---
title:
  page: "Network Policy Customization"
  nav: "Network Policy"
description: "Create custom network policy presets and modify sandbox egress rules."
keywords: ["nemoclaw network policy", "nemoclaw egress rules"]
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

# Network Policy Customization

Network policies control what the sandboxed agent can access on the network. Every sandbox starts with a base policy that allows traffic to core services like the NVIDIA inference API, GitHub, and the OpenClaw plugin registry. When your agent needs to reach additional services, you either modify the base policy or create a composable preset.

Policies live in the `nemoclaw-blueprint/policies/` directory. There are two types of policy files: the base sandbox policy, which is applied to every sandbox, and composable presets, which are added for specific services. Policies sit at the end of the dependency chain. They are applied to the running container after the Docker image is built, so you can iterate on policies without rebuilding the image.

This page walks through the base policy structure, shows how to create a custom preset for database egress, and provides a supplementary example for cache access.

## What Policies Control

`openclaw-sandbox.yaml`
: The base policy applied to every sandbox. It already includes rules for `claude_code`, `nvidia`, `github`, `clawhub`, `openclaw_api`, `openclaw_docs`, `npm_registry`, and `telegram`. Modifying this file changes the default behavior for all sandboxes.

`presets/*.yaml`
: Composable policy additions for specific services. Each preset file defines one or more named policy blocks that can be added to a sandbox alongside the base policy. The preset directory ships with policies for discord, docker, huggingface, jira, npm, outlook, pypi, slack, and telegram.

`endpoints`
: Each policy block defines a list of endpoints. An endpoint specifies a `host`, `port`, `protocol`, `enforcement` mode, and access `rules` that control what traffic is allowed.

`enforcement`
: Set to `enforce` to block traffic that does not match the rules. This is the standard mode for all production policies.

`tls`
: TLS termination setting for HTTPS endpoints. Set to `terminate` for services that use TLS on port 443.

## Locate the Files

The base policy and preset directory are in the blueprint policies folder.

Base policy
: `nemoclaw-blueprint/policies/openclaw-sandbox.yaml`

Preset directory
: `nemoclaw-blueprint/policies/presets/`

The preset directory contains these files:

- `discord.yaml`
- `docker.yaml`
- `huggingface.yaml`
- `jira.yaml`
- `npm.yaml`
- `outlook.yaml`
- `pypi.yaml`
- `slack.yaml`
- `telegram.yaml`

## Understand the Base Sandbox Policy

The base policy in `openclaw-sandbox.yaml` defines the `network_policies:` top-level key with named policy blocks. Each block contains an `endpoints` array. Here is a representative excerpt showing two of the built-in policy blocks.

```yaml
# File: nemoclaw-blueprint/policies/openclaw-sandbox.yaml (excerpt)
network_policies:
  nvidia:
    name: nvidia
    endpoints:
      - host: integrate.api.nvidia.com
        port: 443
        protocol: rest
        enforcement: enforce
        tls: terminate
        rules:
          - allow: { method: "*", path: "/**" }
      - host: inference-api.nvidia.com
        port: 443
        protocol: rest
        enforcement: enforce
        tls: terminate
        rules:
          - allow: { method: "*", path: "/**" }
    binaries:
      - { path: /usr/local/bin/claude }
      - { path: /usr/local/bin/openclaw }

  npm_registry:
    name: npm_registry
    endpoints:
      - host: registry.npmjs.org
        port: 443
        access: full
    binaries:
      - { path: /usr/local/bin/openclaw }
      - { path: /usr/local/bin/npm }
```

To add a new egress rule to the base policy, add a new named policy block under `network_policies:`. For example, to allow traffic to an internal monitoring service:

```yaml
# File: nemoclaw-blueprint/policies/openclaw-sandbox.yaml (excerpt)
network_policies:
  # ... existing policy blocks ...

  acme_monitoring:                                       # <-- ADD THIS
    name: acme_monitoring                                # <-- ADD THIS
    endpoints:                                           # <-- ADD THIS
      - host: monitoring.acme.internal                   # <-- ADD THIS
        port: 443                                        # <-- ADD THIS
        protocol: rest                                   # <-- ADD THIS
        enforcement: enforce                             # <-- ADD THIS
        tls: terminate                                   # <-- ADD THIS
        rules:                                           # <-- ADD THIS
          - allow: { method: POST, path: "/v1/metrics" } # <-- ADD THIS
```

This approach works when the service should be accessible to every sandbox by default. For services that only some sandboxes need, create a preset instead.

## Create a Custom Preset

Presets are composable. Create a new file in `presets/` and it becomes available to add to sandboxes. Each preset file requires two top-level keys: `preset:` (with `name` and `description`) and `network_policies:` (with one or more named policy blocks).

The following example creates a preset for PostgreSQL database access. This demonstrates a non-HTTP use case where the protocol is TCP rather than REST.

```yaml
# File: nemoclaw-blueprint/policies/presets/postgresql.yaml
preset:
  name: postgresql
  description: "PostgreSQL database access for custom tooling"

network_policies:
  postgresql:
    name: postgresql
    endpoints:
      - host: db.acme.internal              # <-- Your database hostname
        port: 5432                           # <-- PostgreSQL default port
        protocol: tcp                        # <-- TCP for database connections
        enforcement: enforce
        rules:
          - allow: {}                        # <-- Allow all TCP traffic to this endpoint
```

Here is what each field does.

`preset.name` and `preset.description`
: Required metadata fields. The name identifies the preset and the description explains what it enables.

`network_policies.<name>.name`
: The policy block name. This typically matches the preset name.

`endpoints[].host`
: The target hostname. Use internal DNS names for private services (like `db.acme.internal`) and public hostnames for external services.

`endpoints[].port`
: The target port number.

`endpoints[].protocol`
: Set to `rest` for HTTP/HTTPS services or `tcp` for raw TCP connections such as databases and message queues.

`endpoints[].enforcement`
: Set to `enforce` to block traffic that does not match the rules.

`endpoints[].rules`
: Access rules for the endpoint. Use `- allow: {}` to permit all traffic to this endpoint. For HTTP services, use `method` and `path` constraints such as `- allow: { method: GET, path: "/**" }`.

:::{note}
The `protocol: tcp` value is used here for the PostgreSQL example. All existing presets in the repository use `protocol: rest` with HTTP method and path rules. The TCP protocol option has not been verified against a running OpenShell instance. If TCP enforcement does not work as expected, fall back to `protocol: rest` with permissive rules.
:::

For contrast, HTTP-style presets like the Slack preset use `protocol: rest` with method and path rules:

```yaml
# File: nemoclaw-blueprint/policies/presets/slack.yaml (excerpt)
network_policies:
  slack:
    name: slack
    endpoints:
      - host: slack.com
        port: 443
        protocol: rest
        enforcement: enforce
        tls: terminate
        rules:
          - allow: { method: GET, path: "/**" }
          - allow: { method: POST, path: "/**" }
```

## Add Egress for a Redis Cache

To reinforce the preset pattern, here is a second example for Redis cache access. The structure is the same as the PostgreSQL preset with different host and port values.

```yaml
# File: nemoclaw-blueprint/policies/presets/redis.yaml
preset:
  name: redis
  description: "Redis cache access for session storage"

network_policies:
  redis:
    name: redis
    endpoints:
      - host: cache.acme.internal            # <-- Your Redis hostname
        port: 6379                            # <-- Redis default port
        protocol: tcp                         # <-- TCP for Redis connections
        enforcement: enforce
        rules:
          - allow: {}                         # <-- Allow all TCP traffic to this endpoint
```

:::{note}
See [Known Pitfalls](overview.md#known-pitfalls) for general policy pitfalls and other common issues when customizing your fork.
:::

## Validate Your Changes

After creating or modifying a preset file, validate the YAML syntax and required top-level keys.

```console
$ python3 -c "import yaml; d=yaml.safe_load(open('nemoclaw-blueprint/policies/presets/postgresql.yaml')); assert 'preset' in d and 'network_policies' in d; print('Preset structure OK')"
Preset structure OK
```

This command checks that the file is valid YAML and contains both the `preset` and `network_policies` keys. Run the same command for any preset file you create or modify, replacing the file path as needed.

## What's Next

You have now customized all four YAML-only extension surfaces. The next phase of the tutorial covers the Developer Surface, which includes the plugin API, agents, Docker images, and web UI. That phase requires the TypeScript build pipeline.
