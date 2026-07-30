# Locations

Two location types: **Production** and **Distribution**.

Each type has its own dashboard controller, join table, and join model. Adding a new location type requires: model, migration, join model, join migration, controller, route, and a home-page box.

## Production

- Model: `Production` — `app/models/production.rb`
- Join: `UserProduction` (`user_id`, `production_id`, `role`) — roles defined in `UserProduction::ROLES`
- Controller: `ProductionsController` — actions: `show` (redirects to tickets), `tickets`, `delivery`, `users`
- Routes:
  - `GET /productions/:id` — redirects to tickets
  - `GET /productions/:id/tickets` — bike ticket dashboard (requested/pending/archived only — see Bike Requests below)
  - `GET /productions/:id/delivery` — delivery dashboard (ready_for_delivery/taken_up/delivered)
  - `GET /productions/:id/users` — member management (admin only)
- Currently one record (`Main Production`)

## Distribution

- Model: `Distribution` — `app/models/distribution.rb`; has `name` and `address`
- Join: `UserDistribution` (`user_id`, `distribution_id`, `role`) — roles defined in `UserDistribution::ROLES`
- Controller: `DistributionsController` — actions: `show` (redirects to tickets), `tickets`, `users`
- Routes:
  - `GET /distributions/:id` — redirects to tickets
  - `GET /distributions/:id/tickets` — bike ticket dashboard
  - `GET /distributions/:id/users` — member management (admin only)

## Member Management

Both productions and distributions have a `/users` route for managing members. Only location admins (and superadmins) can access it. Members can be searched by name or email (fuzzy, ILIKE), added with a role, have their role changed, or be removed.

Nested routes:
- `POST /productions/:id/user_productions` — add member
- `PATCH /productions/:id/user_productions/:id` — update role
- `DELETE /productions/:id/user_productions/:id` — remove member
- Same pattern for distributions with `user_distributions`

## Bike Requests

Distributions submit bike requests to a production. One request = one person with one or more bikes. Productions can also submit internal requests directly (no distribution).

Model: `BikeRequest` — fields: `phone` (10 digits exactly, no formatting), `requestor_name`, `due_date`, `status` (enum), `denial_reason`, `status_before_archival`, `owner_id` (FK to users — the production member assigned at approval), `taker_id` (FK to users — the production member who claimed the delivery via "I've got this")

Each request `has_many :bikes`. `Bike` fields: `name` (optional), `bike_type` (enum: male/female/kid, default male), `age` (required when type is kid), `height`, `notes` (all optional).

Status flow: `requested (1)` → production approves → `pending (0)` → master mechanic marks ready → `ready_for_delivery (2)` → delivery volunteer takes it up → `taken_up (7)` → delivery volunteer marks done → `delivered (3)` → requestor marks distributed → `distributed (4)`. Production can also deny: `requested` → `denied (5)` → distribution edits and resubmits → `requested`.

- Distribution-submitted requests start as `requested` (awaiting approval); production-submitted requests start as `pending` (skip approval)
- Approving a request requires selecting a production member as the owner via a live-search dropdown; Approve is disabled until one is chosen. The owner is stored on the record.
- Only a `master_mechanic` (or superadmin) can advance `pending` → `ready_for_delivery` via the "Ready for Delivery" button
- `ready_for_delivery` → `taken_up` ("I've got this") is only available on the production's Delivery dashboard and is open to any production member (admin, volunteer, or master_mechanic). It records the acting user as `taker_id`, shown on the card as "Picked up by".
- `taken_up` → `delivered` ("I'm done!") is restricted to the recorded `taker` or a `master_mechanic` (or superadmin) — not open to any production member. Setting `delivered` from any *other* status (a skip-ahead from `ready_for_delivery`, or the `distributed` → `delivered` correction below) requires `admin` or `master_mechanic` instead — there is no way for a plain volunteer to set `delivered` directly.
- "Mark Distributed" is restricted to the entity that submitted the request: distribution users for distribution-submitted requests (shown on the distribution's own Bike Tickets dashboard only), production users for production-submitted requests (shown on the production's Delivery dashboard, to the left of "Back to Taken Up", only when the request has no distribution)
- Denied cards show a red outline in the distribution's requested tab
- Cards can be archived from any non-requested, non-archived status; unarchiving restores the previous status
- Back-transitions (`pending` → `requested`, `ready_for_delivery` → `pending`, `taken_up` → `ready_for_delivery`, `delivered` → `taken_up`, and the `distributed` → `delivered` correction) are each one step, restricted to `admin` or `master_mechanic` (or superadmin) — not open to plain volunteers. The four with buttons use distinct `back_to_*` status params in `BikeRequestsController::BACK_TRANSITION_STATUSES` so they never collide with the forward-action param names (e.g. `back_to_taken_up` vs `taken_up`). `delivered` → `taken_up` does not change `taker_id`. `distributed` → `delivered` has no button but remains reachable directly via `PATCH` for an admin/master_mechanic.

Production's Bike Tickets dashboard only shows `requested`/`pending`/`archived` — once a request reaches `ready_for_delivery`, it moves to the production's Delivery dashboard instead, covering `ready_for_delivery`/`taken_up`/`delivered`. Distribution's Bike Tickets dashboard is unaffected and still shows the full flow end to end (`requested`/`pending`/`ready_for_delivery`/`delivered`/`distributed`/`archived` — `taken_up` is Delivery-exclusive and never shown there).

Production roles in `UserProduction::ROLES`: `admin`, `volunteer`, `master_mechanic`

Routes:
- `GET /distributions/:distribution_id/bike_requests/new` — new request form (distribution access)
- `POST /distributions/:distribution_id/bike_requests` — create (distribution access)
- `GET /productions/:production_id/bike_requests/new` — new internal request form (production access)
- `POST /productions/:production_id/bike_requests` — create internal request (production access)
- `GET /bike_requests/:id/edit` — edit requested/denied request (distribution access)
- `PATCH /bike_requests/:id` — approve/deny/status update (production), mark distributed (requestor), or resubmit (distribution)
- `PATCH /bike_requests/:id/complete_all` — advance pending → ready_for_delivery (master mechanic only)
