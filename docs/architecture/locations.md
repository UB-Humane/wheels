# Locations

Two location types: **Production** and **Distribution**.

Each type has its own dashboard controller, join table, and join model. Adding a new location type requires: model, migration, join model, join migration, controller, route, and a home-page box.

## Production

- Model: `Production` — `app/models/production.rb`
- Join: `UserProduction` (`user_id`, `production_id`, `role`) — roles defined in `UserProduction::ROLES`
- Controller: `ProductionsController` — actions: `show` (redirects to tickets), `tickets`, `delivery`, `your_tickets`, `users`
- Routes:
  - `GET /productions/:id` — redirects to tickets
  - `GET /productions/:id/tickets` — bike ticket dashboard (requested/pending/archived only — see Bike Requests below)
  - `GET /productions/:id/delivery` — delivery dashboard (ready_for_delivery/taken_up/delivered)
  - `GET /productions/:id/your_tickets` — dashboard covering `pending`/`ready_for_delivery`/`taken_up` (`BikeRequest::MECHANIC_STATUSES`), scoped to requests where `owner == current_user`. 403s for anyone who isn't a `master_mechanic` or `admin` (or superadmin) at that production
  - `GET /productions/:id/users` — member management (admin only)
- Currently one record (`Main Production`)
- Nav-bar setup (`@location_name`, `@location_show_delivery`, `@location_show_your_tickets`, etc. — everything the layout's nav needs except `@location_active`, which each action/controller sets itself) lives in `ProductionNav` (`app/controllers/concerns/production_nav.rb`), included by both `ProductionsController` and `DonorsController` (donors is a full CRUD resource nested under productions, not a single-action tab, so it can't just become another `ProductionsController` action — see the concern instead). Any controller that renders inside a production's nav needs both `@production` set and this concern included; a controller with its own hand-rolled copy will silently drift out of sync as new nav fields get added (this happened once already — `DonorsController` was missing `@location_show_delivery`/`@location_show_your_tickets`, which quietly dropped those tabs only on Donors pages).

### Delivery-only host

`ApplicationController.delivery_only_host` (`delivery.` + the base host — hardcoded `testing.wheelsforworkers.org` outside production, `ENV["APP_HOST"]` in production) is a dedicated kiosk hostname for the delivery pickup station. A `before_action` (`restrict_to_delivery_only_host`) redirects every request on that host to `delivery_production_path(Production.first)` except `SessionsController` (login must still work), `ProductionsController#delivery` (the page itself), and `BikeRequestsController#update` (the action buttons that live on that page) — applies to everyone, including superadmins, since it's a restriction on what that host/device shows, not a per-user permission. The nav bar also hides every other location link (`Bike Tickets`, `Your Tickets`, `Inventory`, `Donors`, `Manage Users`) on this host via the `delivery_only_host?` helper. In production, if `APP_HOST` isn't set, the restriction doesn't activate rather than blocking every request.

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

Model: `BikeRequest` — fields: `codename`, `due_date`, `status` (enum), `denial_reason`, `status_before_archival`, `owner_id` (FK to users — the production member assigned at approval), `taker_id` (FK to users — the production member who claimed the delivery via "I've got this"). No separate requestor name/phone is collected — `user` (the submitting account, set from `current_user` at creation) already has `name`/`mobile_number`, so that's what's shown wherever a requestor's identity is needed (card and both print outputs read `req.user.name`/`req.user.mobile_number`, styled "Requested by {name} ({number})").

`codename` is an auto-generated two-word identifier (e.g. "brave-tiger") assigned in `before_create :assign_codename`, meant to make individual requests easy to recognize/reference. `BikeRequest.generate_codename` picks a random adjective + noun from `lib/data/adjectives.txt`/`lib/data/nouns.txt` (Glitch's `friendly-words` lists — curated to avoid offensive/awkward combinations, not derived from a raw dictionary), retrying if the pair is already in use by another *open* request — `BikeRequest::CLOSED_STATUSES` (`delivered`, `distributed`) are excluded from that uniqueness check, so a closed request's codename can be reused. No DB-level uniqueness constraint backs this (a deliberate choice — a rare collision between two open requests isn't worth the complexity of enforcing it), but `codename` does have a plain index for the lookup. Shown on the card next to the production/distribution name, and on both print outputs.

Each request `has_many :bikes`. `Bike` fields: `name` (optional), `bike_type` (enum: male/female/kid, default male), `age`, `height`, `notes` (all optional, no enforcement on `age` even for kid bikes).

Status flow: `requested (1)` → production approves → `pending (0)` → master mechanic marks ready → `ready_for_delivery (2)` → delivery volunteer takes it up → `taken_up (7)` → delivery volunteer marks done → `delivered (3)` → requestor marks distributed → `distributed (4)`. Production can also deny: `requested` → `denied (5)` → distribution edits and resubmits → `requested`.

- Distribution-submitted requests start as `requested` (awaiting approval); production-submitted requests start as `pending` (skip approval)
- A production `admin`/`master_mechanic` can also submit a request on behalf of any distribution, from the same "Request Bikes" form used for production self-requests (`app/views/bike_requests/new.html.haml`) — a live-search "Request on behalf of a distribution" field (`GET /productions/:id/distributions_search`, gated to admin/master_mechanic) is shown only to those roles, alongside the existing Owner field. Selecting a distribution and submitting via `POST /productions/:id/bike_requests` attaches that distribution to the record but otherwise follows the production self-request path exactly — `pending` status (skips approval, since the admin/master mechanic submitting it already has approval authority) and an owner picked via the same live-search used for a normal self-request. `BikeRequestsController#selected_distribution` only honors the `bike_request[distribution_id]` param for admin/master_mechanic, so a plain volunteer submitting it has no effect and falls through to the ordinary self-request flow. The requestor (`user`) is whoever is logged in and submitting the form (the admin/master mechanic), not anyone from the distribution.
- Approving a request requires selecting a production member as the owner via a live-search dropdown; Approve is disabled until one is chosen. The owner is stored on the record. The live-search endpoint (`GET /productions/:id/members`) and a `BikeRequest` model validation both restrict the owner to a `master_mechanic` or `admin` at that production (`UserProduction::OWNER_ROLES`) — a request with an ineligible `owner_id` (e.g. a volunteer) fails validation (`errors[:owner]`, "must be a master mechanic or admin"), on both `create` (production-submitted requests) and `approve` (distribution-submitted requests).
- Only a `master_mechanic` (or superadmin) can advance `pending` → `ready_for_delivery` via the "Ready for Delivery" button
- `ready_for_delivery` → `taken_up` ("I've got this") is only available on the production's Delivery dashboard and is open to any production member (admin, volunteer, or master_mechanic). It records the acting user as `taker_id`, shown on the card as "Picked up by".
- `taken_up` → `delivered` ("I'm done!") is restricted to the recorded `taker` or a `master_mechanic` (or superadmin) — not open to any production member. Setting `delivered` from any *other* status (a skip-ahead from `ready_for_delivery`, or the `distributed` → `delivered` correction below) requires `admin` or `master_mechanic` instead — there is no way for a plain volunteer to set `delivered` directly.
- "Mark Distributed" is restricted to the entity that submitted the request: distribution users for distribution-submitted requests (shown on the distribution's own Bike Tickets dashboard only), production users for production-submitted requests (shown on the production's Delivery dashboard, to the left of "Back to Taken Up", only when the request has no distribution)
- Denied cards show a red outline in the distribution's requested tab
- Cards can be archived from any non-requested, non-archived status; unarchiving restores the previous status
- Back-transitions (`pending` → `requested`, `ready_for_delivery` → `pending`, `taken_up` → `ready_for_delivery`, `delivered` → `taken_up`, and the `distributed` → `delivered` correction) are each one step, restricted to `admin` or `master_mechanic` (or superadmin) — not open to plain volunteers. The four with buttons use distinct `back_to_*` status params in `BikeRequestsController::BACK_TRANSITION_STATUSES` so they never collide with the forward-action param names (e.g. `back_to_taken_up` vs `taken_up`). `delivered` → `taken_up` does not change `taker_id`. `distributed` → `delivered` has no button but remains reachable directly via `PATCH` for an admin/master_mechanic.
- Any move to `requested` — `back_to_requested` (`pending` → `requested`) or a distribution's resubmit (`denied` → `requested`) — clears both `owner_id` and `taker_id`, since neither an owner nor a taker is meaningful before the request is re-approved.

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
