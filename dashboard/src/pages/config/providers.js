import { useState } from "react";
import Layout from "../../components/Layout";
import StatusBadge from "../../components/StatusBadge";

const initialProviders = [
  {
    id: "openrouter",
    name: "OpenRouter",
    type: "openai",
    endpoint: "https://openrouter.ai/api/v1",
    model: "anthropic/claude-sonnet-4",
    credentialEnv: "OPENROUTER_API_KEY",
    status: "online",
    enabled: true,
  },
  {
    id: "nvidia-nim",
    name: "NVIDIA NIM",
    type: "nvidia",
    endpoint: "https://integrate.api.nvidia.com/v1",
    model: "nvidia/nemotron-3-super-120b-a12b",
    credentialEnv: "NVIDIA_API_KEY",
    status: "online",
    enabled: true,
  },
  {
    id: "ollama-local",
    name: "Ollama (Local)",
    type: "openai",
    endpoint: "http://localhost:11434/v1",
    model: "",
    credentialEnv: "",
    status: "stopped",
    enabled: false,
  },
];

export default function Providers() {
  const [providers, setProviders] = useState(initialProviders);
  const [editing, setEditing] = useState(null);

  function toggleProvider(id) {
    setProviders((prev) =>
      prev.map((p) => (p.id === id ? { ...p, enabled: !p.enabled } : p))
    );
  }

  return (
    <Layout>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "24px" }}>
        <h1 style={{ fontSize: "20px", fontWeight: 700 }}>Inference Providers</h1>
        <button className="btn btn-primary">Add Provider</button>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
        {providers.map((provider) => (
          <div key={provider.id} className="card">
            <div className="card-header">
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <span className="card-title">{provider.name}</span>
                <StatusBadge status={provider.status} />
              </div>
              <div style={{ display: "flex", gap: "8px" }}>
                <button className="btn" onClick={() => setEditing(editing === provider.id ? null : provider.id)}>
                  {editing === provider.id ? "Close" : "Edit"}
                </button>
                <button className="btn" onClick={() => toggleProvider(provider.id)}>
                  {provider.enabled ? "Disable" : "Enable"}
                </button>
              </div>
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "12px", fontSize: "13px" }}>
              <div>
                <span style={{ color: "var(--text-muted)", fontSize: "11px" }}>Endpoint</span>
                <div style={{ fontFamily: "var(--font-mono)", fontSize: "12px", marginTop: "4px" }}>{provider.endpoint}</div>
              </div>
              <div>
                <span style={{ color: "var(--text-muted)", fontSize: "11px" }}>Active Model</span>
                <div style={{ marginTop: "4px" }}>{provider.model || "—"}</div>
              </div>
              <div>
                <span style={{ color: "var(--text-muted)", fontSize: "11px" }}>Credential</span>
                <div style={{ fontFamily: "var(--font-mono)", fontSize: "12px", marginTop: "4px" }}>{provider.credentialEnv || "—"}</div>
              </div>
            </div>

            {editing === provider.id && (
              <div style={{ marginTop: "16px", paddingTop: "16px", borderTop: "1px solid var(--border)" }}>
                <div className="grid-2">
                  <div className="form-group">
                    <label className="form-label">Endpoint URL</label>
                    <input className="form-input" defaultValue={provider.endpoint} />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Model</label>
                    <input className="form-input" defaultValue={provider.model} />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Provider Type</label>
                    <select className="form-select" defaultValue={provider.type}>
                      <option value="openai">OpenAI-Compatible</option>
                      <option value="nvidia">NVIDIA</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label className="form-label">API Key Env Variable</label>
                    <input className="form-input" defaultValue={provider.credentialEnv} />
                  </div>
                </div>
                <div style={{ display: "flex", gap: "8px", marginTop: "8px" }}>
                  <button className="btn btn-primary">Save Changes</button>
                  <button className="btn">Test Connection</button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </Layout>
  );
}
