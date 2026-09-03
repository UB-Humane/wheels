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

`Production` has a `settings` jsonb column, accessed via the [`store_attribute`](https://github.com/palkan/store_attribute) gem (`app/models/production.rb`) rather than plain `store_accessor` — it adds real type-casting and per-key defaults. Currently exposed: `print_padding_top` (default `120`), `print_padding_right`/`print_padding_bottom`/`print_padding_left` (default `20` each) — pixel padding around the "Print Overview" page (see `docs/architecture/views.md`) — and `print_font`, one of the keys in `Production::PRINT_FONTS` (default `atkinson_hyperlegible`), used for both the "Print Overview" and "Print Stickers" labels. All are editable on `/admin/productions/:id/edit`; the padding fields are validated as non-negative integers (a blank field is rejected rather than silently reverting to the default), and `print_font` is validated against `PRINT_FONTS.keys`.

Defaults are declared once — `Production::PRINT_PADDING_DEFAULTS` for padding, `Production::PRINT_FONT_DEFAULT` for the font — `store_attribute`'s own `default:` only applies to a brand-new, unsaved record (a persisted row loaded from the DB with the key missing reads back `nil`, not the default), so each reader is overridden (`super() || default`) to fall back correctly either way. This means a future setting only needs a `store_attribute` line plus a reader override — no migration required to backfill existing rows. The `settings` column's own default (set in the `add_settings_to_productions` migration) additionally seeds real padding values into every row's jsonb at creation time, so `Production.first.settings` shows real numbers rather than an empty hash — that's a nice-to-have for anyone inspecting the raw column, not something the reader fallback depends on (it wasn't extended to cover `print_font` when that key was added, precisely because the fallback makes it unnecessary).

`PRINT_FONTS` maps a stored key (e.g. `"public_sans"`) to its Google Fonts family name (e.g. `"Public Sans"`); `Production#print_font_family` resolves the current key to that name. The print views load all five candidate fonts (Inter, Noto Sans, IBM Plex Sans, Public Sans, Atkinson Hyperlegible) from Google Fonts' CDN rather than bundling them with the app — see `FONTS_URL` in `app/javascript/controllers/print_controller.js`.

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
