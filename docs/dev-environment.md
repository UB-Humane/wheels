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
