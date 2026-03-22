export default function MetricCard({ label, value, change, changeDir, unit }) {
  return (
    <div className="card">
      <div className="metric">
        <span className="metric-label">{label}</span>
        <span className="metric-value">
          {value}
          {unit && <span style={{ fontSize: "14px", marginLeft: "4px", color: "var(--text-secondary)" }}>{unit}</span>}
        </span>
        {change && (
          <span className={`metric-change ${changeDir || ""}`}>{change}</span>
        )}
      </div>
    </div>
  );
}
