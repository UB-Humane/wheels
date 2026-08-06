# Authentication & Authorization

## Authentication

Custom session-based auth using `has_secure_password` (bcrypt). No Devise.

- `SessionsController` — login/logout at `/login` and `/logout`; skips `require_authentication`
- `ApplicationController` — memoizes `current_user` from `session[:user_id]`; `require_authentication` is a default `before_action` on all controllers

## Sign in with Google

`omniauth` + `omniauth-google-oauth2`, configured in `config/initializers/omniauth.rb` from `ENV["GOOGLE_OAUTH_CLIENT_ID"]` / `ENV["GOOGLE_OAUTH_CLIENT_SECRET"]` (loaded from `.env` via the `dotenv` gem — see `docs/dev-environment.md`). `omniauth-rails_csrf_protection` restricts the request phase to `POST` with a valid Rails CSRF token, so the "Sign in with Google" button on `/login` is a `button_to`, not a plain link.

- `POST /auth/google_oauth2` — request phase, handled entirely by the OmniAuth Rack middleware (no Rails route)
- `GET /auth/google_oauth2/callback` → `SessionsController#omniauth` — matches a `User` by the email Google verifies (`auth.info.email`); if none exists, auto-creates one (`name` from Google, falling back to the email if Google gives no name; a random unusable password to satisfy `has_secure_password`/`password_digest NOT NULL`). New accounts have no location assignments until a superadmin assigns them.
- `GET /auth/failure` → `SessionsController#omniauth_failure` — redirects to `/login` with an alert on any OmniAuth failure (denied consent, etc.)

`SessionsController` stays fully reachable on the delivery-only host (`docs/architecture/locations.md`), so login works there too — but Google validates the callback URL per host. Any new host that needs to serve login (e.g. `delivery.<APP_HOST>` once a production domain exists) must have its own `.../auth/google_oauth2/callback` URL added to the OAuth client's Authorized redirect URIs in Google Cloud Console — this is a manual step, not something the app can do for itself.

## Authorization

Access is determined entirely by location assignments, not a global role.

```
User
 ├── has_many :user_productions       (join: user_id, production_id, role)
 ├── has_many :productions, through: :user_productions
 ├── has_many :user_distributions     (join: user_id, distribution_id, role)
 ├── has_many :distributions, through: :user_distributions
 └── superadmin: boolean
```

`role` is `"admin"` or `"volunteer"`, scoped per location. A user can be admin at one production and volunteer at a distribution simultaneously.

`superadmin: true` is the only way to access `/admin`. Independent of location assignments.

## Access control helpers (ApplicationController)

| Helper | Enforces |
|---|---|
| `require_authentication` | user is logged in |
| `require_superadmin` | `current_user.superadmin?` |
| `require_production_access(production)` | user has this production assigned |
| `require_distribution_access(distribution)` | user has this distribution assigned |

All return `403 Access denied` (plain text) on failure.

## Self-service profile

Any logged-in user can edit their own name, email, mobile number, and password at `/profile/edit` (`ProfilesController`, scoped to `current_user` — no `:id` param, so a user can never target another user's record). The username link in the nav bar (top right) points here. Cannot change the `superadmin` flag or location assignments — that stays superadmin-only via `Admin::UsersController`.

`mobile_number` is optional at the model level (`allow_blank: true`, so `/profile/edit` and the admin user form can still leave it blank) and, when present, must be exactly 10 digits (no spaces, dashes, or country code) — validated by `User::MOBILE_NUMBER_FORMAT`.

## Mobile number requirement

`require_mobile_number` (`ApplicationController`, runs right after `require_authentication`, before `restrict_to_delivery_only_host`) redirects any logged-in user with a blank `mobile_number` to `/mobile_number/edit` (`MobileNumbersController`) — a single-field page that enforces presence itself (the model validation stays optional, since it's shared with `/profile/edit`). Applies app-wide, including `/admin`, with no superadmin exemption. `MobileNumbersController` skips this callback on itself, and is in the delivery-only host's allow-list, so it doesn't loop.

## Post-login routing (HomeController)

1. Superadmin with no location assignments → redirect to `/admin`
2. Exactly one location total → redirect directly to that dashboard
3. Otherwise → home page with up to three boxes: Productions, Distributions, Admin Panel
