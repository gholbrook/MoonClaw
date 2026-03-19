---
title:
  page: "Agents and Skills"
  nav: "Agents & Skills"
description: "Pre-configure custom agent directories and add skills to the NemoClaw sandbox image."
keywords: ["nemoclaw agents", "nemoclaw custom skills"]
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

# Agents and Skills

OpenClaw uses an agent directory structure under `/sandbox/.openclaw/agents/` to store agent configurations, skills, and credential profiles. Each named agent gets its own directory containing an `agent/` subdirectory with configuration files, skill definitions, and hook scripts.

The NemoClaw Dockerfile creates a default `main` agent at build time. The `nemoclaw-start.sh` script then writes an `auth-profiles.json` file into the `main` agent directory at container startup. Continuing the Acme Corp scenario, you now pre-configure a custom `acme-agent` with skills tailored for your workflow and bake it into the Docker image.

## What Agents and Skills Control

`/sandbox/.openclaw/agents/<name>/agent/`
: The root directory for a named agent. OpenClaw discovers agents by scanning this directory structure. Each agent directory contains configuration, skills, and credential profiles.

`auth-profiles.json`
: Maps provider credentials to environment variable references. The `nemoclaw-start.sh` script writes this file for the `main` agent at startup. Custom agents need their own auth profiles.

`Skill files`
: YAML files within agent directories that define agent capabilities, tool access, and behavioral constraints. Skills follow OpenClaw conventions for agent configuration.

`Hook scripts`
: Scripts that run at agent lifecycle events. Placed within the agent directory structure.

## Locate the Files

The primary file is the `Dockerfile`, which creates the agent directory structure at line 46:

```dockerfile
RUN mkdir -p /sandbox/.openclaw/agents/main/agent \
    && chmod 700 /sandbox/.openclaw
```

The supporting file is `scripts/nemoclaw-start.sh`, which writes `auth-profiles.json` into the main agent directory at lines 63-77. The `write_auth_profile()` function constructs the credential profile and writes it to `~/.openclaw/agents/main/agent/auth-profiles.json`.

New files to create in your fork:

- `agents/acme-agent/agent/auth-profiles.json` with credential references for the Acme agent
- `agents/acme-agent/agent/skills/acme-research.yaml` with skill definitions
- `agents/acme-agent/agent/hooks/on-start.sh` with lifecycle hook scripts

These are source files you add to your fork. The Dockerfile `COPY` instruction bakes them into the image at build time.

## Modify: Add a Custom Agent Directory

Create the following directory tree in the root of your fork:

```
agents/
  acme-agent/
    agent/
      auth-profiles.json
      skills/
        acme-research.yaml
      hooks/
        on-start.sh
```

Create `agents/acme-agent/agent/auth-profiles.json` with credential references for the Acme agent:

```json
{
  "anthropic:manual": {
    "type": "api_key",
    "provider": "acme-claude",
    "keyRef": { "source": "env", "id": "ANTHROPIC_API_KEY" },
    "profileId": "anthropic:manual"
  }
}
```

This references the `acme-claude` provider registered in the [plugin page](openclaw-plugins.md). The `keyRef` uses the `credential_env` pattern, referencing the `ANTHROPIC_API_KEY` environment variable by name. Never put a literal API key value in this file.

Add a `COPY` instruction to the Dockerfile to bake the custom agent into the image. Place this after the existing `mkdir -p /sandbox/.openclaw/agents/main/agent` line:

```dockerfile
# Pre-create OpenClaw directories
RUN mkdir -p /sandbox/.openclaw/agents/main/agent \
    && chmod 700 /sandbox/.openclaw

# Copy custom Acme agent configuration                    # <-- ADD THIS
COPY agents/acme-agent/ /sandbox/.openclaw/agents/acme-agent/  # <-- ADD THIS
```

The `COPY` instruction copies your entire `agents/acme-agent/` directory tree into the sandbox image, preserving the directory structure that OpenClaw expects.

## Modify: Add Custom Skills

Create a skill definition file at `agents/acme-agent/agent/skills/acme-research.yaml`:

```yaml
name: acme-research
description: Research skill for Acme Corp workflows
tools:
  - web-search
  - file-read
constraints:
  - "Always cite sources"
  - "Limit responses to 500 words unless asked for more"
```

:::{note}
The skill YAML format follows OpenClaw conventions. The exact schema depends on the OpenClaw version installed in your sandbox image. Consult the OpenClaw documentation for your version to see the full set of supported fields.
:::

Create a hook script at `agents/acme-agent/agent/hooks/on-start.sh`:

```bash
#!/bin/bash
# Hook: runs when the acme-agent starts
echo "[acme-agent] Agent started at $(date)"
```

Add a Dockerfile `RUN` instruction to make the hook scripts executable:

```dockerfile
RUN chmod +x /sandbox/.openclaw/agents/acme-agent/agent/hooks/*.sh  # <-- ADD THIS
```

Place this line after the `COPY agents/acme-agent/` instruction so the files exist before you change their permissions.

## Validate

Build the Docker image to verify the agent directory is baked in correctly:

```console
$ docker build -t nemoclaw-custom .
```

Verify the agent directory exists inside the image:

```console
$ docker run --rm nemoclaw-custom ls -la /sandbox/.openclaw/agents/acme-agent/agent/
```

Verify the auth-profiles.json file is present and contains the expected content:

```console
$ docker run --rm nemoclaw-custom cat /sandbox/.openclaw/agents/acme-agent/agent/auth-profiles.json
```

:::{note}
Full agent functionality requires the OpenClaw host runtime. These validation steps confirm that the files are correctly placed in the image. The agent will be discovered and activated when OpenClaw starts inside the sandbox.
:::

## What's Next

Proceed to [Docker Image](docker-image.md) to build a custom Docker image that bakes in your plugins, agents, and packages.
