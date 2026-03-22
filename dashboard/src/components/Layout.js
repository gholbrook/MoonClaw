import Link from "next/link";
import { useRouter } from "next/router";

const navSections = [
  {
    label: "Overview",
    links: [{ href: "/", label: "Dashboard", icon: "grid" }],
  },
  {
    label: "Monitoring",
    links: [
      { href: "/monitoring/sandbox", label: "Sandbox Status", icon: "box" },
      { href: "/monitoring/inference", label: "Inference Health", icon: "zap" },
      { href: "/monitoring/logs", label: "Live Logs", icon: "terminal" },
    ],
  },
  {
    label: "Configuration",
    links: [
      { href: "/config/providers", label: "Providers", icon: "cloud" },
      { href: "/config/models", label: "Models", icon: "cpu" },
      { href: "/config/network", label: "Network Policy", icon: "shield" },
      { href: "/config/shared-drive", label: "Shared Drive", icon: "folder" },
    ],
  },
];

const icons = {
  grid: "▦",
  box: "□",
  zap: "⚡",
  terminal: ">_",
  cloud: "☁",
  cpu: "◈",
  shield: "⛊",
  folder: "📁",
};

export default function Layout({ children }) {
  const router = useRouter();

  return (
    <div className="layout">
      <header className="topbar">
        <div className="topbar-logo">MoonClaw</div>
        <div className="topbar-status">
          <span className="badge badge-success">
            <span className="status-dot online" />
            System Online
          </span>
        </div>
      </header>

      <nav className="sidebar">
        {navSections.map((section) => (
          <div key={section.label} className="sidebar-section">
            <div className="sidebar-label">{section.label}</div>
            {section.links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`sidebar-link ${
                  router.pathname === link.href ? "active" : ""
                }`}
              >
                <span>{icons[link.icon] || "•"}</span>
                {link.label}
              </Link>
            ))}
          </div>
        ))}
      </nav>

      <main className="main">{children}</main>
    </div>
  );
}
