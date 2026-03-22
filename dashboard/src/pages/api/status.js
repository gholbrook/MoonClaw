import { exec } from "child_process";
import { promisify } from "util";
import fs from "fs";
import path from "path";

const execAsync = promisify(exec);

async function getSandboxStatus() {
  try {
    const { stdout } = await execAsync("nemoclaw status --json", { timeout: 10000 });
    return JSON.parse(stdout);
  } catch {
    return { status: "unknown", error: "Could not reach nemoclaw" };
  }
}

async function getDockerStatus() {
  try {
    const { stdout } = await execAsync('docker ps --filter "name=openclaw" --format "{{json .}}"', { timeout: 10000 });
    if (!stdout.trim()) return { running: false };
    const container = JSON.parse(stdout.trim());
    return { running: true, ...container };
  } catch {
    return { running: false, error: "Docker not available" };
  }
}

function getNemoClawConfig() {
  const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".nemoclaw", "config.json");
  try {
    return JSON.parse(fs.readFileSync(configPath, "utf-8"));
  } catch {
    return null;
  }
}

function getShareConfig() {
  const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".nemoclaw", "shared-drive.json");
  try {
    return JSON.parse(fs.readFileSync(configPath, "utf-8"));
  } catch {
    return null;
  }
}

export default async function handler(req, res) {
  const [sandbox, docker] = await Promise.all([
    getSandboxStatus(),
    getDockerStatus(),
  ]);

  const config = getNemoClawConfig();
  const share = getShareConfig();

  res.status(200).json({
    sandbox,
    docker,
    config,
    share,
    timestamp: new Date().toISOString(),
  });
}
