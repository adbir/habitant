# Habitant — Design Principles

Guidelines for all UI and navigation work in this app. When in doubt, refer back here before reaching for a pattern that isn't listed.

---

## Navigation & screen hierarchy

Every piece of content that a user might read, act on, or share gets its own **full screen** and a dedicated route. Do not put content inside sheets or dialogs.

```text
Admin shell (/admin)
  └─ Housing detail   /admin/housing/:id
       └─ Address detail   /admin/housing/:housingId/address/:addressId
            └─ Tenancy issues   /admin/housing/:housingId/address/:addressId/tenancy-issues
                 └─ Issue detail   /staff/issues/:id

Staff shell (/staff)
  └─ Issue detail   /staff/issues/:id

Tenant shell (/tenant)
  └─ Report issue   /tenant/report-issue
  └─ Issue detail   /tenant/issues/:id
```

Shell routes (inside `ShellRoute`) render navigation chrome (rail on desktop, bar on mobile). Detail and action routes sit **outside** the shell so they go full-screen with a back button and no nav chrome.

---

## Routing rules

Two rules prevent router/screen timing bugs:

1. **The router only blocks — screens navigate on success.**
   `computeAuthRedirect` returns a redirect path when a user *must not* be
   somewhere. It never drives positive navigation (what happens after a flow
   completes). On completion, the screen calls `context.go(...)` or
   `context.push(...)` directly. The join flow is the canonical example: the
   router allows `/join` for all authenticated users unconditionally;
   `JoinScreen` calls `context.go('/tenant')` when the VM reaches
   `JoinStep.complete`.

2. **All data mutations go through `ApiClient`.**
   ViewModels must not call `_supabase.from(...).insert/update/upsert`
   directly. Use `ApiClient` methods instead so the VM is testable with
   `MockApiClient` and the fake client provides a working offline
   implementation. `SupabaseClient` in VMs is allowed only for auth
   operations (`signUp`, `verifyOTP`, `signInWithPassword`, `resend`,
   `currentUser`).

---

## When to use a sheet (`showAdaptiveSheet`)

Sheets are reserved for exactly two cases:

1. **Destructive confirmation** — "Are you sure you want to cancel this invitation?" with OK / Cancel buttons and nothing else.
2. **Minimal info display** — at most 4 labelled fields shown read-only: e.g. name, date, status, one more. No actions beyond close.

If the content needs actions, a list, a form, or more than four fields → make a screen instead.

`showAdaptiveSheet` renders a bottom sheet on narrow screens (<640 px) and a centred dialog on wide screens (≥640 px). Never call `showModalBottomSheet` or `showDialog` directly; always go through `showAdaptiveSheet`.

---

## Data passing via GoRouter `extra`

Detail routes receive their primary model object through `state.extra` to avoid a second network round-trip on the initial render. Deep-link / URL-only navigation (no extra) requires the screen to load from path parameters — implement that only when deep linking is actually needed.

---

## State management

- ViewModels extend `ChangeNotifier`; screens use `ListenableBuilder`.
- No Riverpod, Bloc, or GetX.
- DI is manual constructor injection; the router owns all `ApiClient` / `AuthService` instances and passes them down.
- Ephemeral UI state (spinners, input values) lives in the widget with `StatefulWidget`; app-level state lives in the VM.

---

## Adaptive layout

- **Navigation breakpoint:** 640 px — `NavigationBar` below, `NavigationRail` at or above.
- **Content breakpoint:** `AdaptiveLayout` centres content at 840 px; caps at 1920 px.
- Bottom sheet / dialog switch: `showAdaptiveSheet` at 640 px.

---

## Code conventions

| Concern | Convention |
| --- | --- |
| File names | `snake_case.dart` |
| Widget / class names | `PascalCase` |
| Private widgets | `_` prefix, defined at the bottom of the file that owns them |
| Shared widgets used across 2+ screens | Public class in a dedicated `*_widgets.dart` file in the same feature folder |
| l10n | All user-visible strings in `app_en.arb` + `app_da.arb`; run `flutter gen-l10n` after edits |
| Logging | `dart:developer` `log()` only; no `print` |
| Null safety | No `!` operator; use `?` and flow analysis |
