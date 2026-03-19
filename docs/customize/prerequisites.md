---
title:
  page: "Prerequisites and Fork Setup"
  nav: "Prerequisites"
description: "Clone your fork, install dependencies, and build the documentation locally."
keywords: ["nemoclaw fork setup", "nemoclaw prerequisites"]
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

# Prerequisites and Fork Setup

This page covers the software you need installed and how to set up a local development environment for customizing your NemoClaw fork.

## Required Software

| Software | Minimum Version | Purpose |
|----------|----------------|---------|
| Git | any recent | Clone and manage your fork |
| Node.js | 20.0.0+ | Build the TypeScript plugin |
| Python | 3.11+ | Run the blueprint orchestrator and build docs |
| Docker | any recent | Build and run the sandbox container |
| uv | any recent | Python package manager (manages doc dependencies) |

:::{note}
The NemoClaw install script (`install.sh`) handles Node.js and Ollama installation for end users. These prerequisites are for developers customizing the fork, not for end users running the installer.
:::

## Fork and Clone

Fork the NemoClaw repository on GitHub, then clone your fork locally.

```bash
git clone https://github.com/YOUR_USERNAME/NemoClaw.git
cd NemoClaw
```

Add the upstream remote so you can pull future updates from the original repository.

```bash
git remote add upstream https://github.com/NVIDIA/NemoClaw.git
```

## Install Documentation Dependencies

Install the documentation toolchain with uv.

```bash
uv sync --group docs
```

This installs Sphinx, MyST Parser, sphinxcontrib-mermaid, and all other documentation tools defined in `pyproject.toml`.

## Build the Documentation

The Makefile provides three targets for building documentation.

Build the full documentation site:

```bash
make docs
```

Build with live reload (recommended during authoring):

```bash
make docs-live
```

Clean the build output:

```bash
make docs-clean
```

:::{tip}
Use `make docs-live` during development. It starts a local server with automatic rebuilds when you save a file.
:::

After running `make docs`, the built site is in `docs/_build/html/` and can be opened directly in a browser.

## Verify Your Setup

Follow this checklist to confirm everything works.

1. Run `make docs` and confirm it completes without errors.
2. Open `docs/_build/html/index.html` in a browser.
3. Confirm the left sidebar navigation renders correctly.
4. Confirm the Mermaid diagrams on the "How It Works" page render (not blank).

## What's Next

Read the [overview page](overview.md) to understand the six customization surfaces and their dependency order. Then work through the individual surface tutorials in the sidebar, starting with onboard wizard customization.
