---
title:
  page: "Docker Image Customization"
  nav: "Docker Image"
description: "Build a custom NemoClaw sandbox image with baked-in plugins, packages, and agent configurations."
keywords: ["nemoclaw docker", "nemoclaw custom image"]
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

# Docker Image Customization

:::{warning}
**Build the plugin before building the image**

The Dockerfile copies pre-built JavaScript from `nemoclaw/dist/`. Run `cd nemoclaw && npm run build` before `docker build`. If `dist/` does not exist, the COPY instruction fails with "no such file or directory."
:::

The NemoClaw Dockerfile builds a sandbox image with OpenClaw, the NemoClaw plugin, and the blueprint pre-installed. Customizing this Dockerfile lets you bake in additional packages, your custom plugin modifications, agent configurations, and an `openclaw.json` init block. Continuing the Acme Corp scenario, the developer now builds a custom image with the Acme Claude provider plugin, additional monitoring tools, and the acme-agent configuration.

## What the Dockerfile Controls

`System packages (apt-get)`
: Linux packages available inside the sandbox. The base image includes python3, curl, git, ca-certificates, and iproute2.

`OpenClaw CLI version`
: Pinned at `openclaw@2026.3.11` via `npm install -g`. Change the version to match your target OpenClaw release.

`Plugin and blueprint`
: The compiled NemoClaw plugin (`dist/`) and blueprint YAML are COPYed into the image and installed via `openclaw plugins install`.

`openclaw.json`
: Initial OpenClaw configuration written during image build. Sets default model, provider routing, and inference endpoint.

`Agent directories`
: Pre-created under `/sandbox/.openclaw/agents/`. Custom agent configurations are COPYed here.

`Entrypoint script`
: `nemoclaw-start.sh` is copied to `/usr/local/bin/nemoclaw-start`. It configures the gateway and launches the dashboard at container start.

## Locate the File

The primary file is `Dockerfile` in the repository root.

Supporting files you may want to reference while making changes:

- `nemoclaw/dist/` -- compiled plugin output (created by `npm run build`)
- `nemoclaw/openclaw.plugin.json` -- plugin manifest
- `scripts/nemoclaw-start.sh` -- container entrypoint

## Modify: Add System and npm Packages

Add system packages to the existing `apt-get` block in the Dockerfile. The base image already includes python3, curl, git, ca-certificates, and iproute2. Insert new packages before the cleanup line.

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv \
        curl git ca-certificates \
        iproute2 \
        postgresql-client \                # <-- ADD THIS
        jq \                               # <-- ADD THIS
    && rm -rf /var/lib/apt/lists/*
```

Add npm packages after the existing `npm install -g openclaw@2026.3.11` line. Each global package gets its own `RUN` instruction to keep layers cacheable.

```dockerfile
RUN npm install -g openclaw@2026.3.11
RUN npm install -g @acme/monitoring-cli    # <-- ADD THIS
```

## Modify: Bake In the Custom Plugin

The existing Dockerfile already COPYs the compiled plugin and runs `openclaw plugins install`. Your custom `registerProvider`, `registerCli`, and `registerService` additions from the [plugin page](openclaw-plugins.md) are automatically included because they are part of the compiled `dist/` output.

The relevant Dockerfile lines for orientation:

```dockerfile
COPY nemoclaw/dist/ /opt/nemoclaw/dist/
COPY nemoclaw/openclaw.plugin.json /opt/nemoclaw/
COPY nemoclaw/package.json /opt/nemoclaw/
```

After modifying `nemoclaw/src/index.ts` and `nemoclaw/src/cli.ts`, run `cd nemoclaw && npm run build` to regenerate `dist/`, then `docker build` picks up the changes. The build step compiles TypeScript to JavaScript via `tsc` (the `build` script in `nemoclaw/package.json`).

## Modify: Customize the openclaw.json Init Block

The Dockerfile writes `openclaw.json` using an inline Python script near the end of the build. This configuration sets the default model, provider routing, and inference endpoint. To add the Acme Claude provider, insert a new entry in the `models.providers` dict.

The existing Python block writes the NVIDIA provider. Add the `acme-claude` provider alongside it:

```python
'acme-claude': {                                           # <-- ADD THIS
    'baseUrl': 'https://api.anthropic.com/v1',             # <-- ADD THIS
    'apiKey': 'openshell-managed',                         # <-- ADD THIS
    'api': 'anthropic',                                    # <-- ADD THIS
    'models': [{                                           # <-- ADD THIS
        'id': 'claude-sonnet-4-20250514',                  # <-- ADD THIS
        'name': 'Claude Sonnet 4',                         # <-- ADD THIS
        'reasoning': False,                                # <-- ADD THIS
        'input': ['text'],                                 # <-- ADD THIS
        'contextWindow': 200000,                           # <-- ADD THIS
        'maxTokens': 16384                                 # <-- ADD THIS
    }]                                                     # <-- ADD THIS
}                                                          # <-- ADD THIS
```

This entry goes inside the `'providers'` dict, next to the existing `'nvidia'` entry. The `'apiKey': 'openshell-managed'` value means OpenShell injects credentials at runtime via provider configuration.

## Secrets and Environment Variables

:::{danger}
**Never bake API keys into the image**

The following is WRONG -- the key is stored in the image layer history and visible to anyone with access to the image:

```dockerfile
# DO NOT DO THIS
ENV ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxx
```
:::

Pass secrets at runtime only:

```bash
# Pass secrets at runtime only
docker run --env ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" nemoclaw-custom
```

The `openclaw.json` init block uses `"apiKey": "openshell-managed"` because OpenShell injects credentials via provider configuration at runtime. For standalone Docker runs outside OpenShell, pass API keys via `--env` flags.

## Modify: Multi-Stage Build Pattern

The following Dockerfile shows how all Acme customizations compose on top of the base in logical layer order. Each section builds on the previous one, and comments mark where custom layers begin.

```dockerfile
# NemoClaw sandbox image -- customized for Acme Corp
FROM node:22-slim

ENV DEBIAN_FRONTEND=noninteractive

# --- Layer 1: System packages ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv \
        curl git ca-certificates \
        iproute2 \
        postgresql-client \                # <-- CUSTOM: database client
        jq \                               # <-- CUSTOM: JSON processing
    && rm -rf /var/lib/apt/lists/*

# Create sandbox user (matches OpenShell convention)
RUN groupadd -r sandbox && useradd -r -g sandbox -d /sandbox -s /bin/bash sandbox \
    && mkdir -p /sandbox/.openclaw /sandbox/.nemoclaw \
    && chown -R sandbox:sandbox /sandbox

# --- Layer 2: npm packages ---
RUN npm install -g openclaw@2026.3.11
RUN npm install -g @acme/monitoring-cli    # <-- CUSTOM: monitoring tools

# Install PyYAML for blueprint runner
RUN pip3 install --break-system-packages pyyaml

# --- Layer 3: Plugin and blueprint (COPY + install) ---
COPY nemoclaw/dist/ /opt/nemoclaw/dist/
COPY nemoclaw/openclaw.plugin.json /opt/nemoclaw/
COPY nemoclaw/package.json /opt/nemoclaw/
COPY nemoclaw-blueprint/ /opt/nemoclaw-blueprint/

WORKDIR /opt/nemoclaw
RUN npm install --omit=dev

# Set up blueprint for local resolution
RUN mkdir -p /sandbox/.nemoclaw/blueprints/0.1.0 \
    && cp -r /opt/nemoclaw-blueprint/* /sandbox/.nemoclaw/blueprints/0.1.0/

# Copy startup script
COPY scripts/nemoclaw-start.sh /usr/local/bin/nemoclaw-start
RUN chmod +x /usr/local/bin/nemoclaw-start

WORKDIR /sandbox
USER sandbox

# --- Layer 4: Agent directories ---
RUN mkdir -p /sandbox/.openclaw/agents/main/agent \
    && chmod 700 /sandbox/.openclaw

# --- Layer 5: openclaw.json with Acme Claude provider ---
RUN python3 -c "\
import json, os; \
config = { \
    'agents': {'defaults': {'model': {'primary': 'nvidia/nemotron-3-super-120b-a12b'}}}, \
    'models': {'mode': 'merge', 'providers': { \
        'nvidia': { \
            'baseUrl': 'https://inference.local/v1', \
            'apiKey': 'openshell-managed', \
            'api': 'openai-completions', \
            'models': [{'id': 'nemotron-3-super-120b-a12b', 'name': 'NVIDIA Nemotron 3 Super 120B', 'reasoning': False, 'input': ['text'], 'cost': {'input': 0, 'output': 0, 'cacheRead': 0, 'cacheWrite': 0}, 'contextWindow': 131072, 'maxTokens': 4096}] \
        }, \
        'acme-claude': { \
            'baseUrl': 'https://api.anthropic.com/v1', \
            'apiKey': 'openshell-managed', \
            'api': 'anthropic', \
            'models': [{'id': 'claude-sonnet-4-20250514', 'name': 'Claude Sonnet 4', 'reasoning': False, 'input': ['text'], 'contextWindow': 200000, 'maxTokens': 16384}] \
        } \
    }} \
}; \
path = os.path.expanduser('~/.openclaw/openclaw.json'); \
json.dump(config, open(path, 'w'), indent=2); \
os.chmod(path, 0o600)"

# Install NemoClaw plugin into OpenClaw
RUN openclaw doctor --fix > /dev/null 2>&1 || true \
    && openclaw plugins install /opt/nemoclaw > /dev/null 2>&1 || true

ENTRYPOINT ["/bin/bash"]
CMD []
```

This is a single-stage build. The "multi-stage" terminology refers to the logical layering pattern: system packages, npm packages, plugin installation, agent configuration, and OpenClaw setup each form a distinct stage in the build. Layer ordering follows Docker cache optimization: less-frequently-changed layers (system packages) come first, and more-frequently-changed layers (plugin code, config) come last.

## Validate

Build the plugin first, then the image:

1. Compile the plugin:

   ```console
   $ cd nemoclaw && npm run build
   ```

2. Build the custom image:

   ```console
   $ docker build -t nemoclaw-custom .
   ```

3. Verify the plugin is installed:

   ```console
   $ docker run --rm nemoclaw-custom openclaw plugins list 2>/dev/null | grep nemoclaw || echo "plugin check requires host"
   ```

4. Verify custom packages:

   ```console
   $ docker run --rm nemoclaw-custom which jq
   ```

5. Verify agent directories:

   ```console
   $ docker run --rm nemoclaw-custom ls /sandbox/.openclaw/agents/
   ```

## What's Next

Proceed to the [Web UI](web-ui.md) page to customize the web UI gateway configuration, entry point script, and dashboard.
