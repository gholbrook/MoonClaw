---
title:
  page: "Customize Your NemoClaw Fork"
  nav: "Overview"
description: "Extension surfaces, dependency order, and known pitfalls for NemoClaw fork customization."
keywords: ["nemoclaw customize", "nemoclaw fork tutorial"]
topics: ["generative_ai", "ai_agents"]
tags: ["openclaw", "openshell", "customization"]
content:
  type: concept
  difficulty: technical_beginner
  audience: ["developer", "engineer"]
status: published
---

<!--
  SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
  SPDX-License-Identifier: Apache-2.0
-->

# Customize Your NemoClaw Fork

NemoClaw exposes six customization surfaces that let you tailor the sandbox environment, inference routing, and agent behavior to your needs.
This tutorial walks through each surface in order, so that after following it, all your customizations install automatically via `install.sh`.

## Extension Surfaces

Each surface controls a different aspect of the NemoClaw stack. They are listed here in the order you will encounter them during customization.

install.sh
: The entry point script that installs Node.js, Ollama, NemoClaw, and runs the onboard wizard. Fork authors can add pre-install checks, change default installation paths, or bundle additional tools that the rest of the stack depends on.

Onboard wizard
: The interactive endpoint configuration flow that persists settings to `~/.nemoclaw/config.json`. You can add new endpoint types, change default model selections, or add custom validation for API keys and URLs.

Blueprint (`nemoclaw-blueprint/`)
: The Python orchestrator that contains `blueprint.yaml` profiles, sandbox configuration, and the runner script. You can define new profiles, change sandbox resource limits, or add custom orchestration steps that run before or after sandbox creation.

Plugin (`nemoclaw/src/`)
: The TypeScript OpenClaw plugin that uses `registerProvider`, `registerCli`, and `registerService` to integrate with the host. You can add new CLI subcommands, register additional model providers, or extend the slash command interface.

Docker image (`Dockerfile`)
: The container definition that builds the sandbox with OpenClaw and NemoClaw pre-installed. You can add system packages, pre-install extensions, or change the base image to match your deployment environment.

Policies (`nemoclaw-blueprint/policies/`)
: The network egress and filesystem policies that control what the sandboxed agent can access. You can pre-approve trusted domains, restrict filesystem paths, or define custom policy templates for different use cases.

## Dependency Order

The six surfaces form a linear dependency chain. Each surface consumes output from the one before it, so changes should follow this order.

```{mermaid}
flowchart LR
    A["install.sh"] --> B["onboard wizard"]
    B --> C["blueprint"]
    C --> D["plugin"]
    D --> E["Docker image"]
    E --> F["policies"]

    classDef nv fill:#76b900,stroke:#333,color:#fff
    classDef nvLight fill:#e6f2cc,stroke:#76b900,color:#1a1a1a
    classDef nvDark fill:#333,stroke:#76b900,color:#fff

    class A,B nvDark
    class C,D nv
    class E,F nvLight
```

The install script runs the onboard wizard, which writes endpoint configuration consumed by the blueprint. The blueprint configures the plugin and determines what gets baked into the Docker image. Finally, policies are applied to the running container to control network and filesystem access.

## Known Pitfalls

These are issues every fork author should understand before making changes to any surface.

:::{warning}
**Blueprint fetch stub**

The `fetchBlueprint()` function is not implemented. Blueprints must be manually placed in `~/.nemoclaw/blueprints/` before running any blueprint commands. Do not expect `nemoclaw launch` to automatically download blueprints from a registry.
:::

:::{warning}
**YAML regex parser**

The blueprint manifest uses manual regex parsing instead of a proper YAML parser. Stick to simple key-value pairs in the manifest header. Avoid multi-line values, lists, or special characters in manifest fields.
:::

:::{warning}
**Secrets hygiene**

API keys stored in `~/.nemoclaw/config.json` are plaintext JSON. Keys passed as CLI arguments are visible in process listings. Never put API keys in Dockerfile `ENV` instructions. Use `credential_env: "ENV_VAR_NAME"` references instead, and load secrets from environment variables at runtime.
:::

:::{warning}
**SDK import constraint**

The OpenClaw plugin SDK (`openclaw/plugin-sdk`) is only available at runtime, not at build time. Plugin TypeScript code must use local type stubs for SDK interfaces during development and compilation. The Plugin API section of this tutorial covers the type stub pattern in detail.
:::

## What's Next

Proceed to the [Prerequisites and Fork Setup](prerequisites.md) page to set up your development environment, install dependencies, and verify that you can build the documentation locally. After that, work through the individual surface tutorials in the sidebar, starting from the top of the dependency chain.
