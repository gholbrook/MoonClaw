import Link from "next/link";
import { useRouter } from "next/router";

const sidebarItems = [
  { href: "/", icon: "grid", label: "Dashboard" },
  { href: "/monitoring/sandbox", icon: "box", label: "Sandbox" },
  { href: "/monitoring/inference", icon: "zap", label: "Inference" },
  { href: "/monitoring/logs", icon: "terminal", label: "Logs" },
  { type: "spacer" },
  { href: "/config/providers", icon: "cloud", label: "Providers" },
  { href: "/config/models", icon: "cpu", label: "Models" },
  { href: "/config/network", icon: "shield", label: "Network" },
  { href: "/config/shared-drive", icon: "folder", label: "Shared Drive" },
];

const topPills = [
  { href: "/", label: "Overview", match: ["/"] },
  { href: "/monitoring/sandbox", label: "Monitoring", match: ["/monitoring"] },
  { href: "/config/providers", label: "Configuration", match: ["/config"] },
];

function SidebarIcon({ icon }) {
  const icons = {
    grid: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="3" y="3" width="6" height="6" rx="1.5" />
        <rect x="11" y="3" width="6" height="6" rx="1.5" />
        <rect x="3" y="11" width="6" height="6" rx="1.5" />
        <rect x="11" y="11" width="6" height="6" rx="1.5" />
      </svg>
    ),
    box: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="3" y="5" width="14" height="12" rx="2" />
        <path d="M3 9h14" />
        <path d="M8 5V3h4v2" />
      </svg>
    ),
    zap: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M11 2L5 11h4l-1 7 6-9h-4l1-7z" />
      </svg>
    ),
    terminal: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="2" y="3" width="16" height="14" rx="2" />
        <path d="M6 8l3 2-3 2" />
        <path d="M11 12h3" />
      </svg>
    ),
    cloud: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M5.5 16h9a4 4 0 00.5-7.97A6 6 0 005 9.5 3.5 3.5 0 005.5 16z" />
      </svg>
    ),
    cpu: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="5" y="5" width="10" height="10" rx="1" />
        <rect x="7.5" y="7.5" width="5" height="5" rx="0.5" />
        <path d="M8 2v3M12 2v3M8 15v3M12 15v3M2 8h3M2 12h3M15 8h3M15 12h3" />
      </svg>
    ),
    shield: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M10 2l7 3v5c0 4-3 6.5-7 8-4-1.5-7-4-7-8V5l7-3z" />
      </svg>
    ),
    folder: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M3 6a2 2 0 012-2h3l2 2h5a2 2 0 012 2v7a2 2 0 01-2 2H5a2 2 0 01-2-2V6z" />
      </svg>
    ),
    settings: (
      <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
        <circle cx="10" cy="10" r="3" />
        <path d="M10 2v2M10 16v2M2 10h2M16 10h2M4.22 4.22l1.42 1.42M14.36 14.36l1.42 1.42M4.22 15.78l1.42-1.42M14.36 5.64l1.42-1.42" />
      </svg>
    ),
  };
  return icons[icon] || null;
}

export default function Layout({ children }) {
  const router = useRouter();

  function isActivePill(pill) {
    if (pill.href === "/") return router.pathname === "/";
    return pill.match.some((m) => router.pathname.startsWith(m));
  }

  function isSidebarActive(href) {
    return router.pathname === href;
  }

  return (
    <div className="layout">
      <header className="topbar">
        <div className="topbar-left">
          <Link href="/" className="topbar-logo" style={{ textDecoration: "none" }}>
            MoonClaw
            <span>studio.</span>
          </Link>
          <nav className="topbar-pills">
            {topPills.map((pill) => (
              <Link
                key={pill.href}
                href={pill.href}
                className={`topbar-pill ${isActivePill(pill) ? "active" : ""}`}
              >
                {pill.label}
              </Link>
            ))}
          </nav>
        </div>
        <div className="topbar-right">
          <button className="topbar-icon" title="Notifications">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
              <path d="M15 7a5 5 0 00-10 0c0 5-2 7-2 7h14s-2-2-2-7" />
              <path d="M8.5 17a2 2 0 003 0" />
            </svg>
          </button>
          <button className="topbar-icon" title="Help">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
              <circle cx="10" cy="10" r="8" />
              <path d="M7.5 7.5a2.5 2.5 0 015 0c0 1.5-2.5 2-2.5 3.5" />
              <circle cx="10" cy="14" r="0.5" fill="currentColor" />
            </svg>
          </button>
          <button className="topbar-icon" title="Settings">
            <SidebarIcon icon="settings" />
          </button>
        </div>
      </header>

      <nav className="sidebar">
        {sidebarItems.map((item, i) => {
          if (item.type === "spacer") return <div key={i} className="sidebar-spacer" />;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`sidebar-icon ${isSidebarActive(item.href) ? "active" : ""}`}
              title={item.label}
            >
              <SidebarIcon icon={item.icon} />
            </Link>
          );
        })}
      </nav>

      <main className="main">{children}</main>
    </div>
  );
}
