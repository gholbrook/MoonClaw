import Layout from "../../components/Layout";
import MetricCard from "../../components/MetricCard";
import StatusBadge from "../../components/StatusBadge";

export default function InferenceMonitoring() {
  return (
    <Layout>
      <h1 style={{ fontSize: "20px", fontWeight: 700, marginBottom: "24px" }}>
        Inference Health
      </h1>

      <div className="grid-3" style={{ marginBottom: "24px" }}>
        <MetricCard label="Total Requests" value="1,247" change="+18% today" changeDir="up" />
        <MetricCard label="Avg Response Time" value="142" unit="ms" change="-12ms" changeDir="up" />
        <MetricCard label="Error Rate" value="0.3" unit="%" change="-0.1%" changeDir="up" />
      </div>

      <div className="card" style={{ marginBottom: "24px" }}>
        <div className="card-header">
          <span className="card-title">Provider Status</span>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Provider</th>
              <th>Endpoint</th>
              <th>Active Model</th>
              <th>Latency (p50)</th>
              <th>Latency (p99)</th>
              <th>Requests/hr</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td style={{ fontWeight: 500 }}>OpenRouter</td>
              <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>openrouter.ai/api/v1</td>
              <td>claude-sonnet-4</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>128ms</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>340ms</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>87</td>
              <td><StatusBadge status="online" label="Healthy" /></td>
            </tr>
            <tr>
              <td style={{ fontWeight: 500 }}>NVIDIA NIM</td>
              <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>integrate.api.nvidia.com/v1</td>
              <td>nemotron-3-super-120b</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>95ms</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>210ms</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>42</td>
              <td><StatusBadge status="online" label="Healthy" /></td>
            </tr>
            <tr>
              <td style={{ fontWeight: 500 }}>Ollama (local)</td>
              <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>localhost:11434</td>
              <td>&mdash;</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>&mdash;</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>&mdash;</td>
              <td style={{ fontFamily: "var(--font-mono)" }}>0</td>
              <td><StatusBadge status="stopped" label="Stopped" /></td>
            </tr>
          </tbody>
        </table>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">Request Distribution (Last Hour)</span>
        </div>
        <div style={{ display: "flex", gap: "16px", marginTop: "12px" }}>
          <div style={{ flex: 1 }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
              <span style={{ fontSize: "12px" }}>OpenRouter</span>
              <span style={{ fontSize: "12px", fontFamily: "var(--font-mono)" }}>67%</span>
            </div>
            <div style={{ height: "8px", background: "var(--bg-primary)", borderRadius: "4px", overflow: "hidden" }}>
              <div style={{ width: "67%", height: "100%", background: "var(--accent)", borderRadius: "4px" }} />
            </div>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
              <span style={{ fontSize: "12px" }}>NVIDIA NIM</span>
              <span style={{ fontSize: "12px", fontFamily: "var(--font-mono)" }}>33%</span>
            </div>
            <div style={{ height: "8px", background: "var(--bg-primary)", borderRadius: "4px", overflow: "hidden" }}>
              <div style={{ width: "33%", height: "100%", background: "var(--success)", borderRadius: "4px" }} />
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
