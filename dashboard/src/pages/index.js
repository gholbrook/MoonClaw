import Layout from "../components/Layout";
import MetricCard from "../components/MetricCard";
import StatusBadge from "../components/StatusBadge";

export default function Dashboard() {
  return (
    <Layout>
      <h1 style={{ fontSize: "20px", fontWeight: 700, marginBottom: "24px" }}>
        Dashboard
      </h1>

      {/* Metrics row */}
      <div className="grid-4" style={{ marginBottom: "24px" }}>
        <MetricCard label="Sandbox Uptime" value="99.8" unit="%" change="+0.1% vs yesterday" changeDir="up" />
        <MetricCard label="Requests Today" value="1,247" change="+18% vs avg" changeDir="up" />
        <MetricCard label="Avg Latency" value="142" unit="ms" change="-12ms vs avg" changeDir="up" />
        <MetricCard label="Active Models" value="3" />
      </div>

      {/* Status cards */}
      <div className="grid-2" style={{ marginBottom: "24px" }}>
        <div className="card">
          <div className="card-header">
            <span className="card-title">Sandbox Status</span>
            <StatusBadge status="running" label="Running" />
          </div>
          <table className="table">
            <tbody>
              <tr>
                <td>Container</td>
                <td>openclaw</td>
                <td><StatusBadge status="online" label="Healthy" /></td>
              </tr>
              <tr>
                <td>Gateway</td>
                <td>:18789</td>
                <td><StatusBadge status="online" label="Listening" /></td>
              </tr>
              <tr>
                <td>Blueprint</td>
                <td>v0.1.0</td>
                <td><StatusBadge status="info" label="Latest" /></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">Inference Providers</span>
            <StatusBadge status="online" label="All Healthy" />
          </div>
          <table className="table">
            <tbody>
              <tr>
                <td>OpenRouter</td>
                <td>claude-sonnet-4</td>
                <td><StatusBadge status="online" label="Connected" /></td>
              </tr>
              <tr>
                <td>NVIDIA NIM</td>
                <td>nemotron-3-super</td>
                <td><StatusBadge status="online" label="Connected" /></td>
              </tr>
              <tr>
                <td>Ollama (local)</td>
                <td>&mdash;</td>
                <td><StatusBadge status="stopped" label="Stopped" /></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* Recent activity */}
      <div className="card">
        <div className="card-header">
          <span className="card-title">Recent Activity</span>
          <button className="btn">View All</button>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Event</th>
              <th>Provider</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>14:32:01</td>
              <td>Inference request</td>
              <td>OpenRouter</td>
              <td><StatusBadge status="online" label="200 OK" /></td>
            </tr>
            <tr>
              <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>14:31:45</td>
              <td>Model switch</td>
              <td>OpenRouter</td>
              <td><StatusBadge status="info" label="claude-sonnet-4" /></td>
            </tr>
            <tr>
              <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>14:30:12</td>
              <td>Health check</td>
              <td>NVIDIA NIM</td>
              <td><StatusBadge status="online" label="Healthy" /></td>
            </tr>
            <tr>
              <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>14:28:33</td>
              <td>Plugin loaded</td>
              <td>&mdash;</td>
              <td><StatusBadge status="info" label="lossless-claw" /></td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
