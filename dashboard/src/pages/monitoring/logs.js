import { useState } from "react";
import Layout from "../../components/Layout";
import LogViewer from "../../components/LogViewer";

const sampleLogs = [
  { time: "14:32:01", level: "info", message: "Inference request completed — provider=openrouter model=claude-sonnet-4 latency=128ms" },
  { time: "14:31:45", level: "info", message: "Model switched to anthropic/claude-sonnet-4 on openrouter provider" },
  { time: "14:31:30", level: "info", message: "Health check passed — openrouter endpoint=https://openrouter.ai/api/v1 status=200" },
  { time: "14:30:12", level: "info", message: "Health check passed — nvidia-nim endpoint=https://integrate.api.nvidia.com/v1 status=200" },
  { time: "14:28:33", level: "info", message: "Plugin loaded: lossless-claw v1.0.0" },
  { time: "14:28:30", level: "info", message: "Plugin loaded: nemoclaw v0.1.0" },
  { time: "14:28:15", level: "info", message: "Sandbox 'openclaw' started on port 18789" },
  { time: "14:28:10", level: "info", message: "Blueprint v0.1.0 verified — digest matches" },
  { time: "14:28:05", level: "info", message: "Gateway started — listening on :18789" },
  { time: "14:28:00", level: "info", message: "MoonClaw dashboard started on http://localhost:3200" },
  { time: "14:27:55", level: "warn", message: "Ollama not detected — local inference unavailable" },
  { time: "14:27:50", level: "info", message: "OpenRouter provider configured — key=sk-or-...redacted" },
  { time: "14:27:45", level: "info", message: "Shared drive mounted at C:\\Users\\user\\Desktop\\MoonClaw Shared" },
];

export default function Logs() {
  const [filter, setFilter] = useState("all");

  const filteredLogs = filter === "all"
    ? sampleLogs
    : sampleLogs.filter((l) => l.level === filter);

  return (
    <Layout>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "24px" }}>
        <h1 style={{ fontSize: "20px", fontWeight: 700 }}>Live Logs</h1>
        <div style={{ display: "flex", gap: "8px" }}>
          {["all", "info", "warn", "error"].map((level) => (
            <button
              key={level}
              className={`btn ${filter === level ? "btn-primary" : ""}`}
              onClick={() => setFilter(level)}
            >
              {level.toUpperCase()}
            </button>
          ))}
        </div>
      </div>

      <LogViewer logs={filteredLogs} />
    </Layout>
  );
}
