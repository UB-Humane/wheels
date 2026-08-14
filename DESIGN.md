# DESIGN.md

This document describes the visual design system for Wheels. Follow it exactly when building or modifying any UI. Do not introduce new patterns without updating this document.

## Philosophy

The app is used by people aged 25–70, including people who are uncomfortable with computers. Every decision should reduce confusion and cognitive load:

- Show only what is needed for the current task. Remove anything decorative.
- Fewer elements on screen is always better.
- When in doubt, make it bigger and plainer.

---

## Colors

The palette is almost entirely black, white, and gray. Color is not used for decoration.

| Use | Value |
|---|---|
| Page background | `bg-white` |
| Primary text | `text-gray-900` |
| Secondary / muted text | `text-gray-500` |
| Borders | `border-gray-900` (interactive), `border-gray-400` (inputs), `border-gray-200` (dividers) |
| Primary button | `bg-gray-900 text-white hover:bg-gray-700` |
| Destructive action | `text-red-700 underline` (no background) |
| Flash notice | `bg-green-100 border-green-300 text-green-900` |
| Flash alert | `bg-red-100 border-red-300 text-red-900` |

Do not introduce new colors. Do not use colored backgrounds for cards, sections, or labels.

---

## Typography

| Element | Classes |
|---|---|
| Page title (`h1`) | `text-3xl font-bold text-gray-900` |
| Section label | `text-sm font-semibold text-gray-500 uppercase tracking-widest` |
| Body / field labels | `text-xl font-medium text-gray-900` |
| Secondary info | `text-lg text-gray-500` |
| Inline assignments / metadata | `text-lg text-gray-600` |

Minimum font size for any interactive element is `text-lg`. Never go smaller on buttons, labels, or links.

---

## Layout

- Page padding: `px-6 py-8` (applied by the layout, not individual views)
- Max width on forms: `max-w-lg`
- Max width on content pages: none by default — let content breathe
- Vertical spacing between major sections: `space-y-10` or `mb-8`
- Vertical spacing between list rows: `space-y-2`

---

## Responsive / Mobile

Everything must work down to an iPhone SE (375px, and the 320px original). Breakpoint is Tailwind's default `sm` (640px) — below it, mobile rules apply; at and above it, desktop.

- **Two-column rows stack.** Any row with info on one side and actions/metadata on the other (list rows, card headers) is `flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3` — a single full-width column on mobile, side by side with the standard alignment at `sm`+.
- **Actions are full-width on mobile.** Buttons and links in an actions row get `w-full sm:w-auto text-center`. A `button_to`'s wrapping `<form>` needs it too (`form: { class: "w-full sm:w-auto sm:shrink-0" }`), since the form — not the button — is the actual flex item.
- **`sm:shrink-0` on anything that's both a flex item and its own flex container.** Flex items default to `flex-shrink: 1`, so the *outer* row can compress an inner form/group below its own content's natural width before it runs out of room elsewhere — and once compressed, its *internal* `flex-wrap` splits apart (e.g. an input dropping to its own line, separate from its submit button) even though the row as a whole still had space. `sm:shrink-0` stops that: line breaks happen only at the outer row's flex-wrap, never inside a group that fits on its own.
- **`flex-1` inputs need `min-w-0` (or a fixed width) to actually shrink.** A flex item's default `min-width: auto` floors it at its content size, which for a text input can still force the row to overflow on a narrow screen even with `flex-1` set. Add `min-w-0` so it can shrink freely, or give it a concrete `w-full sm:w-<n>` instead of relying on `flex-1` growth inside a `sm:w-auto` (shrink-to-fit) parent, which is ambiguous.
- **Tab bars and other single-row navigation that can outgrow the screen** (e.g. a distribution's 6-tab Bike Tickets bar) get `overflow-x-auto` on the row and `whitespace-nowrap` on each item, so they scroll horizontally in their own strip instead of breaking the page layout.
- **Wide content** (data tables) stays in its own `overflow-x-auto` wrapper — the page itself must never scroll horizontally.

---

## Navigation

The nav bar is rendered by the layout for any logged-in user. It contains, left to right:
- Home icon, linking to root
- Current location name (production or distribution), when on a location dashboard
- That location's tab links (Bike Tickets, Delivery, Your Tickets, Inventory, Donors, Manage Users — whichever apply)
- Current user's name, linking to `/profile/edit` — `text-lg text-gray-700`
- Log out — underlined text link, no button styling

The nav bar uses a thick bottom border (`border-b-2 border-gray-900`) as the only separator. No background color, no shadow.

### Mobile nav

Below the `lg` breakpoint, the tab links row and the profile/logout links both hide (`hidden lg:flex`), replaced by a single dropdown menu (`lg:hidden`): a button styled as a bordered box (`border-2 border-gray-900 bg-white`, showing the active tab's label, or the user's name when there's no location context) that toggles a panel below it. The panel repeats the tab links, then a `border-t border-gray-900` divider, then the profile link and Log out — same items as desktop, just grouped into one menu instead of two areas. `app/javascript/controllers/nav_menu_controller.js` handles toggling and closing on an outside click (same pattern as the existing owner-search dropdown). Home icon and location name stay visible at every width.

---

## Buttons and Actions

### Primary button (one per page)
```haml
= f.submit "Label", class: "px-6 py-3 text-lg font-bold text-white bg-gray-900 hover:bg-gray-700 cursor-pointer transition-colors"
= link_to "Label", path, class: "px-6 py-3 text-lg font-bold text-white bg-gray-900 hover:bg-gray-700 transition-colors"
```

### Secondary / cancel action
```haml
= link_to "Cancel", path, class: "px-6 py-3 text-lg font-medium text-gray-900 underline"
```

### Destructive action (remove / delete)
```haml
= button_to "Remove", path, method: :delete,
    data: { turbo_confirm: "Remove X?" },
    class: "px-4 py-2 text-lg font-medium text-red-700 underline bg-transparent border-0 cursor-pointer"
```

Rules:
- One primary action per page. Everything else is secondary.
- Destructive actions are underlined red text — never a filled red button.
- Confirm dialogs use plain language: "Remove X?" not "Are you sure you want to permanently delete X?"
- When several actions sit in a row (e.g. a request card's status-transition buttons), each one is `w-full sm:w-auto text-center` — full-width and stacked one per row below `sm`, natural width and inline at `sm` and up. `button_to`'s wrapping `<form>` needs the same treatment via `form: { class: "w-full sm:w-auto sm:shrink-0" }` (see the Responsive section above for why `shrink-0` matters).

---

## Navigation Rows (list items that link somewhere)

Used on the home page, admin dashboard, and anywhere a user taps to navigate into a section.

```haml
= link_to path, class: "flex items-center justify-between px-6 py-5 border-2 border-gray-900 hover:bg-gray-100 transition-colors" do
  %span.text-2xl.font-bold.text-gray-900 Label
  %span.text-gray-500 →
```

- Thick border on all four sides
- Large bold label on the left, `→` on the right
- Hover fills with `bg-gray-100`
- No icons, no sublabels unless essential

---

## List Rows (non-navigable, e.g. admin index pages)

```haml
.flex.flex-col.sm:flex-row.sm:items-center.sm:justify-between.gap-3.px-6.py-5.border-2.border-gray-900
  .space-y-1
    %p.text-2xl.font-bold.text-gray-900= item.name
    %p.text-lg.text-gray-500= item.secondary_info
  .flex.flex-wrap.items-center.gap-4.sm:shrink-0
    = button_to "Remove", ...
```

- Same padding and border as navigation rows
- Stacks to a single column below `sm` (info block, then actions block, both full width); side by side with the actions right-aligned at `sm` and up
- Wrap the actions in their own `flex flex-wrap` block, `sm:shrink-0` so they keep their natural size once the row goes horizontal
- Keep secondary info to one line where possible — join with ` · ` separator

---

## Forms

```haml
= form_with ..., class: "space-y-8 max-w-lg" do |f|
  .space-y-2
    = f.label :field, "Label", class: "block text-xl font-medium text-gray-900"
    = f.text_field :field, class: "w-full px-4 py-3 text-xl border-2 border-gray-400 focus:border-gray-900 focus:outline-none"
    - @record.errors[:field].each do |msg|
      %p.text-lg.text-red-700= msg
  .flex.gap-4
    = f.submit "Save", class: "px-6 py-3 text-lg font-bold text-white bg-gray-900 hover:bg-gray-700 cursor-pointer transition-colors"
    = link_to "Cancel", back_path, class: "px-6 py-3 text-lg font-medium text-gray-900 underline"
```

- `border-2 border-gray-400` on inputs, thickens to `border-gray-900` on focus
- No floating labels, no placeholder-only labels — always a visible label above the field
- Validation errors appear directly below the field in `text-red-700`
- Submit + Cancel always paired at the bottom with `flex gap-4`
- Checkboxes: `w-6 h-6 border-2 border-gray-400`
- Selects: `px-3 py-2 text-lg border-2 border-gray-400 bg-white`

---

## What to avoid

- Shadows (`shadow`, `shadow-sm`, `shadow-lg`, etc.) — never
- Rounded corners (`rounded`, `rounded-xl`, `rounded-2xl`, etc.) — never
- Colored card backgrounds (`bg-blue-50`, `bg-green-50`, etc.) — never
- Badges and pills — avoid; use plain text with ` · ` separators instead
- Gradients — never
- Icons — avoid unless absolutely necessary; use text labels
- Hover color changes on non-interactive elements
- More than one visual hierarchy level per page (one `h1`, then flat content)
