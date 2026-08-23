# Admin Panel

All admin controllers inherit from `Admin::BaseController < ApplicationController`, which applies `require_superadmin`. Only accessible to users with `superadmin: true`.

## Managed resources

| Resource | Actions |
|---|---|
| `Production` | index, new, create, edit, update, destroy |
| `Distribution` | index, new, create, edit, update, destroy |
| `User` | index, new, create, destroy |

No edit for Users currently.

## Production print settings

`Production` has a `settings` jsonb column, accessed via the [`store_attribute`](https://github.com/palkan/store_attribute) gem (`app/models/production.rb`) rather than plain `store_accessor` — it adds real type-casting and per-key defaults. Currently exposed: `print_padding_top` (default `120`), `print_padding_right`/`print_padding_bottom`/`print_padding_left` (default `20` each) — pixel padding around the "Print Overview" page (see `docs/architecture/views.md`). All four are editable on `/admin/productions/:id/edit`, validated as non-negative integers; a blank field is rejected by that validation rather than silently reverting to the default.

Defaults are declared once, in `Production::PRINT_PADDING_DEFAULTS` — `store_attribute`'s own `default:` only applies to a brand-new, unsaved record (a persisted row loaded from the DB with the key missing reads back `nil`, not the default), so each reader is overridden (`super() || default`) to fall back correctly either way. This means a future setting only needs a new entry in that hash plus a `store_attribute` line — no migration required to backfill existing rows. The `settings` column's own default (set in the `add_settings_to_productions` migration) additionally seeds real values into every row's jsonb at creation time, so `Production.first.settings` shows real numbers rather than an empty hash — that's a nice-to-have for anyone inspecting the raw column, not something the reader fallback depends on.

## Creating users

Location assignments are submitted as indexed param arrays:

```
production_assignments[i][production_id]
production_assignments[i][enabled]       # "1" = include
production_assignments[i][role]          # "admin" or "volunteer"

distribution_assignments[i][distribution_id]
distribution_assignments[i][enabled]
distribution_assignments[i][role]
```

The controller skips rows where `enabled != "1"`.
