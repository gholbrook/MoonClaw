---
title:
  page: "Web UI and Gateway"
  nav: "Web UI"
description: "Customize the OpenClaw gateway configuration, entry point script, and dashboard UI."
keywords: ["nemoclaw web ui", "nemoclaw gateway config"]
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

# Web UI and Gateway

The NemoClaw sandbox runs an OpenClaw gateway that serves the web dashboard. The `nemoclaw-start.sh` entry point script configures the gateway, writes credential profiles, and launches the auto-pair watcher that automatically approves device pairing requests. Continuing the Acme Corp scenario, you now configure CORS origins for an internal dashboard, customize the startup sequence, and bundle a custom UI into the Docker image.

## What the Web UI Controls

`Gateway configuration (openclaw.json)`
: Controls CORS allowed origins, trusted proxies, auth mode, and device pairing. Written by the `fix_openclaw_config()` function in `nemoclaw-start.sh`.

`nemoclaw-start.sh entry point`
: The container startup script that runs `openclaw doctor --fix`, writes auth profiles, configures the gateway, installs plugins, and launches `openclaw gateway run`. Customizing this script changes the sandbox startup behavior.

`Dashboard UI`
: The OpenClaw gateway (`openclaw gateway run`) serves the built-in control UI on port 18789 (configurable via `PUBLIC_PORT`). A custom dashboard can be bundled into the image and served alongside or instead of the default UI.

## Locate the Files

The primary file is `scripts/nemoclaw-start.sh` (185 lines). This is the entry point script that configures the gateway, writes auth profiles, and launches the sandbox services.

Supporting files you may want to reference while making changes:

- Dockerfile lines 39-40 copy and chmod the entrypoint into the image:

  ```dockerfile
  COPY scripts/nemoclaw-start.sh /usr/local/bin/nemoclaw-start
  RUN chmod +x /usr/local/bin/nemoclaw-start
  ```

- `~/.openclaw/openclaw.json` is the gateway configuration file, written at both build time and start time by `fix_openclaw_config()`.

## Modify: CORS Origins and Trusted Proxies

The `fix_openclaw_config()` function in `nemoclaw-start.sh` builds the list of allowed origins from environment variables. To add a custom dashboard URL, append it to the `origins` list inside the embedded Python block.

Open `scripts/nemoclaw-start.sh` and find the `fix_openclaw_config()` function. Locate the origin-building logic near line 39:

```python
origins = [local_origin]
if chat_origin not in origins:
    origins.append(chat_origin)
origins.append('https://dashboard.acme.internal')          # <-- ADD THIS
```

To add a reverse proxy IP to the trusted proxies list, find the `trustedProxies` assignment near line 50:

```python
gateway['trustedProxies'] = ['127.0.0.1', '::1', '10.0.0.1']  # <-- ADD THIS (added 10.0.0.1)
```

Two environment variables control these values at runtime:

`CHAT_UI_URL`
: Sets the browser origin that will access the forwarded dashboard. The default is `http://127.0.0.1:18789`. The function parses this URL to extract the scheme and host, then adds it to `allowedOrigins` if it differs from the local origin.

`PUBLIC_PORT`
: Sets the gateway listen port. The default is `18789`. This value is used to construct the local origin (`http://127.0.0.1:{PUBLIC_PORT}`).

## Modify: Entry Point Customization

The `nemoclaw-start.sh` script runs the following startup sequence (lines 169-184):

1. `openclaw doctor --fix` -- diagnose and repair the OpenClaw installation
2. `openclaw models set nvidia/nemotron-3-super-120b-a12b` -- set the default model
3. `write_auth_profile` -- write NVIDIA API key to auth-profiles.json
4. `export CHAT_UI_URL PUBLIC_PORT` -- export environment variables for the config function
5. `fix_openclaw_config` -- write gateway configuration to openclaw.json
6. `openclaw plugins install /opt/nemoclaw` -- install the NemoClaw plugin
7. `openclaw gateway run` -- launch the gateway (via nohup, backgrounded)
8. `start_auto_pair` -- launch the device auto-pair watcher
9. `print_dashboard_urls` -- print the local and remote dashboard URLs

To add a custom step, insert it at the appropriate point in the sequence. For example, to verify Anthropic API key connectivity between `fix_openclaw_config` and `openclaw plugins install`:

```bash
export CHAT_UI_URL PUBLIC_PORT
fix_openclaw_config
openclaw plugins install /opt/nemoclaw > /dev/null 2>&1 || true

# Custom Acme startup: verify Claude endpoint connectivity    # <-- ADD THIS
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then                      # <-- ADD THIS
  echo "[acme] Anthropic API key configured"                  # <-- ADD THIS
fi                                                            # <-- ADD THIS
```

The entrypoint is copied into the image at build time (Dockerfile lines 39-40). To customize it, modify `scripts/nemoclaw-start.sh` in your fork before running `docker build`. Changes take effect on the next image build.

## Modify: Custom Dashboard UI

The OpenClaw gateway (`openclaw gateway run`) serves the built-in control UI. To bundle a custom dashboard alongside the default UI, follow these three steps.

**Build your custom UI.** Build a static web application (for example, a React or Vite app) to a `dist/` directory.

**Add the UI to the Docker image.** Add these lines to the Dockerfile after the existing COPY instructions:

```dockerfile
# Copy custom dashboard UI                                    # <-- ADD THIS
COPY dashboard/dist/ /opt/acme-dashboard/                      # <-- ADD THIS
RUN npm install -g serve                                       # <-- ADD THIS
```

**Start the custom dashboard in the entry point.** Add these lines to `nemoclaw-start.sh` after the `openclaw gateway run` launch:

```bash
# Start custom Acme dashboard on port 3000                    # <-- ADD THIS
nohup serve -s /opt/acme-dashboard -l 3000 >> /tmp/dashboard.log 2>&1 &  # <-- ADD THIS
echo "[acme] Custom dashboard running on port 3000"           # <-- ADD THIS
```

This runs the custom dashboard alongside the default OpenClaw gateway UI. If your custom dashboard calls the gateway API, add its origin to the `allowedOrigins` list in `fix_openclaw_config()`:

```python
origins.append('http://127.0.0.1:3000')  # <-- ADD THIS (custom dashboard origin)
```

Remember to also add port 3000 to `forward_ports` in `blueprint.yaml` so the port is mapped from the sandbox container to the host.

## Validate

Build the image with your custom start script:

```console
$ docker build -t nemoclaw-custom .
```

Start the container:

```console
$ docker run --rm -p 18789:18789 nemoclaw-custom nemoclaw-start
```

Verify the gateway responds:

```console
$ curl -s http://127.0.0.1:18789/ | head -5
```

Check the container logs for gateway startup messages:

```console
$ docker logs <container-id> 2>&1 | grep "gateway"
```

If you bundled a custom dashboard, verify that port 3000 responds:

```console
$ curl -s http://127.0.0.1:3000/ | head -5
```

## What's Next

This is the last page in the Developer Surface phase. Return to the [Customization Overview](overview.md) to review all extension surfaces, or proceed to the next phase to customize the install script and auxiliary services.
