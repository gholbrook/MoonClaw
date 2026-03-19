---
title:
  page: "Blueprint Customization"
  nav: "Blueprint"
description: "Add inference profiles, customize the sandbox, and work around the digest field."
keywords: ["nemoclaw blueprint", "nemoclaw inference profiles"]
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

# Blueprint Customization

:::{warning}
**Comma-string syntax required for profiles**

The blueprint manifest header is parsed by regex, not a YAML parser. The `profiles:` field in the manifest header MUST be a comma-separated string on a single line (e.g., `profiles: default, ncp, claude`), not a YAML list. Using YAML list syntax will silently break profile resolution, falling back to `["default"]` only. See the [YAML regex parser pitfall](overview.md#known-pitfalls) for details.
:::

The blueprint is the Python orchestrator that defines inference profiles, sandbox configuration, and orchestration steps. It lives at `nemoclaw-blueprint/blueprint.yaml`. The `components:` section is parsed by Python's `yaml.safe_load()` in `runner.py`, but the manifest header (version, digest, profiles list) is parsed by regex in `resolve.ts`.

This dual-parser architecture is the source of the comma-string pitfall warned about above. The manifest header fields must be simple single-line key-value pairs because `parseManifestHeader()` extracts each field with a regex like `^profiles:\s*(.+)$` and splits on commas.

The blueprint sits third in the dependency chain, after `install.sh` and the onboard wizard, and before the plugin. Changes you make here control which inference providers are available and how the sandbox container is configured.

## What the Blueprint Controls

`components.inference.profiles`
: A map of named inference profiles, each specifying a provider type, endpoint URL, model, and credential env var. The runner selects one profile at launch time and uses it to configure the sandbox inference route.

`components.sandbox`
: Sandbox container settings including image source, container name, and forwarded ports. These values are passed to OpenShell when creating the sandbox.

`manifest header`
: Top-level fields (version, digest, profiles list) parsed by regex in `resolve.ts`. The profiles list determines which profile names the plugin considers valid.

`orchestrator/runner.py`
: The Python script that reads `blueprint.yaml` via `yaml.safe_load()` and executes the `action_plan()` pipeline. It consumes the `components:` section to resolve profiles, sandbox settings, and policy additions.

## Locate the File

The primary file is `nemoclaw-blueprint/blueprint.yaml`. This is the file you edit to add profiles, change sandbox settings, or update the digest.

Supporting files you may want to reference while making changes:

- `nemoclaw-blueprint/orchestrator/runner.py` consumes the blueprint via `yaml.safe_load()` and uses the `components.inference.profiles` map to resolve the selected profile.
- `nemoclaw/src/blueprint/resolve.ts` contains `parseManifestHeader()`, the regex-based parser that reads the manifest header fields including the profiles list.
- `nemoclaw/src/blueprint/verify.ts` contains `verifyBlueprintDigest()`, which checks the digest field against a SHA-256 hash of the blueprint directory.

## Modify: Add a Custom Inference Profile

This section continues the Acme Corp scenario from the onboard wizard page. You will add a Claude inference profile so that the blueprint can route requests to the Anthropic API.

**Update the manifest header.** Open `nemoclaw-blueprint/blueprint.yaml` and find the `profiles:` line near the top of the file. Add your new profile name to the comma-separated list. Remember that this line is parsed by regex, not a YAML parser, so it must remain a single comma-separated line.

Before:

```yaml
profiles: default, ncp, nim-local, vllm
```

After:

```yaml
profiles: default, ncp, nim-local, vllm, claude     # <-- ADD "claude"
```

**Add the profile definition.** Scroll down to the `components.inference.profiles` section and add the new profile block. The existing profiles provide context for the structure.

```yaml
components:
  inference:
    profiles:
      default:
        provider_type: "nvidia"
        provider_name: "nvidia-inference"
        endpoint: "https://integrate.api.nvidia.com/v1"
        model: "nvidia/nemotron-3-super-120b-a12b"

      ncp:
        provider_type: "nvidia"
        provider_name: "nvidia-ncp"
        endpoint: ""
        model: "nvidia/nemotron-3-super-120b-a12b"
        credential_env: "NVIDIA_API_KEY"
        dynamic_endpoint: true

      claude:                                        # <-- ADD THIS
        provider_type: "openai"                      # <-- ADD THIS
        provider_name: "acme-claude"                 # <-- ADD THIS
        endpoint: "https://api.anthropic.com/v1"     # <-- ADD THIS
        model: "claude-sonnet-4-20250514"          # <-- ADD THIS
        credential_env: "ANTHROPIC_API_KEY"          # <-- ADD THIS
```

The `provider_type: "openai"` field means this profile uses the OpenAI-compatible API format, which the Anthropic API supports. The `credential_env: "ANTHROPIC_API_KEY"` field references the environment variable that holds the API key. Never put the actual key in this file. The runner reads the key from the environment at launch time using `os.environ.get(credential_env)`.

## Modify: Customize Sandbox Configuration

The `components.sandbox` section controls the container that OpenShell creates for the sandboxed agent. You can change the image source, container name, and forwarded ports.

```yaml
components:
  sandbox:
    image: "ghcr.io/acme/nemoclaw-sandbox:latest"   # <-- CHANGE to your registry
    name: "acme-openclaw"                            # <-- CHANGE container name
    forward_ports:
      - 18789
      - 8080                                         # <-- ADD extra port
```

`image`
: The Docker image pulled for the sandbox. Change this to your own registry if you maintain a custom sandbox image with additional tools or packages pre-installed.

`name`
: The container name passed to OpenShell. This must be unique if you run multiple sandboxes on the same machine. The default is `openclaw`.

`forward_ports`
: A list of ports mapped from the sandbox container to the host. The default port `18789` is used by the OpenClaw API. Add additional ports if your custom tools need host-accessible endpoints.

## Working Around the Digest Field

Line 8 of `blueprint.yaml` contains a `digest` field. When this field is non-empty, `verifyBlueprintDigest()` in `verify.ts` computes a SHA-256 hash of the entire blueprint directory and rejects the blueprint if the hashes do not match.

The workaround is to set `digest` to an empty string:

```yaml
digest: ""  # Leave empty during development to skip digest verification
```

When digest is empty, the verification function short-circuits. The check in `verify.ts` reads:

```typescript
if (manifest.digest && manifest.digest !== actualDigest) {
  errors.push(`Digest mismatch: expected ${manifest.digest}, got ${actualDigest}`);
}
```

The falsy empty string causes the condition to skip entirely, so no verification is performed. Only compute and set the digest at release time when the blueprint is finalized and you want to prevent accidental modifications.

:::{note}
See [Known Pitfalls](overview.md#known-pitfalls) for additional issues that affect blueprint customization, including the fetch stub limitation and secrets hygiene guidelines.
:::

## Validate Your Changes

Run this command to validate the YAML syntax of your modified blueprint:

```console
$ python3 -c "import yaml; yaml.safe_load(open('nemoclaw-blueprint/blueprint.yaml')); print('YAML syntax OK')"
```

This validates the `components:` section that is parsed by `yaml.safe_load()` in `runner.py`. It does not validate the manifest header, which is regex-parsed. To verify the profiles list, visually confirm that the `profiles:` field is a single comma-separated line (e.g., `profiles: default, ncp, nim-local, vllm, claude`) and that your new profile name is included.

## What's Next

Proceed to the [Network Policy](network-policy.md) page to create custom policy presets that control what your sandbox can access on the network.
