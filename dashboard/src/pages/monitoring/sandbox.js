import Layout from "../../components/Layout";
import MetricCard from "../../components/MetricCard";
import StatusBadge from "../../components/StatusBadge";

export default function SandboxMonitoring() {
  return (
    <Layout>
      <h1 style={{ fontSize: "20px", fontWeight: 700, marginBottom: "24px" }}>
        Sandbox Status
      </h1>

      <div className="grid-4" style={{ marginBottom: "24px" }}>
        <MetricCard label="CPU Usage" value="23" unit="%" />
        <MetricCard label="Memory" value="512" unit="MB" />
        <MetricCard label="Uptime" value="4h 32m" />
        <MetricCard label="Restarts" value="0" />
      </div>

      <div className="grid-2" style={{ marginBottom: "24px" }}>
        <div className="card">
          <div className="card-header">
            <span className="card-title">Container Details</span>
            <StatusBadge status="running" label="Running" />
          </div>
          <table className="table">
            <tbody>
              <tr><td>Container ID</td><td style={{ fontFamily: "var(--font-mono)" }}>abc123def456</td></tr>
              <tr><td>Image</td><td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest</td></tr>
              <tr><td>Sandbox Name</td><td>openclaw</td></tr>
              <tr><td>Gateway Port</td><td>18789</td></tr>
              <tr><td>Blueprint</td><td>v0.1.0</td></tr>
              <tr><td>Started</td><td>2026-03-21 10:00:12</td></tr>
            </tbody>
          </table>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">Plugins</span>
          </div>
          <table className="table">
            <thead>
              <tr><th>Plugin</th><th>Version</th><th>Status</th></tr>
            </thead>
            <tbody>
              <tr>
                <td>lossless-claw</td>
                <td>1.0.0</td>
                <td><StatusBadge status="online" label="Active" /></td>
              </tr>
              <tr>
                <td>nemoclaw</td>
                <td>0.1.0</td>
                <td><StatusBadge status="online" label="Active" /></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">Actions</span>
        </div>
        <div style={{ display: "flex", gap: "12px", marginTop: "8px" }}>
          <button className="btn btn-primary">Restart Sandbox</button>
          <button className="btn">Stop Sandbox</button>
          <button className="btn">View Logs</button>
          <button className="btn">Run Migration</button>
        </div>
      </div>
    </Layout>
  );
}
