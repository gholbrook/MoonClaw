import fs from "fs";
import path from "path";

function getProviderConfig() {
  const configDir = path.join(process.env.USERPROFILE || process.env.HOME, ".nemoclaw");

  const providers = [];

  // Read OpenRouter provider
  const openrouterPath = path.join(configDir, "openrouter-provider.json");
  if (fs.existsSync(openrouterPath)) {
    const config = JSON.parse(fs.readFileSync(openrouterPath, "utf-8"));
    providers.push({
      ...config,
      id: "openrouter",
      hasKey: !!process.env.OPENROUTER_API_KEY,
    });
  }

  // Read OpenRouter profile YAML for model list
  const profilePath = path.join(configDir, "openrouter-profile.yaml");
  let models = [];
  if (fs.existsSync(profilePath)) {
    const content = fs.readFileSync(profilePath, "utf-8");
    // Simple YAML model extraction
    const modelMatches = content.match(/- id: "([^"]+)"\s*\n\s*label: "([^"]+)"/g);
    if (modelMatches) {
      models = modelMatches.map((m) => {
        const idMatch = m.match(/id: "([^"]+)"/);
        const labelMatch = m.match(/label: "([^"]+)"/);
        return { id: idMatch?.[1], label: labelMatch?.[1] };
      });
    }
  }

  return { providers, models };
}

async function testProviderHealth(endpoint, apiKey) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const res = await fetch(`${endpoint}/models`, {
      headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {},
      signal: controller.signal,
    });
    clearTimeout(timeout);
    return { healthy: res.ok, status: res.status };
  } catch {
    return { healthy: false, error: "unreachable" };
  }
}

export default async function handler(req, res) {
  if (req.method === "GET") {
    const config = getProviderConfig();
    res.status(200).json(config);
  } else {
    res.status(405).json({ error: "Method not allowed" });
  }
}
