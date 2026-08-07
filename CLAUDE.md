# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Wheels does

Wheels manages the process of requesting and distributing bikes. Distribution centers submit requests for individual people; the production center fulfills them.

Users are assigned to one or more locations (productions or distributions) with a role per location: **admin** or **volunteer**. If a user has only one location assigned, they go directly to that dashboard on login. Multiple locations show a picker. Superadmins with no location assignments go directly to the admin panel.

Target audience: ages 25–70, including people uncomfortable with computers. The UI must be simple and intuitive — minimal elements, large tap targets, plain language.

### Bike requests

Each bike request belongs to its `requestor` (the submitting user) — no separate recipient name/phone is collected; `requestor.name`/`requestor.mobile_number` is what's shown everywhere a requestor's identity or contact info is needed. The production center (currently only one, hardcoded to `Production.first`) fulfills it.

Status flow: **requested → pending → ready_for_delivery → taken_up → delivered → distributed**, with `denied` (from `requested`) and `archived` (from most other statuses) as side states. Back-transitions are allowed at each step. Marking pending sets the claiming production worker as the assignee.

Each card will eventually have a print button (not yet implemented — keep the card layout print-friendly).

### Future considerations

- Multiple productions may be added; the hardcoded `Production.first` will need to become selectable.

## Quick reference

- Dev environment & commands: `docs/dev-environment.md`
- Auth & authorization: `docs/architecture/auth.md`
- Locations & bike requests: `docs/architecture/locations.md`
- Admin panel: `docs/architecture/admin.md`
- Views, design system, partials: `docs/architecture/views.md`
- UI design rules: `DESIGN.md`
- Commit policy: see Commits section below
- Testing policy: see Testing section below
- Updating docs: see Documentation section below

## Commits

Do not include a Co-Authored-By line in commit messages.

Write commit messages with a subject line and a body. The body should explain what changed, why, and what the tests cover — two to three sentences minimum. One-line subjects alone are not enough.

## Testing

Every new feature and every change to existing behaviour must have tests before committing. Run the full suite with `PGDATA=$(pwd)/pgdata rails test` and confirm it passes. Do not commit with failing or missing tests.

## Documentation

When making changes, update the relevant `docs/` file(s) before committing. Keep docs current — stale docs are worse than none.

## Stack

Rails 8.1 · PostgreSQL (local Unix socket at `pgdata/`) · HAML · Tailwind CSS v4 · Pagy · Nix flakes

Always set `PGDATA=$(pwd)/pgdata` when running Rails commands. Run the app with `bin/dev`.
