import Layout from "../components/Layout";

function DonutChart({ segments, size = 160, thickness = 24 }) {
  const radius = (size - thickness) / 2;
  const circumference = 2 * Math.PI * radius;
  let offset = 0;

  return (
    <div className="donut-chart" style={{ width: size, height: size }}>
      <svg width={size} height={size}>
        {/* Background ring */}
        <circle
          cx={size / 2} cy={size / 2} r={radius}
          fill="none" stroke="#EEEAE5" strokeWidth={thickness}
        />
        {segments.map((seg, i) => {
          const dashLength = (seg.value / 100) * circumference;
          const dashOffset = -offset;
          offset += dashLength;
          return (
            <circle
              key={i}
              cx={size / 2} cy={size / 2} r={radius}
              fill="none"
              stroke={seg.color}
              strokeWidth={thickness}
              strokeDasharray={`${dashLength} ${circumference - dashLength}`}
              strokeDashoffset={dashOffset}
              strokeLinecap="round"
            />
          );
        })}
      </svg>
    </div>
  );
}

export default function Dashboard() {
  return (
    <Layout>
      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-row">
          <div>
            <p className="page-subtitle">Monitor and manage your sandbox</p>
            <h1 className="page-title">MoonClaw Dashboard</h1>
          </div>
          <div className="search-box">
            <span className="search-icon">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5">
                <circle cx="7" cy="7" r="5" />
                <path d="M11 11l3 3" />
              </svg>
            </span>
            <input type="text" placeholder="Search services, models, logs..." />
          </div>
        </div>
      </div>

      {/* Dashboard Grid - 4 columns like the reference */}
      <div className="dashboard-grid">

        {/* Column 1: Services (like "My Tasks") */}
        <div className="card" style={{ gridRow: "1 / 3" }}>
          <div className="card-header">
            <span className="card-title">Services</span>
            <button className="card-action" title="Add service">+</button>
          </div>

          <div className="pill-tabs">
            <button className="pill-tab active">Running</button>
            <button className="pill-tab">All</button>
          </div>

          <div className="item-count" style={{ marginBottom: 16 }}>
            <span className="item-count-num">4</span>
            Active Services
            <span style={{ marginLeft: "auto", cursor: "pointer" }}>&#x25BE;</span>
          </div>

          <div className="service-item">
            <div className="service-icon green">&#x2588;</div>
            <div className="service-info">
              <div className="service-name">OpenShell Gateway</div>
              <div className="service-desc">Sandbox orchestration on :8080</div>
            </div>
            <div className="service-check ok">&#x2713;</div>
          </div>

          <div className="service-item">
            <div className="service-icon blue">&#x2588;</div>
            <div className="service-info">
              <div className="service-name">OpenClaw Sandbox</div>
              <div className="service-desc">Container runtime with agent tools</div>
            </div>
            <div className="service-check ok">&#x2713;</div>
          </div>

          <div className="service-item">
            <div className="service-icon purple">&#x2588;</div>
            <div className="service-info">
              <div className="service-name">OpenRouter Provider</div>
              <div className="service-desc">Claude Sonnet 4 via openrouter.ai</div>
            </div>
            <div className="service-check ok">&#x2713;</div>
          </div>

          <div className="service-item">
            <div className="service-icon orange">&#x2588;</div>
            <div className="service-info">
              <div className="service-name">NVIDIA NIM</div>
              <div className="service-desc">Nemotron 3 Super 120B endpoint</div>
            </div>
            <div className="service-check ok">&#x2713;</div>
          </div>

          <div className="service-item">
            <div className="service-icon red">&#x2588;</div>
            <div className="service-info">
              <div className="service-name">Ollama (Local)</div>
              <div className="service-desc">Not running on localhost:11434</div>
            </div>
            <div className="service-check err">&#x2717;</div>
          </div>
        </div>

        {/* Column 2: Inference Overview (like "Projects Overview") */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">Inference Overview</span>
            <button className="card-action" title="Expand">&#x2197;</button>
          </div>

          <DonutChart
            segments={[
              { value: 55, color: "#4A90D9" },
              { value: 35, color: "#7C5CFC" },
              { value: 10, color: "#EEEAE5" },
            ]}
          />

          <div className="donut-legend">
            <div className="donut-legend-item">
              <span className="donut-legend-dot" style={{ background: "#F4A261" }} />
              Pending: 2
            </div>
            <div className="donut-legend-item">
              <span className="donut-legend-dot" style={{ background: "#4A90D9" }} />
              Completed: 847
            </div>
          </div>
          <div className="donut-legend" style={{ marginTop: 4 }}>
            <div className="donut-legend-item" style={{ color: "var(--text-muted)" }}>
              Failed: 3
            </div>
          </div>
        </div>

        {/* Column 3: Resource Usage (like "Income vs Expense") */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">Resource Usage</span>
            <div style={{ display: "flex", gap: 4 }}>
              <button className="card-action" title="Settings">&#x2699;</button>
              <button className="card-action" title="Expand">&#x2197;</button>
            </div>
          </div>

          <div style={{ display: "flex", gap: 24, marginBottom: 16 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13 }}>
              <span style={{ width: 8, height: 8, borderRadius: "50%", background: "#4A90D9" }} />
              CPU: 23%
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13 }}>
              <span style={{ width: 8, height: 8, borderRadius: "50%", background: "#F4A261" }} />
              Memory: 512MB
            </div>
          </div>

          {/* Simplified chart area */}
          <div style={{
            height: 120,
            background: "linear-gradient(180deg, rgba(74,144,217,0.06) 0%, transparent 100%)",
            borderRadius: 8,
            display: "flex",
            alignItems: "flex-end",
            padding: "0 8px",
            gap: 2,
          }}>
            {[35, 42, 28, 55, 48, 23, 38, 31, 45, 22, 33, 28, 40, 35, 23].map((h, i) => (
              <div
                key={i}
                style={{
                  flex: 1,
                  height: `${h}%`,
                  background: i === 14 ? "#4A90D9" : "rgba(74,144,217,0.2)",
                  borderRadius: "4px 4px 0 0",
                }}
              />
            ))}
          </div>
        </div>

        {/* Column 4 Top: Quick Status (like "My Meetings") */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">Quick Status</span>
            <button className="card-action" title="Details">&#x2630;</button>
          </div>

          <div className="event-card">
            <div className="event-left">
              <span className="event-meta">Gateway</span>
              <span className="event-title">nemoclaw</span>
              <div className="event-detail">
                <span className="status-dot online" />
                Healthy &bull; :8080
              </div>
            </div>
            <button className="event-action">&#x2197;</button>
          </div>

          <div className="event-card">
            <div className="event-left">
              <span className="event-meta">Sandbox</span>
              <span className="event-title">my-assistant</span>
              <div className="event-detail">
                <span className="status-dot online" />
                Running &bull; :18789
              </div>
            </div>
            <button className="event-action">&#x2197;</button>
          </div>

          <a className="see-all" href="/monitoring/sandbox">
            See All Details &rsaquo;
          </a>
        </div>

        {/* Column 2-3 Bottom: Provider Health (like "Invoice Overview") */}
        <div className="card span-2">
          <div className="card-header">
            <span className="card-title">Provider Health</span>
            <button className="card-action" title="Settings">&#x2699;</button>
          </div>

          <div className="progress-row">
            <div className="progress-header">
              <span className="progress-label">OpenRouter</span>
              <span className="progress-value">847 req &nbsp;|&nbsp; p50: 128ms</span>
            </div>
            <div className="progress-bar">
              <div className="progress-fill blue" style={{ width: "92%" }} />
            </div>
          </div>

          <div className="progress-row">
            <div className="progress-header">
              <span className="progress-label">NVIDIA NIM</span>
              <span className="progress-value">342 req &nbsp;|&nbsp; p50: 95ms</span>
            </div>
            <div className="progress-bar">
              <div className="progress-fill purple" style={{ width: "88%" }} />
            </div>
          </div>

          <div className="progress-row">
            <div className="progress-header">
              <span className="progress-label">Ollama (Local)</span>
              <span className="progress-value">Stopped</span>
            </div>
            <div className="progress-bar">
              <div className="progress-fill orange" style={{ width: "0%" }} />
            </div>
          </div>

          <div className="progress-row">
            <div className="progress-header">
              <span className="progress-label">lossless-claw</span>
              <span className="progress-value">Active &nbsp;|&nbsp; 1,189 optimized</span>
            </div>
            <div className="progress-bar">
              <div className="progress-fill green" style={{ width: "100%" }} />
            </div>
          </div>
        </div>

        {/* Column 4 Bottom: Recent Events (like "Open Tickets") */}
        <div className="card">
          <div className="card-header">
            <span className="card-title">Recent Events</span>
            <button className="card-action" title="Filter">&#x2699;</button>
          </div>

          <div className="ticket-item">
            <div className="ticket-avatar" style={{ background: "var(--success-bg)", color: "var(--success)" }}>&#x2713;</div>
            <div className="ticket-content">
              <div className="ticket-name">Inference request</div>
              <div className="ticket-message">Claude Sonnet 4 via OpenRouter — 200 OK, 142ms</div>
              <a className="ticket-link">Details &rsaquo;</a>
            </div>
          </div>

          <div className="ticket-item">
            <div className="ticket-avatar" style={{ background: "var(--info-bg)", color: "var(--info)" }}>&#x21C4;</div>
            <div className="ticket-content">
              <div className="ticket-name">Model switch</div>
              <div className="ticket-message">Active model changed to claude-sonnet-4</div>
              <a className="ticket-link">Details &rsaquo;</a>
            </div>
          </div>

          <div className="ticket-item">
            <div className="ticket-avatar" style={{ background: "var(--warning-bg)", color: "var(--warning)" }}>&#x26A0;</div>
            <div className="ticket-content">
              <div className="ticket-name">Gateway restart</div>
              <div className="ticket-message">Recovered from corrupted cluster state</div>
              <a className="ticket-link">Details &rsaquo;</a>
            </div>
          </div>
        </div>

      </div>
    </Layout>
  );
}
