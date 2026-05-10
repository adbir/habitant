# Habitant

A Flutter app for housing administration. Tenants report maintenance issues; staff triage, assign, and resolve them.

---

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend / database | Supabase (PostgreSQL + PostgREST + Auth + Storage) |
| Navigation | go_router |
| State management | ChangeNotifier / MVVM |
| Image upload | flutter_image_compress → WebP → Supabase Storage |

---

## Running locally

### Prerequisites

- Flutter SDK (stable channel)
- A Supabase project (or use the fake client — see below)

### 1. Install dependencies

```sh
flutter pub get
```

### 2. Add Supabase credentials

Create `lib/core/supabase_config.dart` (git-ignored):

```dart
const supabaseUrl = 'https://<your-ref>.supabase.co';
const supabaseAnonKey = '<your-anon-key>';
```

### 3. Run

```sh
flutter run
```

In **debug mode** the app uses `FakeApiClient` — no Supabase connection needed. In release mode it uses `SupabaseApiClient`.

---

## Dev credentials

All passwords are `password`. These accounts are seeded in the Supabase database and mirrored in `FakeApiClient`.

| Email | Role | Notes |
|---|---|---|
| `lars@example.com` | Tenant | Onboarded, 3 issues |
| `maria@example.com` | Tenant | Onboarded, 1 issue |
| `peter@example.com` | Tenant | Not onboarded (tests signup flow) |
| `admin@aab.dk` | Admin | Access to both housings |
| `tech@aab.dk` | Maintenance staff | Access to both housings |

---

## Project structure

```
lib/
├── core/
│   ├── models/          # Immutable data classes (Issue, TenantProfile, …)
│   ├── services/        # ApiClient, AuthService, SupabaseApiClient
│   └── widgets/         # Shared UI components
├── dev/
│   └── fake_api_client.dart   # Offline fake backend for debug builds
├── features/
│   ├── auth/            # Login + 4-step signup wizard
│   ├── maintenance/     # Staff dashboard and issue detail
│   └── tenant/          # Tenant home, issue list, report issue
└── l10n/                # Localisation (EN + DA)

supabase/
├── migrations/          # Schema, RLS policies (applied via supabase db push)
├── seed.sql             # Housing and address data
└── seed_users.sql       # Staff and tenant rows (auth users created separately)
```

---

## Architecture

Each screen has a paired ViewModel (`ChangeNotifier`) that owns business logic and API calls. The screen listens with `ListenableBuilder` and rebuilds on state changes. Dependencies are passed down via constructor injection — no global state or service locator.

```
Screen → ViewModel → ApiClient (interface)
                          ↑
              FakeApiClient (debug)
              SupabaseApiClient (release)
```

`AuthService` listens to Supabase's auth state stream and exposes `isAuthenticated`, `role`, and `tenantId`. `GoRouter` uses `AuthService` as its `refreshListenable` and redirects automatically on login/logout.

### Photo upload flow

Photos are converted to WebP and uploaded to Supabase Storage immediately when selected — not on form submit. By the time the user finishes writing their description and taps Submit, the upload is already done. Submit waits for any remaining in-progress uploads before creating the issue row.

---

## Supabase setup

### Apply migrations

```sh
npx supabase link --project-ref <ref>
npx supabase db push
```

### Seed data

```sh
# Housing + addresses
npx supabase db query --linked --file supabase/seed.sql

# Create auth users first (Admin API or Supabase dashboard),
# then insert profile rows:
npx supabase db query --linked --file supabase/seed_users.sql
```

### Storage

The `issue-photos` bucket must exist with public read and authenticated write scoped to each user's folder (`<user-id>/<filename>`). The bucket and its RLS policies are created by running the SQL in the migrations.

---

## Database schema

### Tables at a glance

| Table | Description |
|---|---|
| `housing` | Housing estates / complexes |
| `address` | Individual dwelling units within a housing |
| `staff_user` | All staff accounts (admin, housing manager, maintenance) |
| `staff_housing_access` | Which housing complexes a staff user can access |
| `tenant` | Tenant accounts |
| `tenancy_record` | Historical tenancy periods per address |
| `issue` | Maintenance issues reported by tenants |
| `issue_photo` | Photos submitted with an issue |
| `issue_comment` | Staff comments on issues (private or public) |
| `maintenance_update` | Work-completion records logged by maintenance staff |
| `maintenance_update_photo` | Proof photos attached to a maintenance update |

### Conventions

| Convention | Rule |
|---|---|
| Primary keys | `UUID`, generated with `gen_random_uuid()` |
| `created` | Set once at insert, never changed |
| `modified` | Auto-updated by trigger on every `UPDATE` |
| `<table>_flags` | `BIGINT` bitmask — replaces individual boolean columns |
| Timestamps | `TIMESTAMPTZ` (always UTC) |
| Identifiers | `snake_case` throughout |

Authentication is handled entirely by Supabase Auth. Application tables never store password material. `tenant.tenant_id` and `staff_user.staff_user_id` are primary keys equal to `auth.users.id`.

### Flags reference

| Table | Bit | Meaning |
|---|---|---|
| `address` | 0 | `is_occupied` |
| `tenant` | 0 | `is_onboarded` |
| `issue` | 0 | `needs_assistance` |
| `issue_comment` | 0 | `is_private` (hidden from tenant) |

### Enum reference

**`user_role`:** `root_admin` · `admin` · `housing_manager` · `maintenance_staff`

**`issue_status`:** `pending` → `assigned` → `in_progress` → `completed` / `rejected`

### Entity relationships

```
housing ──< address ──< tenancy_record >── tenant
               │
               └──< issue ──< issue_photo
                        │──< issue_comment
                        └──< maintenance_update ──< maintenance_update_photo

staff_user >──< staff_housing_access >── housing
staff_user ──────────────────────────── issue.maintenance_staff_id
staff_user ──────────────────────────── issue_comment.author_id
staff_user ──────────────────────────── maintenance_update.maintenance_staff_id
```
