import Layout from "../../components/Layout";
import StatusBadge from "../../components/StatusBadge";

const policies = [
  { name: "openrouter_api", host: "openrouter.ai", port: 443, protocol: "rest", status: "active" },
  { name: "nvidia_api", host: "integrate.api.nvidia.com", port: 443, protocol: "rest", status: "active" },
  { name: "nim_service", host: "nim-service.local", port: 8000, protocol: "rest", status: "inactive" },
  { name: "openclaw_gateway", host: "localhost", port: 18789, protocol: "rest", status: "active" },
  { name: "ollama_local", host: "localhost", port: 11434, protocol: "rest", status: "inactive" },
];

const presets = [
  { name: "Discord", file: "discord.yaml" },
  { name: "Docker", file: "docker.yaml" },
  { name: "HuggingFace", file: "huggingface.yaml" },
  { name: "Jira", file: "jira.yaml" },
  { name: "npm", file: "npm.yaml" },
  { name: "Outlook", file: "outlook.yaml" },
  { name: "PyPI", file: "pypi.yaml" },
  { name: "Slack", file: "slack.yaml" },
  { name: "Telegram", file: "telegram.yaml" },
];

export default function NetworkPolicy() {
  return (
    <Layout>
      <h1 style={{ fontSize: "20px", fontWeight: 700, marginBottom: "24px" }}>
        Network Policy
      </h1>

      <div className="card" style={{ marginBottom: "24px" }}>
        <div className="card-header">
          <span className="card-title">Active Rules</span>
          <button className="btn btn-primary">Add Rule</button>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Host</th>
              <th>Port</th>
              <th>Protocol</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {policies.map((policy) => (
              <tr key={policy.name}>
                <td style={{ fontWeight: 500 }}>{policy.name}</td>
                <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>{policy.host}</td>
                <td style={{ fontFamily: "var(--font-mono)" }}>{policy.port}</td>
                <td>{policy.protocol}</td>
                <td>
                  <StatusBadge
                    status={policy.status === "active" ? "online" : "stopped"}
                    label={policy.status}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">Policy Presets</span>
          <span className="card-subtitle">Enable pre-configured policies for common services</span>
        </div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: "8px", marginTop: "12px" }}>
          {presets.map((preset) => (
            <button key={preset.name} className="btn">
              {preset.name}
            </button>
          ))}
        </div>
      </div>
    </Layout>
  );
}
