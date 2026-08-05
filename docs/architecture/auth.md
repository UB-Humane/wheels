# Authentication & Authorization

## Authentication

Custom session-based auth using `has_secure_password` (bcrypt). No Devise.

- `SessionsController` — login/logout at `/login` and `/logout`; skips `require_authentication`
- `ApplicationController` — memoizes `current_user` from `session[:user_id]`; `require_authentication` is a default `before_action` on all controllers

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

`mobile_number` is optional and, when present, must be exactly 10 digits (no spaces, dashes, or country code) — validated by `User::MOBILE_NUMBER_FORMAT`.

## Post-login routing (HomeController)

1. Superadmin with no location assignments → redirect to `/admin`
2. Exactly one location total → redirect directly to that dashboard
3. Otherwise → home page with up to three boxes: Productions, Distributions, Admin Panel
