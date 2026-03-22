# MoonClaw Design System

## Intent

**Who:** Developer who just installed NemoClaw on Windows. Checking if sandbox is alive, inference is flowing, diagnosing failures. Often late evening, mid-debug.

**What they must accomplish:** Verify health at a glance, diagnose when things break, reconfigure providers and models.

**Feel:** Warm, spacious, professional. A polished project management tool — not a dark terminal. Inspired by Panze Studio's project dashboard. Confident when things work, clear when they don't.

## Direction

Light warm theme. Cards float on shadows, not borders. Dense information without clutter. Icon-only sidebar keeps navigation compact. Pill tabs for section switching.

## Palette

| Token | Value | Usage |
|-------|-------|-------|
| `--bg-body` | `#F5F3EF` | Page background — warm cream |
| `--bg-card` | `#FFFFFF` | Card surfaces |
| `--bg-sidebar` | `#FFFFFF` | Sidebar background |
| `--bg-topbar` | `#FFFFFF` | Top bar background |
| `--bg-hover` | `#F0EDE8` | Hover states |
| `--bg-input` | `#F5F3EF` | Input backgrounds |
| `--bg-active` | `#1A1A2E` | Active pill/sidebar — dark navy |
| `--text-primary` | `#1A1A2E` | Headings, primary text |
| `--text-secondary` | `#6B7280` | Body text, descriptions |
| `--text-muted` | `#9CA3AF` | Labels, meta text |
| `--text-inverse` | `#FFFFFF` | Text on dark backgrounds |
| `--success` | `#00C48C` | Healthy, running, online |
| `--warning` | `#F4A261` | Degraded, pending |
| `--error` | `#FF4757` | Failed, stopped, offline |
| `--info` | `#4A90D9` | Informational, links |
| `--orange` | `#F4A261` | NVIDIA NIM accent |
| `--blue` | `#4A90D9` | OpenRouter accent |
| `--purple` | `#7C5CFC` | Plugin/extension accent |
| `--green` | `#00C48C` | Success accent |

**Why warm cream, not dark:** This is a monitoring dashboard you check, not a terminal you live in. The light theme reduces the "scary ops tool" barrier and matches the Panze reference.

**Why dark navy active states:** High contrast on light backgrounds. The dark pill/sidebar active state is the signature element from the reference.

## Depth

- **No visible borders on cards.** Cards are separated by shadow only.
- **Shadow scale:** `--shadow-sm` (1px 3px), `--shadow-md` (2px 8px), `--shadow-lg` (4px 16px)
- **Cards hover to `--shadow-md`** for subtle interaction feedback.
- **Whitespace separates, not lines.** Dividers within cards use `#F3F0EB` (barely visible).

## Surfaces

Two-level elevation:
1. **Background** — `#F5F3EF` cream
2. **Cards** — `#FFFFFF` white, `border-radius: 16px`, `box-shadow: var(--shadow-sm)`

Nested surfaces (event cards inside cards) use `--bg-body` as background.

## Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Page title | 28px | 700 | `--text-primary` |
| Page subtitle | 13px | 400 | `--text-muted` |
| Card title | 16px | 600 | `--text-primary` |
| Body text | 14px | 400 | `--text-secondary` |
| Labels | 12px | 500 | `--text-secondary` |
| Meta/muted | 12px | 400 | `--text-muted` |
| Metric value | 28px | 700 | `--text-primary` |
| Code/mono | 12px | 400 | JetBrains Mono |

**Font:** Inter — clean, modern, excellent readability at small sizes. Matches the reference.

**Letter spacing:** -0.5px on page title and logo for tightness.

## Spacing

- **Base unit:** 8px
- **Card padding:** 24px
- **Grid gaps:** 24px
- **Section margin:** 32px
- **Main content padding:** 32px

## Layout

### Top Bar (64px)
- Full width, spans sidebar
- Left: Logo + pill navigation tabs
- Right: Icon buttons (notifications, help, settings)
- No shadow or border — sits flush with content

### Sidebar (64px wide)
- Icon-only, centered vertically
- Icons: 44x44px hit area, 10px border-radius
- Active state: dark navy background, white icon
- Hover: cream background
- Spacer separates monitoring icons from config icons

### Pill Navigation
- Top bar: section-level (Overview, Monitoring, Configuration)
- Inside cards: contextual tabs (Running/All, filters)
- Active: `--bg-active` fill, white text, `border-radius: 999px`
- Inactive: transparent, `--text-secondary`, 1px border

### Dashboard Grid
```css
grid-template-columns: 280px 1fr 1fr 300px;
```
- Column 1: Services list (full height, spans 2 rows)
- Column 2-3: Charts and metrics
- Column 4: Quick status + recent events

## Components

### Card
White, 16px radius, soft shadow. Header has title + action button. No border.

### Service Item
Icon (36px, colored background) + name/description + status check circle. Separated by subtle `#F3F0EB` border-bottom.

### Progress Bar
Label + value on top, rounded 8px bar below. Colors: blue (OpenRouter), purple (NIM), orange (pending), green (active), red (error).

### Event Card
Nested card (cream background) inside a white card. Meta label, title, detail with status dot. Arrow action button.

### Donut Chart
SVG-based, 160px, 24px stroke width. Segments with rounded linecaps. Legend below with colored dots.

### Status Badge
Pill-shaped (999px radius). Colored background + dot. Variants: success, warning, error, info.

### Ticket Item
Avatar circle + name + message + link. Used for recent events.

## Icons

SVG-based, 20x20 viewBox, stroke-only (1.5px), `currentColor`. No icon library — inline SVGs for tree-shaking and zero dependencies.

Available: grid, box, zap, terminal, cloud, cpu, shield, folder, settings, bell, help, search.

## Pages

| Path | Section | Purpose |
|------|---------|---------|
| `/` | Overview | Dashboard home — 4-column grid with services, inference, resources, status, events |
| `/monitoring/sandbox` | Monitoring | Sandbox container details, CPU/memory, actions |
| `/monitoring/inference` | Monitoring | Provider health, request metrics, latency |
| `/monitoring/logs` | Monitoring | Live log viewer with filters |
| `/config/providers` | Configuration | Provider CRUD, connection testing |
| `/config/models` | Configuration | Model list, activate/deactivate |
| `/config/network` | Configuration | Network policy rules, presets |
| `/config/shared-drive` | Configuration | Shared folder stats, permissions |

## Reference

Design inspired by [Panze Studio Project Dashboard](https://dribbble.com/shots/panze-studio) — warm light theme, icon sidebar, pill tabs, card grid, progress bars, donut chart, event cards.
