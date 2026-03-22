export default function StatusBadge({ status, label }) {
  const variants = {
    online: "badge-success",
    healthy: "badge-success",
    running: "badge-success",
    warning: "badge-warning",
    degraded: "badge-warning",
    offline: "badge-error",
    error: "badge-error",
    stopped: "badge-error",
    info: "badge-info",
  };

  const dotVariants = {
    online: "online",
    healthy: "online",
    running: "online",
    warning: "warning",
    degraded: "warning",
    offline: "offline",
    error: "offline",
    stopped: "offline",
    info: "online",
  };

  return (
    <span className={`badge ${variants[status] || "badge-info"}`}>
      <span className={`status-dot ${dotVariants[status] || ""}`} />
      {label || status}
    </span>
  );
}
