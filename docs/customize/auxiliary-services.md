---
title:
  page: "Auxiliary Services"
  nav: "Auxiliary Services"
description: "Add custom bridge services to start-services.sh using the PID management pattern."
keywords: ["nemoclaw auxiliary services", "nemoclaw bridge service"]
topics: ["generative_ai", "ai_agents"]
tags: ["openclaw", "openshell", "customization"]
content:
  type: how-to
  difficulty: technical_beginner
  audience: ["developer", "engineer"]
status: published
---

<!--
  SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
  SPDX-License-Identifier: Apache-2.0
-->

# Auxiliary Services

NemoClaw manages auxiliary services through `scripts/start-services.sh`. The script currently launches two services: a Telegram bridge that forwards chat messages to the sandbox agent, and a Cloudflare tunnel that provides public HTTPS access to the dashboard. Each service follows a PID management pattern that handles startup, shutdown, and status checks.

Continuing the Acme Corp scenario, the developer adds a Discord bot bridge that forwards messages to the sandbox agent, following the same pattern as the existing Telegram bridge.

## How start-services.sh Works

The script accepts three commands via flags:

- `./scripts/start-services.sh` starts all configured services
- `./scripts/start-services.sh --stop` stops all running services
- `./scripts/start-services.sh --status` shows which services are running

PID files are scoped per sandbox using the `PIDDIR` variable:

```bash
PIDDIR="/tmp/nemoclaw-services-${SANDBOX_NAME}"
```

This means multiple sandboxes can run their own set of services without PID file conflicts. The `SANDBOX_NAME` is read from the `NEMOCLAW_SANDBOX` environment variable and defaults to `"default"`.

Three core functions implement the service lifecycle: `is_running()` checks if a service is alive, `start_service()` launches a service idempotently, and `stop_service()` terminates a service and cleans up its PID file. Services are registered in `do_start()`, with matching entries in `show_status()` and `do_stop()`.

## The PID Management Pattern

The `start_service()` function is the core of the pattern. Every service is launched through this function:

```bash
start_service() {
  local name="$1"
  shift
  if is_running "$name"; then
    info "$name already running (PID $(cat "$PIDDIR/$name.pid"))"
    return 0
  fi
  nohup "$@" > "$PIDDIR/$name.log" 2>&1 &
  echo $! > "$PIDDIR/$name.pid"
  info "$name started (PID $!)"
}
```

The first argument is the service name, used to derive the PID and log file paths. The remaining arguments are the command to execute.

The `is_running` check at the top makes the function idempotent. Calling `start_service` twice for the same service is safe because the second call returns early if the process is still alive.

The `nohup` command runs the service in the background, detached from the terminal. Both stdout and stderr are redirected to `$PIDDIR/$name.log`, so the service never writes to the terminal. The background PID (`$!`) is written to `$PIDDIR/$name.pid` for later lifecycle management.

## The Stdout Protocol Contract

Services managed by `start-services.sh` follow a contract: all output goes to the log file, and lifecycle is managed through PID files.

The `is_running()` function checks whether a service is still alive by sending signal 0 to the stored PID:

```bash
is_running() {
  local pidfile="$PIDDIR/$1.pid"
  if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
    return 0
  fi
  return 1
}
```

Signal 0 does not actually send a signal to the process. It checks whether the process exists and the caller has permission to signal it. If the PID file exists and `kill -0` succeeds, the service is running.

The `stop_service()` function terminates the process and removes the PID file:

```bash
stop_service() {
  local name="$1"
  local pidfile="$PIDDIR/$name.pid"
  if [ -f "$pidfile" ]; then
    local pid
    pid="$(cat "$pidfile")"
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
      info "$name stopped (PID $pid)"
    else
      info "$name was not running"
    fi
    rm -f "$pidfile"
  else
    info "$name was not running"
  fi
}
```

The function first tries a graceful `kill` (SIGTERM), then falls back to `kill -9` (SIGKILL) if the process does not terminate. The PID file is always removed, even if the process was already gone.

## Modify: Add a Discord Bot Bridge

Adding a new service requires changes in THREE places in `start-services.sh`. Missing any one of them causes incorrect behavior: the service starts but does not appear in status output, or it starts but cannot be stopped.

**1. Register in do_start()**

Add the service registration after the cloudflared block in `do_start()`:

```bash
  # Discord bridge (only if token provided)
  if [ -n "${DISCORD_BOT_TOKEN:-}" ]; then             # <-- ADD THIS
    start_service discord-bridge \                      # <-- ADD THIS
      node "$REPO_DIR/scripts/discord-bridge.js"       # <-- ADD THIS
  fi                                                   # <-- ADD THIS
```

The guard clause checks `DISCORD_BOT_TOKEN` before launching, matching the pattern used by the Telegram bridge with `TELEGRAM_BOT_TOKEN`. If the token is not set, the service is silently skipped.

**2. Update show_status()**

Add `discord-bridge` to the hardcoded service list in `show_status()`:

```bash
  for svc in telegram-bridge discord-bridge cloudflared; do  # <-- ADD discord-bridge
```

Without this change, `./scripts/start-services.sh --status` will not show the Discord bridge even when it is running.

**3. Add to do_stop()**

Add the stop call in `do_stop()`:

```bash
  stop_service discord-bridge                          # <-- ADD THIS
```

Without this change, `./scripts/start-services.sh --stop` will leave the Discord bridge running.

### The Discord Bridge Template

Create `scripts/discord-bridge.js` following the same structure as `scripts/telegram-bridge.js`. This template uses Discord's HTTP API with the built-in `https` module, avoiding a dependency on Discord.js:

```javascript
#!/usr/bin/env node
// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

/**
 * Discord -> NemoClaw bridge (minimal template).
 *
 * Polls a Discord channel for new messages and forwards them to the
 * OpenClaw agent running inside the sandbox. Responses are posted back
 * to the channel.
 *
 * Env:
 *   DISCORD_BOT_TOKEN   -- Bot token from the Discord Developer Portal
 *   NVIDIA_API_KEY      -- For inference
 *   SANDBOX_NAME        -- Sandbox name (default: nemoclaw)
 *   DISCORD_CHANNEL_ID  -- Channel to monitor
 */

const https = require("https");
const { execSync, spawn } = require("child_process");

const TOKEN = process.env.DISCORD_BOT_TOKEN;
const API_KEY = process.env.NVIDIA_API_KEY;
const SANDBOX = process.env.SANDBOX_NAME || "nemoclaw";
const CHANNEL_ID = process.env.DISCORD_CHANNEL_ID;

if (!TOKEN) { console.error("DISCORD_BOT_TOKEN required"); process.exit(1); }
if (!API_KEY) { console.error("NVIDIA_API_KEY required"); process.exit(1); }
if (!CHANNEL_ID) { console.error("DISCORD_CHANNEL_ID required"); process.exit(1); }

let lastMessageId = null;

// -- Discord API helpers --------------------------------------------------

function discordApi(method, path, body) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: "discord.com",
      path: `/api/v10${path}`,
      method,
      headers: {
        Authorization: `Bot ${TOKEN}`,
        "Content-Type": "application/json",
      },
    };
    const req = https.request(options, (res) => {
      let buf = "";
      res.on("data", (c) => (buf += c));
      res.on("end", () => {
        try { resolve(JSON.parse(buf)); } catch { resolve(buf); }
      });
    });
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function sendMessage(channelId, text) {
  const chunks = [];
  for (let i = 0; i < text.length; i += 1900) {
    chunks.push(text.slice(i, i + 1900));
  }
  return Promise.all(
    chunks.map((chunk) =>
      discordApi("POST", `/channels/${channelId}/messages`, { content: chunk })
    )
  );
}

// -- Run agent inside sandbox (same pattern as telegram-bridge.js) --------

function runAgentInSandbox(message, sessionId) {
  return new Promise((resolve) => {
    const sshConfig = execSync(`openshell sandbox ssh-config ${SANDBOX}`, {
      encoding: "utf-8",
    });
    const confPath = `/tmp/nemoclaw-discord-ssh-${sessionId}.conf`;
    require("fs").writeFileSync(confPath, sshConfig);

    const escaped = message.replace(/'/g, "'\\''");
    const cmd = `export NVIDIA_API_KEY='${API_KEY}' && nemoclaw-start openclaw agent --agent main --local -m '${escaped}' --session-id 'discord-${sessionId}'`;

    const proc = spawn("ssh", ["-T", "-F", confPath, `openshell-${SANDBOX}`, cmd], {
      timeout: 120000,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    proc.stdout.on("data", (d) => (stdout += d.toString()));
    proc.on("close", () => {
      try { require("fs").unlinkSync(confPath); } catch {}
      const response = stdout.trim() || "(no response)";
      resolve(response);
    });
    proc.on("error", (err) => resolve(`Error: ${err.message}`));
  });
}

// -- Poll loop ------------------------------------------------------------

async function poll() {
  try {
    const url = `/channels/${CHANNEL_ID}/messages?limit=10` +
      (lastMessageId ? `&after=${lastMessageId}` : "");
    const messages = await discordApi("GET", url);

    if (Array.isArray(messages) && messages.length > 0) {
      // Discord returns newest first, reverse to process oldest first
      messages.reverse();
      for (const msg of messages) {
        lastMessageId = msg.id;
        if (msg.author.bot) continue;

        console.log(`[${msg.author.username}] ${msg.content}`);
        const response = await runAgentInSandbox(msg.content, msg.channel_id);
        await sendMessage(msg.channel_id, response);
      }
    }
  } catch (err) {
    console.error("Poll error:", err.message);
  }
  setTimeout(poll, 2000);
}

console.log("Discord bridge started for channel", CHANNEL_ID);
poll();
```

This template is intentionally minimal. It polls the channel every two seconds, forwards new messages to the sandbox agent via SSH, and posts responses back. For production use, consider switching to the Discord Gateway WebSocket API for real-time message delivery.

## Validate

Run these commands from the repository root to verify your changes:

Check `start-services.sh` syntax:

```console
$ bash -n scripts/start-services.sh
```

Verify all three registration points exist:

```console
$ grep "discord-bridge" scripts/start-services.sh
```

This should show three matches: the `start_service` call in `do_start()`, the entry in the `show_status()` loop, and the `stop_service` call in `do_stop()`.

Syntax-check the Discord bridge template:

```console
$ node -c scripts/discord-bridge.js
```

Test that `start-services.sh` does not error on status check:

```console
$ DISCORD_BOT_TOKEN=test scripts/start-services.sh --status
```

## What's Next

Proceed to the [Environment Variables](env-vars.md) page for the complete reference of all environment variables across every NemoClaw surface.
