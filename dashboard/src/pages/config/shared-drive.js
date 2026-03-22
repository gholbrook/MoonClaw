import Layout from "../../components/Layout";
import MetricCard from "../../components/MetricCard";
import StatusBadge from "../../components/StatusBadge";

export default function SharedDrive() {
  return (
    <Layout>
      <h1 style={{ fontSize: "20px", fontWeight: 700, marginBottom: "24px" }}>
        Shared Drive
      </h1>

      <div className="grid-3" style={{ marginBottom: "24px" }}>
        <MetricCard label="Total Size" value="2.4" unit="GB" />
        <MetricCard label="Files" value="156" />
        <MetricCard label="Network Clients" value="1" />
      </div>

      <div className="grid-2" style={{ marginBottom: "24px" }}>
        <div className="card">
          <div className="card-header">
            <span className="card-title">Share Details</span>
            <StatusBadge status="online" label="Shared" />
          </div>
          <table className="table">
            <tbody>
              <tr>
                <td>Local Path</td>
                <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>
                  C:\Users\user\Desktop\MoonClaw Shared
                </td>
              </tr>
              <tr>
                <td>Network Path</td>
                <td style={{ fontFamily: "var(--font-mono)", fontSize: "12px" }}>
                  \\DESKTOP\MoonClaw
                </td>
              </tr>
              <tr>
                <td>SMB Sharing</td>
                <td><StatusBadge status="online" label="Enabled" /></td>
              </tr>
              <tr>
                <td>Access</td>
                <td>Full Control (Owner)</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">Directories</span>
          </div>
          <table className="table">
            <thead>
              <tr><th>Folder</th><th>Size</th><th>Files</th></tr>
            </thead>
            <tbody>
              <tr><td>models/</td><td style={{ fontFamily: "var(--font-mono)" }}>1.8 GB</td><td>12</td></tr>
              <tr><td>data/</td><td style={{ fontFamily: "var(--font-mono)" }}>420 MB</td><td>45</td></tr>
              <tr><td>logs/</td><td style={{ fontFamily: "var(--font-mono)" }}>89 MB</td><td>78</td></tr>
              <tr><td>config/</td><td style={{ fontFamily: "var(--font-mono)" }}>12 KB</td><td>8</td></tr>
              <tr><td>exports/</td><td style={{ fontFamily: "var(--font-mono)" }}>112 MB</td><td>13</td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">Actions</span>
        </div>
        <div style={{ display: "flex", gap: "12px", marginTop: "8px" }}>
          <button className="btn btn-primary">Open Folder</button>
          <button className="btn">Refresh Stats</button>
          <button className="btn">Manage Permissions</button>
        </div>
      </div>
    </Layout>
  );
}
