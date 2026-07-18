# Locations

Two location types: **Production** and **Distribution**.

Each type has its own dashboard controller, join table, and join model. Adding a new location type requires: model, migration, join model, join migration, controller, route, and a home-page box.

## Production

- Model: `Production` — `app/models/production.rb`
- Join: `UserProduction` (`user_id`, `production_id`, `role`) — roles defined in `UserProduction::ROLES`
- Controller: `ProductionsController` — actions: `show` (redirects to tickets), `tickets`, `users`
- Routes:
  - `GET /productions/:id` — redirects to tickets
  - `GET /productions/:id/tickets` — bike ticket dashboard
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

Model: `BikeRequest` — fields: `phone` (10 digits exactly, no formatting), `requestor_name`, `due_date`, `status` (enum), `denial_reason`, `status_before_archival`, `owner_id` (FK to users — the production member assigned at approval)

Each request `has_many :bikes`. `Bike` fields: `name` (optional), `bike_type` (enum: male/female/kid, default male), `age` (required when type is kid), `height`, `notes` (all optional).

Status flow: `requested (1)` → production approves → `pending (0)` → master mechanic marks ready → `ready_for_delivery (2)` → production marks delivered → `delivered (3)` → requestor marks distributed → `distributed (4)`. Production can also deny: `requested` → `denied (5)` → distribution edits and resubmits → `requested`.

- Distribution-submitted requests start as `requested` (awaiting approval); production-submitted requests start as `pending` (skip approval)
- Approving a request requires selecting a production member as the owner via a live-search dropdown; Approve is disabled until one is chosen. The owner is stored on the record.
- Only a `master_mechanic` (or superadmin) can advance `pending` → `ready_for_delivery` via the "Ready for Delivery" button
- "Mark Distributed" is restricted to the entity that submitted the request: distribution users for distribution-submitted requests, production users for production-submitted requests
- Denied cards show a red outline in the distribution's requested tab
- Cards can be archived from any non-requested, non-archived status; unarchiving restores the previous status
- Back-transitions allowed at each step (ready_for_delivery ↔ delivered ↔ distributed)

Production roles in `UserProduction::ROLES`: `admin`, `volunteer`, `master_mechanic`

Routes:
- `GET /distributions/:distribution_id/bike_requests/new` — new request form (distribution access)
- `POST /distributions/:distribution_id/bike_requests` — create (distribution access)
- `GET /productions/:production_id/bike_requests/new` — new internal request form (production access)
- `POST /productions/:production_id/bike_requests` — create internal request (production access)
- `GET /bike_requests/:id/edit` — edit requested/denied request (distribution access)
- `PATCH /bike_requests/:id` — approve/deny/status update (production), mark distributed (requestor), or resubmit (distribution)
- `PATCH /bike_requests/:id/complete_all` — advance pending → ready_for_delivery (master mechanic only)
