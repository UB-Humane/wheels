# Views

All views are HAML. Tailwind CSS v4 compiled by `tailwindcss-rails` to `app/assets/builds/tailwind.css`.

The layout (`application.html.haml`) renders the nav bar (home icon, location name + tab links, current user + logout) for logged-in users and injects flash messages. The current user's name links to `/profile/edit` for self-service editing (see `docs/architecture/auth.md`), with a small inline SVG pencil icon — the one deliberate exception to DESIGN.md's icon-avoidance rule, kept as a minimal edit affordance next to the name rather than a second text link.

Below the `lg` breakpoint, the tab links and the profile/logout links collapse into a single dropdown menu (button + toggled panel) instead of two separate areas — see "Mobile nav" in `DESIGN.md`. `app/javascript/controllers/nav_menu_controller.js` handles the toggle/outside-click-close, mirroring `owner_search_controller.js`'s existing dropdown pattern.

## Design

Full design system: `DESIGN.md` at the project root. Summary:

- Target audience: ages 25–70, including people uncomfortable with computers
- Flat, minimal — no shadows, no rounded corners, no colored backgrounds
- Black/white/gray palette only; color only for errors (red) and flash (green/red)
- Minimum font size on interactive elements: `text-lg`
- Borders: `border-2 border-gray-900` as the only visual separator
- One primary action per page

## Shared partials

- `app/views/bike_requests/_list.html.haml` — tab bar + request cards + pagination, used by Production's Bike Tickets and Delivery dashboards and Distribution's Bike Tickets dashboard. Accepts: `active_tab`, `bike_requests`, `pagy`, `tab_counts`, `tabs` (array of status names shown as tabs — each caller passes its own subset), `production_view` (bool — shows action buttons and hides DC name when true). Each card carries `data-print-*` values (bikes, requestor, source, codename, phone, owner, due — `owner` is pre-formatted as `"NAME (number)"` or blank if unassigned) consumed by `app/javascript/controllers/print_controller.js`'s `printLabels` (one 50×80mm label per bike, sized via `@page { size: 50mm 80mm }` — source, then every bike field as a `Label: value` line (`-` when blank), then the codename large and centered at the bottom with the position/total counter beneath it; no requestor/owner info, to keep labels compact) and `printCard` (single-page overview table, showing "Requested By" and, if present, "Owned By") actions.

## Pagination

Pagy gem. `Pagy::Backend` included in `ApplicationController`, `Pagy::Frontend` in `ApplicationHelper`. Use `pagy(scope, limit: 20)` in controllers. Render with plain prev/next links (not `pagy_nav`).
