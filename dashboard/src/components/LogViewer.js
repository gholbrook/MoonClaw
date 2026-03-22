import { useState, useEffect, useRef } from "react";

export default function LogViewer({ logs = [], maxLines = 200 }) {
  const containerRef = useRef(null);
  const [autoScroll, setAutoScroll] = useState(true);

  useEffect(() => {
    if (autoScroll && containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight;
    }
  }, [logs, autoScroll]);

  function handleScroll() {
    const el = containerRef.current;
    if (!el) return;
    const atBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 40;
    setAutoScroll(atBottom);
  }

  const displayLogs = logs.slice(-maxLines);

  return (
    <div className="log-viewer" ref={containerRef} onScroll={handleScroll}>
      {displayLogs.length === 0 && (
        <div style={{ color: "var(--text-muted)" }}>No logs yet...</div>
      )}
      {displayLogs.map((log, i) => (
        <div key={i} className="log-line">
          <span className="log-time">{log.time}</span>
          <span className={`log-level-${log.level || "info"}`}>
            [{(log.level || "info").toUpperCase().padEnd(5)}]
          </span>
          <span>{log.message}</span>
        </div>
      ))}
    </div>
  );
}
