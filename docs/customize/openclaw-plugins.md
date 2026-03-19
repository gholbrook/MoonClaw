---
title:
  page: "OpenClaw Plugin API"
  nav: "OpenClaw Plugins"
description: "Register custom inference providers, CLI commands, and background services in the NemoClaw plugin."
keywords: ["nemoclaw plugin api", "nemoclaw custom provider"]
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

# OpenClaw Plugin API

The NemoClaw TypeScript plugin uses the OpenClaw plugin API to register inference providers, CLI commands, slash commands, and background services. The `register()` function in `nemoclaw/src/index.ts` is the plugin entry point. The OpenClaw host calls it at startup and passes an `OpenClawPluginApi` object that exposes the registration methods.

This page continues the Acme Corp scenario from previous pages. You will extend the plugin with a custom Claude provider, a status CLI command, and a metrics collector service.

## What the Plugin API Controls

`registerProvider(provider)`
: Adds a custom inference provider with model catalog, auth methods, and environment variable references. The OpenClaw host makes the provider available in model selection.

`registerCli(registrar, opts?)`
: Adds subcommands under `openclaw nemoclaw` using commander.js. The registrar callback receives a `PluginCliContext` object containing the commander program instance, logger, and config.

`registerService(service)`
: Registers a background service with `start` and optional `stop` lifecycle methods. The OpenClaw host calls these during plugin lifecycle events.

`registerCommand(command)`
: Adds a slash command accessible from the chat interface. NemoClaw already registers `/nemoclaw` in the default codebase. This is not a typical customization target.

## Local Type Stubs

The `openclaw/plugin-sdk` package is only available inside the OpenClaw host runtime process. It is not published to npm and cannot be installed as a dependency. If you try to `import { ProviderPlugin } from "openclaw/plugin-sdk"` at build time, the TypeScript compiler will fail because the package does not exist on disk.

The solution is to define minimal TypeScript interfaces locally that match the runtime SDK shapes. You import these local stubs during development and compilation. At runtime, the OpenClaw host provides the real implementations that conform to these same interfaces.

The comment block at the top of `nemoclaw/src/index.ts` explains this pattern:

```typescript
/**
 * NemoClaw — OpenClaw Plugin for OpenShell
 *
 * Uses the real OpenClaw plugin API. Types defined locally are minimal stubs
 * that match the OpenClaw SDK interfaces available at runtime via
 * `openclaw/plugin-sdk`. We define them here because the SDK package is only
 * available inside the OpenClaw host process and cannot be imported at build
 * time.
 */
```

The key type stubs defined in `nemoclaw/src/index.ts` are shown below. These are the interfaces you work with when extending the plugin.

```typescript
// ---------------------------------------------------------------------------
// OpenClaw Plugin SDK compatible types (mirrors openclaw/plugin-sdk)
// ---------------------------------------------------------------------------

/** Registration shape for a custom model provider. */
export interface ProviderPlugin {
  id: string;
  label: string;
  docsPath?: string;
  aliases?: string[];
  envVars?: string[];
  models?: ModelProviderConfig;
  auth: ProviderAuthMethod[];
}

/** Auth method for a provider plugin. */
export interface ProviderAuthMethod {
  type: string;
  envVar?: string;
  headerName?: string;
  label?: string;
}

/** Model catalog shape. */
export interface ModelProviderConfig {
  chat?: ModelProviderEntry[];
  completion?: ModelProviderEntry[];
}

/** Model entry in a provider's model catalog. */
export interface ModelProviderEntry {
  id: string;
  label: string;
  contextWindow?: number;
  maxOutput?: number;
}

/** Background service registration. */
export interface PluginService {
  id: string;
  start: (ctx: { config: OpenClawConfig; logger: PluginLogger }) => void | Promise<void>;
  stop?: (ctx: { config: OpenClawConfig; logger: PluginLogger }) => void | Promise<void>;
}

/** CLI registrar callback type. */
export type PluginCliRegistrar = (ctx: PluginCliContext) => void | Promise<void>;

/** The API object injected into the plugin's register function. */
export interface OpenClawPluginApi {
  id: string;
  name: string;
  version?: string;
  config: OpenClawConfig;
  pluginConfig?: Record<string, unknown>;
  logger: PluginLogger;
  registerCommand: (command: PluginCommandDefinition) => void;
  registerCli: (registrar: PluginCliRegistrar, opts?: { commands?: string[] }) => void;
  registerProvider: (provider: ProviderPlugin) => void;
  registerService: (service: PluginService) => void;
  resolvePath: (input: string) => string;
  on: (hookName: string, handler: (...args: unknown[]) => void) => void;
}
```

The build pattern works as follows. `tsc` compiles your plugin against these local stubs and produces JavaScript in the `dist/` directory. When the OpenClaw host loads `dist/index.js`, it injects a real `OpenClawPluginApi` instance that conforms to the same interface. Your compiled code calls methods on that real object without ever having imported the SDK package at build time.

## Locate the Files

The files involved in plugin registration are:

- **`nemoclaw/src/index.ts`** is the plugin entry point. It contains the local type stubs and the `register()` function that calls `registerProvider`, `registerCli`, `registerCommand`, and `registerService`.
- **`nemoclaw/src/cli.ts`** contains the `registerCliCommands()` function. It receives a commander.js program instance and wires up subcommands under `openclaw nemoclaw`.
- **`nemoclaw/openclaw.plugin.json`** is the plugin manifest. It declares the plugin ID, name, version, and `configSchema` that defines the plugin's configuration options.
- **`nemoclaw/package.json`** contains the build scripts. The `build` script runs `tsc` to compile TypeScript to JavaScript in the `dist/` directory.

## Modify: Register a Custom Provider

This section adds an `acme-claude` inference provider to the plugin. The new provider appears alongside the existing `nvidia-nim` provider in the OpenClaw model selection.

Open `nemoclaw/src/index.ts` and find the `register()` function. Add the `api.registerProvider()` call for the Acme Claude provider after the existing NVIDIA NIM registration.

```typescript
export default function register(api: OpenClawPluginApi): void {
  // 1. Register /nemoclaw slash command (chat interface)
  api.registerCommand({
    name: "nemoclaw",
    description: "NemoClaw sandbox management (status, eject).",
    acceptsArgs: true,
    handler: (ctx) => handleSlashCommand(ctx, api),
  });

  // 2. Register `openclaw nemoclaw` CLI subcommands (commander.js)
  api.registerCli(
    (cliCtx) => {
      registerCliCommands(cliCtx, api);
    },
    { commands: ["nemoclaw"] },
  );

  // 3. Register nvidia-nim provider — use onboard config if available
  const onboardCfg = loadOnboardConfig();
  const providerCredentialEnv = onboardCfg?.credentialEnv ?? "NVIDIA_API_KEY";
  const providerLabel = onboardCfg
    ? `NVIDIA NIM (${onboardCfg.endpointType}${onboardCfg.ncpPartner ? ` - ${onboardCfg.ncpPartner}` : ""})`
    : "NVIDIA NIM (build.nvidia.com)";

  api.registerProvider({
    id: "nvidia-nim",
    label: providerLabel,
    docsPath: "https://build.nvidia.com/docs",
    aliases: ["nvidia", "nim"],
    envVars: [providerCredentialEnv],
    models: {
      chat: [
        {
          id: "nvidia/nemotron-3-super-120b-a12b",
          label: "Nemotron 3 Super 120B (March 2026)",
          contextWindow: 131072,
          maxOutput: 8192,
        },
        // ... other NVIDIA models
      ],
    },
    auth: [
      {
        type: "bearer",
        envVar: providerCredentialEnv,
        headerName: "Authorization",
        label: `NVIDIA API Key (${providerCredentialEnv})`,
      },
    ],
  });

  // 4. Register acme-claude provider                            // <-- ADD THIS
  api.registerProvider({                                         // <-- ADD THIS
    id: "acme-claude",                                           // <-- ADD THIS
    label: "Acme Claude (Anthropic)",                            // <-- ADD THIS
    docsPath: "https://docs.anthropic.com",                      // <-- ADD THIS
    aliases: ["claude", "anthropic"],                             // <-- ADD THIS
    envVars: ["ANTHROPIC_API_KEY"],                               // <-- ADD THIS
    models: {                                                    // <-- ADD THIS
      chat: [                                                    // <-- ADD THIS
        {                                                        // <-- ADD THIS
          id: "claude-sonnet-4-20250514",                      // <-- ADD THIS
          label: "Claude Sonnet 4 (May 2025)",                 // <-- ADD THIS
          contextWindow: 200000,                                 // <-- ADD THIS
          maxOutput: 16384,                                      // <-- ADD THIS
        },                                                       // <-- ADD THIS
      ],                                                         // <-- ADD THIS
    },                                                           // <-- ADD THIS
    auth: [                                                      // <-- ADD THIS
      {                                                          // <-- ADD THIS
        type: "bearer",                                          // <-- ADD THIS
        envVar: "ANTHROPIC_API_KEY",                             // <-- ADD THIS
        headerName: "x-api-key",                                 // <-- ADD THIS
        label: "Anthropic API Key (ANTHROPIC_API_KEY)",          // <-- ADD THIS
      },                                                         // <-- ADD THIS
    ],                                                           // <-- ADD THIS
  });                                                            // <-- ADD THIS

  // ... banner logging omitted for brevity
}
```

The `ProviderPlugin` fields control how the OpenClaw host presents and authenticates the provider.

`id`
: A unique string identifying this provider. Used internally by the host to route inference requests.

`label`
: A human-readable name shown in the model selection UI.

`docsPath`
: An optional URL linking to the provider's documentation.

`aliases`
: Alternative names that the host accepts when selecting this provider.

`envVars`
: Environment variables that the host checks for provider credentials.

`models.chat`
: An array of model entries with `id`, `label`, `contextWindow`, and `maxOutput`. The host uses these to populate the model catalog.

`auth`
: An array of authentication methods. Each method specifies a `type` (e.g., `"bearer"`), the `envVar` holding the secret, and the `headerName` used in API requests.

## Modify: Add a CLI Command

This section adds an `acme-status` subcommand under `openclaw nemoclaw`. The new command checks the health of the Acme Claude endpoint.

Open `nemoclaw/src/cli.ts` and find the `registerCliCommands()` function. Add the new subcommand after the existing `onboard` command.

```typescript
export function registerCliCommands(ctx: PluginCliContext, api: OpenClawPluginApi): void {
  const { program, logger } = ctx;
  const pluginConfig = getPluginConfig(api);

  const nemoclaw = program.command("nemoclaw").description("NemoClaw sandbox management");

  // openclaw nemoclaw status
  nemoclaw
    .command("status")
    .description("Show sandbox, blueprint, and inference state")
    .option("--json", "Output as JSON", false)
    .action(async (opts: { json: boolean }) => {
      await cliStatus({ json: opts.json, logger, pluginConfig });
    });

  // ... other existing commands (migrate, launch, connect, logs, eject) ...

  // openclaw nemoclaw onboard
  nemoclaw
    .command("onboard")
    .description("Interactive setup: configure inference endpoint, credential, and model")
    .option("--api-key <key>", "API key for endpoints that require one (skips prompt)")
    .option("--endpoint <type>", "Endpoint type: build, ncp, nim-local, vllm, ollama, custom")
    .option("--ncp-partner <name>", "NCP partner name (when endpoint is ncp)")
    .option("--endpoint-url <url>", "Endpoint URL (for ncp, nim-local, ollama, or custom)")
    .option("--model <model>", "Model ID to use")
    .action(async (opts) => {
      await cliOnboard({ ...opts, logger, pluginConfig });
    });

  // openclaw nemoclaw acme-status                               // <-- ADD THIS
  nemoclaw                                                       // <-- ADD THIS
    .command("acme-status")                                      // <-- ADD THIS
    .description("Check Acme Claude endpoint health")            // <-- ADD THIS
    .action(async () => {                                        // <-- ADD THIS
      logger.info("Checking Acme Claude endpoint...");           // <-- ADD THIS
      const apiKey = process.env["ANTHROPIC_API_KEY"];           // <-- ADD THIS
      if (!apiKey) {                                             // <-- ADD THIS
        logger.error("ANTHROPIC_API_KEY is not set");            // <-- ADD THIS
        return;                                                  // <-- ADD THIS
      }                                                          // <-- ADD THIS
      logger.info("ANTHROPIC_API_KEY is configured");            // <-- ADD THIS
      logger.info("Acme Claude endpoint check complete");        // <-- ADD THIS
    });                                                          // <-- ADD THIS
}
```

The new command follows the same pattern as existing subcommands. It uses `nemoclaw.command()` to register under the `openclaw nemoclaw` namespace, `.description()` to set the help text, and `.action()` to define the handler. The handler reads `ANTHROPIC_API_KEY` from the environment and reports whether it is configured.

## Modify: Add a Background Service

This section adds a background service that collects metrics during the plugin lifecycle. The service demonstrates the `registerService` API.

Open `nemoclaw/src/index.ts` and add the `api.registerService()` call inside the `register()` function, after the provider registrations.

```typescript
  // 5. Register acme-metrics background service                 // <-- ADD THIS
  api.registerService({                                          // <-- ADD THIS
    id: "acme-metrics",                                          // <-- ADD THIS
    start: async (ctx) => {                                      // <-- ADD THIS
      ctx.logger.info("Acme metrics collector started");         // <-- ADD THIS
    },                                                           // <-- ADD THIS
    stop: async (ctx) => {                                       // <-- ADD THIS
      ctx.logger.info("Acme metrics collector stopped");         // <-- ADD THIS
    },                                                           // <-- ADD THIS
  });                                                            // <-- ADD THIS
```

:::{note}
NemoClaw does not currently use `registerService`. This example is authored from the `PluginService` interface definition. Service lifecycle timing depends on the OpenClaw host. The host calls `start` when the plugin activates and `stop` when the plugin deactivates or the host shuts down.
:::

The `PluginService` interface requires an `id` and a `start` function. The `stop` function is optional. Both receive a context object with `config` and `logger` properties, matching the `PluginService` type stub defined earlier on this page.

## Validate

After making changes, build the plugin to verify that the TypeScript compiler accepts the new registrations.

```console
$ cd nemoclaw && npm run build
```

This runs `tsc`, which compiles `src/` to `dist/` using the settings in `tsconfig.json` (target ES2022, module Node16, strict mode enabled).

Check that the compiled output contains the new provider ID:

```console
$ grep "acme-claude" dist/index.js
```

Check that the compiled output contains the new CLI command:

```console
$ grep "acme-status" dist/cli.js
```

If both commands produce output, the new registrations compiled successfully. Full runtime testing requires the OpenClaw host environment, which loads the compiled `dist/index.js` and injects the real `OpenClawPluginApi` instance.

## What's Next

Proceed to the [Agents and Skills](agents-and-skills.md) page to pre-configure custom agents and skills for the sandbox image.
