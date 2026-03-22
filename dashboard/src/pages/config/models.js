import Layout from "../../components/Layout";
import StatusBadge from "../../components/StatusBadge";

const models = [
  { id: "anthropic/claude-sonnet-4", provider: "OpenRouter", label: "Claude Sonnet 4", context: "200K", active: true },
  { id: "anthropic/claude-haiku-4", provider: "OpenRouter", label: "Claude Haiku 4", context: "200K", active: false },
  { id: "openai/gpt-4.1", provider: "OpenRouter", label: "GPT-4.1", context: "1M", active: false },
  { id: "openai/gpt-4.1-mini", provider: "OpenRouter", label: "GPT-4.1 Mini", context: "1M", active: false },
  { id: "google/gemini-2.5-pro", provider: "OpenRouter", label: "Gemini 2.5 Pro", context: "1M", active: false },
  { id: "google/gemini-2.5-flash", provider: "OpenRouter", label: "Gemini 2.5 Flash", context: "1M", active: false },
  { id: "meta-llama/llama-4-maverick", provider: "OpenRouter", label: "Llama 4 Maverick", context: "1M", active: false },
  { id: "meta-llama/llama-4-scout", provider: "OpenRouter", label: "Llama 4 Scout", context: "512K", active: false },
  { id: "deepseek/deepseek-r1", provider: "OpenRouter", label: "DeepSeek R1", context: "164K", active: false },
  { id: "mistralai/mistral-large", provider: "OpenRouter", label: "Mistral Large", context: "128K", active: false },
  { id: "qwen/qwen3-235b-a22b", provider: "OpenRouter", label: "Qwen3 235B", context: "128K", active: false },
  { id: "nvidia/nemotron-3-super-120b-a12b", provider: "NVIDIA NIM", label: "Nemotron 3 Super 120B", context: "128K", active: true },
];

export default function Models() {
  return (
    <Layout>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "24px" }}>
        <h1 style={{ fontSize: "20px", fontWeight: 700 }}>Available Models</h1>
        <div style={{ display: "flex", gap: "8px" }}>
          <button className="btn">Refresh</button>
        </div>
      </div>

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>Model</th>
              <th>Provider</th>
              <th>Model ID</th>
              <th>Context</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {models.map((model) => (
              <tr key={model.id}>
                <td style={{ fontWeight: 500 }}>{model.label}</td>
                <td>{model.provider}</td>
                <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>{model.id}</td>
                <td style={{ fontFamily: "var(--font-mono)" }}>{model.context}</td>
                <td>
                  {model.active ? (
                    <StatusBadge status="online" label="Active" />
                  ) : (
                    <StatusBadge status="info" label="Available" />
                  )}
                </td>
                <td>
                  <button className="btn" style={{ padding: "4px 12px", fontSize: "12px" }}>
                    {model.active ? "Deactivate" : "Activate"}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
