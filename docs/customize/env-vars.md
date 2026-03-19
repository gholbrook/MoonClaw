---
title:
  page: "Environment Variables"
  nav: "Environment Variables"
description: "Complete environment variable reference across all NemoClaw extension surfaces."
keywords: ["nemoclaw environment variables", "nemoclaw non-interactive onboard"]
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

# Environment Variables

Environment variables control credential resolution, non-interactive onboarding, service configuration, and runtime behavior across all NemoClaw extension surfaces. This page covers the onboard-specific variables in detail, followed by a complete reference table for every variable organized by surface.

## Credential Variables

The `resolveCredentialEnv()` function in `onboard.ts` maps each `EndpointType` to one of these variable names. Adding a new endpoint type requires adding a matching case to that function, as described in the [Onboard Wizard](onboard-wizard.md) page.

| Variable | Default | Used By | Description |
|----------|---------|---------|-------------|
| `NVIDIA_API_KEY` | none | `build`, `ncp`, `custom` endpoints | API key for build.nvidia.com and NCP endpoints |
| `NIM_API_KEY` | none | `nim-local` endpoint | API key for self-hosted NIM endpoints |
| `OPENAI_API_KEY` | none | `vllm`, `ollama` endpoints | API key for vLLM and Ollama (often set to `"dummy"` or `"ollama"` for local inference) |
| `ANTHROPIC_API_KEY` | none | `claude` endpoint (custom, from the [Onboard Wizard](onboard-wizard.md) example) | API key for the Acme Claude endpoint added in the previous page |

The wizard stores the variable name, not the variable value, in `config.json`. At runtime, the blueprint runner reads the actual key from the environment. This separation keeps secrets out of configuration files on disk.

## Non-Interactive Onboarding

The `isNonInteractive()` function in `onboard.ts` (lines 88-95) determines whether all required inputs have been provided via CLI flags. When every required flag is present, the wizard skips all interactive prompts and writes the configuration directly.

### Required Flags

| Flag | Required For | Description |
|------|-------------|-------------|
| `--endpoint` | all endpoint types | Endpoint type identifier (e.g., `build`, `claude`) |
| `--model` | all endpoint types | Model identifier (e.g., `nvidia/nemotron-3-super-120b-a12b`) |
| `--api-key` | endpoints that need a credential | The API key value |
| `--endpoint-url` | `ncp`, `nim-local`, `custom` | The endpoint URL |
| `--ncp-partner` | `ncp` only | The NCP partner identifier |

The wizard enters non-interactive mode only when all applicable flags for the selected endpoint type are provided. Omitting any required flag causes the wizard to fall back to interactive prompts.

### Non-Interactive Onboarding with the Claude Endpoint

Using the Acme Claude scenario from the previous page:

```bash
openclaw nemoclaw onboard \
  --endpoint claude \
  --model claude-sonnet-4-20250514 \
  --api-key "$ANTHROPIC_API_KEY"
```

The `claude` endpoint does not require `--endpoint-url` or `--ncp-partner`, so only `--endpoint`, `--model`, and `--api-key` are needed.

### Non-Interactive Onboarding with the Default Build Endpoint

```bash
openclaw nemoclaw onboard \
  --endpoint build \
  --model nvidia/nemotron-3-super-120b-a12b \
  --api-key "$NVIDIA_API_KEY"
```

The `build` endpoint uses the hardcoded URL `https://integrate.api.nvidia.com/v1`, so no `--endpoint-url` flag is needed.

## Experimental Endpoint Types

The `NEMOCLAW_EXPERIMENTAL` environment variable controls whether experimental endpoint types appear in the wizard. When set to `"1"`, the `nim-local`, `vllm`, and `ollama` endpoint types become available during onboarding.

```bash
export NEMOCLAW_EXPERIMENTAL=1
openclaw nemoclaw onboard
```

Without this variable (or with any value other than `"1"`), the wizard only shows the `build` and `ncp` endpoint types in the interactive prompt. The experimental types can still be selected via the `--endpoint` flag in non-interactive mode, but the wizard logs a warning that they may not work reliably.

:::{note}
See [Known Pitfalls](overview.md#known-pitfalls) for secrets hygiene guidance. API keys stored in `~/.nemoclaw/config.json` are plaintext JSON, and keys passed as CLI arguments are visible in process listings. Use `credential_env` references and load secrets from environment variables at runtime.
:::

## Validate Your Configuration

After onboarding, verify that the configuration was written correctly.

```bash
cat ~/.nemoclaw/config.json | python3 -c "import sys, json; d=json.load(sys.stdin); print(f'Endpoint: {d[\"endpointType\"]}, Profile: {d[\"profile\"]}, Credential: {d[\"credentialEnv\"]}')"
```

Expected output for the Acme Claude scenario:

```
Endpoint: claude, Profile: claude, Credential: ANTHROPIC_API_KEY
```

---

## Complete Environment Variable Reference

The tables below catalogue every environment variable used across all NemoClaw extension surfaces. Each variable links back to the tutorial page where it is documented in context.

### Onboard

See [Onboard Wizard](onboard-wizard.md) and the [Credential Variables](#credential-variables) section above.

| Variable | Default | Accepted Values | Purpose |
|----------|---------|-----------------|---------|
| `NVIDIA_API_KEY` | none | API key string | Credential for build, ncp, custom endpoints |
| `NIM_API_KEY` | none | API key string | Credential for nim-local endpoint |
| `OPENAI_API_KEY` | none | API key string | Credential for vllm, ollama endpoints |
| `ANTHROPIC_API_KEY` | none | API key string | Credential for claude endpoint (custom) |
| `NEMOCLAW_EXPERIMENTAL` | unset | `"1"` to enable | Shows experimental endpoint types in onboard wizard |

### Blueprint

See [Blueprint](blueprint.md) for inference profile configuration.

| Variable | Default | Accepted Values | Purpose |
|----------|---------|-----------------|---------|
| `NVIDIA_API_KEY` | none | API key string | Referenced by `credential_env` in default and ncp profiles |
| `NIM_API_KEY` | none | API key string | Referenced by `credential_env` in nim-local profile |
| `OPENAI_API_KEY` | none | API key string | Referenced by `credential_env` in vllm profile |

### Install Script

See [Install Script](install-script.md) for installer customization.

| Variable | Default | Accepted Values | Purpose |
|----------|---------|-----------------|---------|
| `NVM_DIR` | `$HOME/.nvm` | Directory path | nvm installation directory |
| `GITHUB_TOKEN` | unset | GitHub token | Used by `gh release download` for OpenShell binary |

### Docker and Build

See [Docker Image](docker-image.md) for image customization.

| Variable | Default | Accepted Values | Purpose |
|----------|---------|-----------------|---------|
| `DEBIAN_FRONTEND` | `noninteractive` | `noninteractive`, `dialog` | Suppresses apt prompts during image build |

### Services

See [Auxiliary Services](auxiliary-services.md) for service management.

| Variable | Default | Accepted Values | Purpose |
|----------|---------|-----------------|---------|
| `TELEGRAM_BOT_TOKEN` | none | Bot token from @BotFather | Required for Telegram bridge |
| `DISCORD_BOT_TOKEN` | none | Bot token from Discord Developer Portal | Required for Discord bridge (custom) |
| `NVIDIA_API_KEY` | none | API key string | Required by start-services.sh and telegram-bridge.js |
| `SANDBOX_NAME` | `"nemoclaw"` | Sandbox name string | Used by telegram-bridge.js for SSH target |
| `ALLOWED_CHAT_IDS` | unset (accepts all) | Comma-separated chat IDs | Access control for Telegram bridge |
| `NEMOCLAW_SANDBOX` | `"default"` | Sandbox name string | Used by start-services.sh for PID directory scoping |
| `DASHBOARD_PORT` | `18789` | Port number | Dashboard port for cloudflared tunnel target |

### Sandbox Entrypoint

See [Web UI](web-ui.md) for gateway and entrypoint configuration.

| Variable | Default | Accepted Values | Purpose |
|----------|---------|-----------------|---------|
| `NVIDIA_API_KEY` | none | API key string | Injected into sandbox for inference |
| `CHAT_UI_URL` | `http://127.0.0.1:18789` | URL | Browser origin for CORS allowed origins |
| `PUBLIC_PORT` | `18789` | Port number | Gateway listen port |
| `NEMOCLAW_GPU` | `a2-highgpu-1g:nvidia-tesla-a100:1` | GPU spec string | Used by `bin/nemoclaw.js` for cloud GPU selection |
| `OLLAMA_HOST` | `0.0.0.0:11434` | host:port | Ollama server bind address |
| `DOCKER_HOST` | unset | Socket path | Docker socket for Colima or alternative runtimes |

## Fully Non-Interactive Installation

To install NemoClaw without any interactive prompts, combine the install script with the non-interactive onboard flags documented [above](#non-interactive-onboarding).

```bash
# Step 1: Run the installer (no prompts in install.sh itself)
curl -fsSL https://raw.githubusercontent.com/your-fork/NemoClaw/main/scripts/install.sh | bash

# Step 2: Run onboard non-interactively
export ANTHROPIC_API_KEY="your-key-here"
openclaw nemoclaw onboard \
  --endpoint claude \
  --model claude-sonnet-4-20250514 \
  --api-key "$ANTHROPIC_API_KEY"
```

The install script itself does not currently read env vars for non-interactive mode. It always runs `nemoclaw onboard` at the end. For fully non-interactive behavior, run the installer first, then run `nemoclaw onboard` with the CLI flags separately (or modify `run_onboard()` in install.sh to pass the flags through).

## What's Next

Proceed to the [Verification Checklist](verification.md) page to validate every customization you have made across all extension surfaces.
