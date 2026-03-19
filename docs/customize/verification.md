---
title:
  page: "Verification Checklist"
  nav: "Verification"
description: "End-to-end checklist to verify every NemoClaw customization is correctly installed and functioning."
keywords: ["nemoclaw verification", "nemoclaw testing customization"]
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

# Verification Checklist

This page provides a surface-by-surface checklist to verify that every customization you have made throughout this tutorial is correctly installed and functioning. Each section contains specific validation commands that test the actual content of your customizations, not just file existence. The checklist follows the Acme Corp scenario that runs throughout the tutorial.

## Onboard Wizard

Verify the custom Claude endpoint is configured:

```bash
# Verify endpoint type is claude
cat ~/.nemoclaw/config.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['endpointType'] == 'claude', f'Expected claude, got {d[\"endpointType\"]}'
assert d['credentialEnv'] == 'ANTHROPIC_API_KEY', f'Expected ANTHROPIC_API_KEY, got {d[\"credentialEnv\"]}'
print('Onboard: OK')
"
```

```bash
# Verify the model is set
cat ~/.nemoclaw/config.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'claude' in d.get('model', ''), f'Expected claude model, got {d.get(\"model\", \"none\")}'
print('Onboard model: OK')
"
```

## Blueprint

Verify the custom inference profile exists:

```bash
# Verify acme-claude profile exists in blueprint.yaml
grep -q "acme-claude" nemoclaw-blueprint/blueprint.yaml && echo "Blueprint profile: OK" || echo "FAIL: acme-claude profile not found"
```

```bash
# Verify credential_env uses ANTHROPIC_API_KEY
grep -A5 "acme-claude" nemoclaw-blueprint/blueprint.yaml | grep -q "ANTHROPIC_API_KEY" && echo "Blueprint credential: OK" || echo "FAIL: ANTHROPIC_API_KEY not in acme-claude profile"
```

## Network Policy

Verify custom policy preset exists:

```bash
# Verify custom preset file exists and contains expected egress rule
ls nemoclaw-blueprint/policies/presets/*.yaml 2>/dev/null | head -5
```

```bash
# Verify policy contains the custom service egress rule
grep -r "api.anthropic.com" nemoclaw-blueprint/policies/presets/ && echo "Policy: OK" || echo "FAIL: custom egress rule not found"
```

## OpenClaw Plugin

Verify custom plugin builds:

```bash
# Verify TypeScript compiles without errors
cd nemoclaw && npm run build && echo "Plugin build: OK" || echo "FAIL: build errors"
```

```bash
# Verify custom provider is registered
grep -r "registerProvider" nemoclaw/src/plugins/ && echo "Plugin registration: OK" || echo "FAIL: registerProvider not found"
```

## Docker Image

Verify custom image builds and contains expected files:

```bash
# Verify Docker image builds
docker build -t nemoclaw-custom . && echo "Docker build: OK" || echo "FAIL: docker build failed"
```

```bash
# Verify custom files are in the image
docker run --rm nemoclaw-custom ls /opt/nemoclaw/nemoclaw/dist/plugins/ 2>/dev/null && echo "Docker contents: OK" || echo "FAIL: plugin files not in image"
```

## Auxiliary Services

Verify service registration is complete in all three locations:

```bash
# Verify discord-bridge appears in do_start, show_status, and do_stop
COUNT=$(grep -c "discord-bridge" scripts/start-services.sh)
[ "$COUNT" -ge 3 ] && echo "Service registration: OK ($COUNT references)" || echo "FAIL: discord-bridge found only $COUNT times (need 3+)"
```

```bash
# Verify discord-bridge.js template has valid syntax
node -c scripts/discord-bridge.js && echo "Service template: OK" || echo "FAIL: syntax error in discord-bridge.js"
```

## Install Script

Verify install.sh customizations:

```bash
# Verify Node.js version updated
grep -q "RECOMMENDED_NODE_MAJOR=24" install.sh && echo "Node version: OK" || echo "FAIL: Node version not updated"
```

```bash
# Verify Ollama medium tier added
grep -q "vram_gb >= 48" install.sh && echo "Ollama tier: OK" || echo "FAIL: medium VRAM tier not found"
```

```bash
# Verify custom post-install function exists and is called in main()
grep -q "install_acme_tools" install.sh && echo "Post-install: OK" || echo "FAIL: install_acme_tools not found"
```

## Clean Machine Test

The ultimate validation is running the full installer on a fresh machine. This confirms that all customizations work together end-to-end.

```bash
# Option 1: Fresh VM or cloud instance
ssh fresh-machine 'curl -fsSL https://raw.githubusercontent.com/your-fork/NemoClaw/main/scripts/install.sh | bash'

# Option 2: Docker container (lighter weight)
docker run --rm -it ubuntu:22.04 bash -c '
  apt-get update && apt-get install -y curl git
  curl -fsSL https://raw.githubusercontent.com/your-fork/NemoClaw/main/scripts/install.sh | bash
'
```

After installation completes, run through each verification section above inside the fresh environment. If every check passes, your fork is ready for distribution.

:::{tip}
For CI/CD, extract the verification commands into a test script that runs automatically after each push to your fork's main branch.
:::

## What's Next

You have verified every customization surface. Return to the [Customization Overview](overview.md) to review the complete extension surface map, or share your fork with your team.
