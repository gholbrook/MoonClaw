---
title:
  page: "Onboard Wizard Customization"
  nav: "Onboard Wizard"
description: "Add new endpoint types, customize default models, and extend the onboard wizard."
keywords: ["nemoclaw onboard wizard", "nemoclaw endpoint types"]
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

# Onboard Wizard Customization

The onboard wizard is the interactive flow that runs after `install.sh` completes. It prompts the developer to select an inference endpoint, choose a model, and provide credentials. The wizard then writes the selected configuration to `~/.nemoclaw/config.json`, which downstream surfaces consume.

In the [dependency chain](overview.md#dependency-order), the onboard wizard sits second: it runs after the install script and before the blueprint. Changes to the wizard affect what endpoint types, models, and credential mappings are available during onboarding, and the resulting `config.json` drives blueprint profile selection.

This page walks through adding a new endpoint type to the wizard using the "Acme Corp adding a Claude endpoint" scenario. You will modify four locations in the TypeScript source, then validate with a build command.

## What the Wizard Controls

`EndpointType`
: The TypeScript union type that defines all valid endpoint identifiers. Found in `config.ts` line 9, it currently contains `"build" | "ncp" | "nim-local" | "vllm" | "ollama" | "custom"`.

`ENDPOINT_TYPES`
: The array of available endpoint types shown to the user during onboarding. Found in `onboard.ts` line 25, it lists every value from the `EndpointType` union.

`DEFAULT_MODELS`
: The default model options presented when the endpoint's model list cannot be fetched. Found in `onboard.ts` lines 35-40, it provides labeled model identifiers for selection prompts.

`resolveProfile()`
: Maps each endpoint type to a blueprint profile name. When the user selects an endpoint, this function determines which `blueprint.yaml` profile governs inference routing.

`resolveCredentialEnv()`
: Maps each endpoint type to its credential environment variable name. The returned variable name (such as `NVIDIA_API_KEY` or `OPENAI_API_KEY`) is stored in `config.json` and used by the blueprint runner to locate the API key at runtime.

`config.json`
: The output file at `~/.nemoclaw/config.json` containing the selected endpoint type, endpoint URL, model, profile name, and credential environment variable. Every downstream surface reads this file to resolve inference configuration.

## Locate the Files

Adding a new endpoint type requires modifications in four locations across two files.

1. `nemoclaw/src/onboard/config.ts` -- `EndpointType` union (line 9)
2. `nemoclaw/src/commands/onboard.ts` -- `ENDPOINT_TYPES` array (line 25)
3. `nemoclaw/src/commands/onboard.ts` -- `resolveProfile()` switch (line 42)
4. `nemoclaw/src/commands/onboard.ts` -- `resolveCredentialEnv()` switch (line 74)

:::{tip}
This is a TypeScript change. After editing these files, you must run `npm run build` in the `nemoclaw/` directory to compile and type-check your changes.
:::

## Add the "claude" Endpoint Type

This section uses the Acme Corp scenario: adding a `claude` endpoint type that routes inference to the Anthropic API.

### Update the EndpointType Union

Open `nemoclaw/src/onboard/config.ts` and add `"claude"` to the union type.

```typescript
export type EndpointType = "build" | "ncp" | "nim-local" | "vllm" | "ollama" | "custom" | "claude";  // <-- ADD "claude"
```

### Update the ENDPOINT_TYPES Array

Open `nemoclaw/src/commands/onboard.ts` and add `"claude"` to the array.

```typescript
const ENDPOINT_TYPES: EndpointType[] = ["build", "ncp", "nim-local", "vllm", "ollama", "custom", "claude"];  // <-- ADD "claude"
```

### Update resolveProfile()

In the same file, add a case to the `resolveProfile()` switch statement that maps `claude` to a profile name.

```typescript
function resolveProfile(endpointType: EndpointType): string {
  switch (endpointType) {
    case "build":
      return "default";
    case "ncp":
    case "custom":
      return "ncp";
    case "nim-local":
      return "nim-local";
    case "vllm":
      return "vllm";
    case "ollama":
      return "ollama";
    case "claude":          // <-- ADD THIS
      return "claude";      // <-- ADD THIS
  }
}
```

### Update resolveCredentialEnv()

Add a case that maps `claude` to the `ANTHROPIC_API_KEY` environment variable.

```typescript
function resolveCredentialEnv(endpointType: EndpointType): string {
  switch (endpointType) {
    case "build":
    case "ncp":
    case "custom":
      return "NVIDIA_API_KEY";
    case "nim-local":
      return "NIM_API_KEY";
    case "vllm":
    case "ollama":
      return "OPENAI_API_KEY";
    case "claude":              // <-- ADD THIS
      return "ANTHROPIC_API_KEY";  // <-- ADD THIS
  }
}
```

### Resulting config.json

After onboarding with the `claude` endpoint type, the wizard writes the following to `~/.nemoclaw/config.json`.

```json
{
  "endpointType": "claude",
  "endpointUrl": "https://api.anthropic.com/v1",
  "ncpPartner": null,
  "model": "claude-sonnet-4-20250514",
  "profile": "claude",
  "credentialEnv": "ANTHROPIC_API_KEY",
  "onboardedAt": "2026-01-15T10:30:00.000Z"
}
```

The `credentialEnv` field tells the blueprint runner to read the API key from the `ANTHROPIC_API_KEY` environment variable at runtime, rather than storing the key directly in the configuration file.

## Change Default Models

You can also change the default model for an existing endpoint type by editing the `DEFAULT_MODELS` array in `onboard.ts`. These defaults are shown when the wizard cannot fetch models from the endpoint.

For example, to change the default model for the `build` endpoint from `nvidia/nemotron-3-super-120b-a12b` to a different model:

```typescript
const DEFAULT_MODELS = [
  { id: "nvidia/llama-3.3-nemotron-super-49b-v1.5", label: "Nemotron Super 49B v1.5" },  // <-- CHANGED
  { id: "nvidia/llama-3.1-nemotron-ultra-253b-v1", label: "Nemotron Ultra 253B" },
  { id: "nvidia/nemotron-3-nano-30b-a3b", label: "Nemotron 3 Nano 30B" },
];
```

:::{note}
See [Known Pitfalls](overview.md#known-pitfalls) for the SDK import constraint that affects TypeScript plugin development. The onboard wizard files are part of the NemoClaw plugin and follow the same build constraints.
:::

## Validate Your Changes

Run the TypeScript compiler to verify that all four locations are consistent. The compiler catches missing switch cases and type errors.

```bash
cd nemoclaw && npm run build
```

A clean build with no errors confirms that the `EndpointType` union, `ENDPOINT_TYPES` array, and both switch statements are in agreement.

## What's Next

Next, configure the environment variables that control non-interactive onboarding in the [Environment Variables](env-vars.md) page. After that, proceed to the [Blueprint](blueprint.md) page to add the matching `claude` inference profile.
