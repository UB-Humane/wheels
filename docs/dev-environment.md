# Dev Environment

Nix flakes — always pre-configured when Claude runs here. No need to run `direnv allow` or `nix develop`.

## PostgreSQL

Runs locally inside the project at `pgdata/`. Connect via Unix socket, not TCP. Always set `PGDATA=$(pwd)/pgdata` when running Rails commands outside the `dev` wrapper.

```
pg-setup   # initialise pgdata/ (first time only)
pg-start   # start postgres
pg-stop    # stop postgres
dev        # pg-start + tmux session "wheels" + pg-stop on exit
```

## Starting the app

```bash
bin/dev    # Rails server + Tailwind watcher via foreman
```

## Environment variables

Loaded from `.env` (gitignored) via the `dotenv` gem — see `.env.example` for the required keys. Changes to `.env` or to `config/initializers/*.rb` require a full restart of `bin/dev`, not just a page reload, since the Rack middleware stack is only built once at boot.

- `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` — Google Cloud Console OAuth 2.0 Client, used for "Sign in with Google" (`docs/architecture/auth.md`). The client's Authorized redirect URIs must include `http://localhost:3000/auth/google_oauth2/callback` for local dev (adjust host/port to match however you're running the app).
- `APP_HOST` — production-only, the app's base host (see "Delivery-only host" in `docs/architecture/locations.md`). Not used in development — that's hardcoded to `testing.wheelsforworkers.org` — or in test. Once set, `config.hosts` in `production.rb` allows `APP_HOST` (and its subdomains) plus `localhost` unconditionally, so running the production build locally (e.g. `docker run` before real deployment) against `localhost:3000` still works — production doesn't auto-permit `localhost` the way development does once `config.hosts` has anything in it.

## Testing the delivery-only host locally

`testing.wheelsforworkers.org` and `delivery.testing.wheelsforworkers.org` need `/etc/hosts` entries pointing at `127.0.0.1`:

```
127.0.0.1 testing.wheelsforworkers.org delivery.testing.wheelsforworkers.org
```

`/etc/hosts` doesn't carry a port, so the `:3000` must be in the URL you visit: `http://testing.wheelsforworkers.org:3000`, not just `http://testing.wheelsforworkers.org`.

## Common commands

```bash
PGDATA=$(pwd)/pgdata rails db:migrate
PGDATA=$(pwd)/pgdata rails db:seed
PGDATA=$(pwd)/pgdata rails db:migrate:status
PGDATA=$(pwd)/pgdata rails routes
PGDATA=$(pwd)/pgdata rails runner '<ruby>'
bundle exec brakeman
bundle exec rubocop
bundle exec bundler-audit
```

Test database is `wheels_test`. Run with `PGDATA=$(pwd)/pgdata rails test`.

## First-time setup

After cloning, run:

```bash
./setup.sh
```

This initialises PostgreSQL, installs gems, configures git hooks, runs migrations, and seeds the database.

## CI

`.github/workflows/docker.yml` builds the production `Dockerfile` and pushes it to GHCR (`ghcr.io/ub-humane/wheels`) on every push to `main` and on `v*.*.*` tags, tagging `latest` on `main`. Pull requests only build the image (Dockerfile validation) — nothing is pushed. The image name is lowercased at runtime since GHCR requires lowercase repository paths.
