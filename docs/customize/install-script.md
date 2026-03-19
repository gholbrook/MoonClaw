---
title:
  page: "Install Script"
  nav: "Install Script"
description: "Customize the NemoClaw install script to change the Node.js version, Ollama model thresholds, package source, and post-install steps."
keywords: ["nemoclaw install script", "nemoclaw customization"]
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

# Install Script

The root `install.sh` installs Node.js via nvm, optionally installs Ollama with GPU-based model selection, clones and builds NemoClaw, and runs the onboard wizard. Each step is a standalone function called from a central `main()` function, making the script straightforward to extend.

Continuing the Acme Corp scenario, the developer now customizes the installer to pin Node.js 24, add a medium-VRAM Ollama tier for their 64 GB workstations, switch the package source to the Acme private registry, and run a custom post-install step that installs Acme's internal CLI tools.

A second installer (`scripts/install.sh`, 333 lines) exists as a simpler curl-pipe-bash variant without Ollama support. This page focuses on the root `install.sh`, which has the full feature set and modular `main()` function.

## What the Install Script Controls

`Node.js version`
: The `RECOMMENDED_NODE_MAJOR` variable (line 20) and the `install_nodejs()` function control which Node.js version gets installed via nvm. Default: 22.

`Ollama model selection`
: The `install_or_upgrade_ollama()` function checks available VRAM and pulls the appropriate model. The VRAM threshold at 120 GB selects between `nemotron-3-super:120b` and `nemotron-3-nano:30b`. This function is commented out in `main()` by default.

`Package source`
: Line 203 installs NemoClaw via `npm install -g git+ssh://...`. Change this to install from a private registry or local path.

`Post-install steps`
: The `main()` function (lines 288-300) calls each install step in sequence. Add custom functions and call them from `main()`.

## Locate the Files

The primary file is `install.sh` at the repository root. This is the full installer with Ollama support and a modular `main()` function (302 lines).

The alternative is `scripts/install.sh`, the curl-pipe-bash variant (333 lines) with a simpler structure and no Ollama support. If you only need to change the Node.js version or package source, the same edits apply to both files.

## Modify: Node.js Version

Two locations must be updated when changing the Node.js version. Both are in `install.sh`.

The first is the `RECOMMENDED_NODE_MAJOR` variable near the top of the file, which controls the version check message and the runtime validation logic:

```bash
# install.sh, line 20:
RECOMMENDED_NODE_MAJOR=24                              # <-- CHANGE THIS
```

The second is the `nvm install` call inside the `install_nodejs()` function, which controls which version nvm actually installs:

```bash
# install.sh, line 116 (in install_nodejs):
  nvm install 24                                       # <-- CHANGE THIS
```

Both values must match. If you change one without the other, the installer will install the wrong version or display an incorrect recommendation in error messages.

## Modify: Ollama Model Thresholds

The `install_or_upgrade_ollama()` function selects a model based on available VRAM. The default configuration has two tiers: 120 GB and above gets the large model, everything else gets the small model.

Before customizing the thresholds, note that `install_or_upgrade_ollama` is commented out in `main()` (line 293). You must uncomment it to enable Ollama auto-installation. The "Modify: Custom Post-Install Steps" section below shows the full `main()` function with this line uncommented.

The `OLLAMA_MIN_VERSION` variable (line 123) controls the minimum acceptable Ollama version. Update it if your models require a newer Ollama release:

```bash
OLLAMA_MIN_VERSION="0.18.0"
```

To add a medium tier for workstations with 48-80 GB VRAM, replace the if/else block in `install_or_upgrade_ollama()` (lines 184-190) with a three-tier if/elif/else:

```bash
# install.sh -- add a medium tier for 48-80 GB VRAM
# Replace lines 184-190 in install_or_upgrade_ollama():
  if (( vram_gb >= 120 )); then
    info "Pulling nemotron-3-super:120b..."
    ollama pull nemotron-3-super:120b
  elif (( vram_gb >= 48 )); then                       # <-- ADD THIS
    info "Pulling nemotron-3-super:70b..."             # <-- ADD THIS
    ollama pull nemotron-3-super:70b                   # <-- ADD THIS
  else
    info "Pulling nemotron-3-nano:30b..."
    ollama pull nemotron-3-nano:30b
  fi
```

The thresholds use integer comparison on `vram_gb`, which is computed from the VRAM reported by `nvidia-smi` (or unified memory on macOS). Adjust the threshold values to match your hardware fleet.

## Modify: Package Source

Line 203 in `install_nemoclaw()` is where NemoClaw is actually installed. The default uses a `git+ssh://` URL that assumes SSH key access to the repository:

```bash
npm install -g git+ssh://git@github.com/nvidia/NemoClaw.git
```

When forking for an organization, change this line to match your distribution method. Three common alternatives:

**Private npm registry** for organizations hosting their fork on a private registry:

```bash
npm install -g @acme/nemoclaw --registry https://npm.acme.corp/  # <-- CHANGE THIS
```

**Local path** for development or air-gapped environments:

```bash
npm install -g /opt/nemoclaw/                                    # <-- CHANGE THIS
```

**HTTPS Git URL** for environments where SSH is not available:

```bash
npm install -g git+https://github.com/acme-corp/nemoclaw.git    # <-- CHANGE THIS
```

Pick the alternative that matches how your team distributes the fork. The rest of the installer does not depend on the install method, so only this one line needs to change.

## Modify: Custom Post-Install Steps

The `main()` function calls each install step in sequence. To add a custom step, define a new function and call it from `main()`.

First, add the function definition anywhere above `main()`. Following the existing naming pattern (`install_nodejs`, `install_nemoclaw`), prefix it with `install_`:

```bash
# install.sh -- add Acme tools installation
install_acme_tools() {                                 # <-- ADD THIS
  info "Installing Acme development tools..."          # <-- ADD THIS
  npm install -g @acme/cli                             # <-- ADD THIS
  info "Acme CLI installed"                            # <-- ADD THIS
}                                                      # <-- ADD THIS
```

Then update `main()` to call the new function. This is also where you uncomment `install_or_upgrade_ollama` if you customized the Ollama thresholds above:

```bash
main() {
  info "=== NemoClaw Installer ==="
  install_nodejs
  ensure_supported_runtime
  install_or_upgrade_ollama                            # <-- UNCOMMENT THIS
  install_nemoclaw
  install_acme_tools                                   # <-- ADD THIS
  verify_nemoclaw
  post_install_message
  run_onboard
  info "=== Installation complete ==="
}
```

The function runs after `install_nemoclaw` so that NemoClaw and Node.js are already available. If your custom tools have no dependency on NemoClaw, you can place the call earlier in the sequence.

## Validate

Run these commands from the repository root to verify your changes:

Check syntax without executing:

```console
$ bash -n install.sh
```

Verify the Node.js version change:

```console
$ grep RECOMMENDED_NODE_MAJOR install.sh
```

Verify the medium VRAM tier was added:

```console
$ grep -A5 "vram_gb >= 48" install.sh
```

Verify the package source change:

```console
$ grep "npm install -g" install.sh
```

Verify the custom function is defined and called in `main()`:

```console
$ grep "install_acme_tools" install.sh
```

The last command should show two matches: the function definition and the call in `main()`.

## What's Next

Proceed to the [Auxiliary Services](auxiliary-services.md) page to add custom bridge services to `start-services.sh`.
