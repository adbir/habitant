# Beboer App — API & Database Reference

This document is for the backend developer. It covers the full PostgreSQL schema — one table per section, with a column breakdown and the `CREATE` SQL — plus read-only views, flag bits, and enum values.

---

## Table of Contents

1. [Conventions](#conventions)
2. [Tables at a Glance](#tables-at-a-glance)
3. [Shared Types & Trigger](#shared-types--trigger)
4. [Tables](#tables)
   - [housing](#housing)
   - [address](#address)
   - [staff_user](#staff_user)
   - [staff_housing_access](#staff_housing_access)
   - [tenant](#tenant)
   - [tenancy_record](#tenancy_record)
   - [issue](#issue)
   - [issue_photo](#issue_photo)
   - [issue_comment](#issue_comment)
   - [maintenance_update](#maintenance_update)
   - [maintenance_update_photo](#maintenance_update_photo)
5. [Read-only Views](#read-only-views)
   - [v_issue](#v_issue)
   - [v_issue_comment](#v_issue_comment)
   - [v_maintenance_update](#v_maintenance_update)
   - [v_issue_detail](#v_issue_detail)
6. [Flags Reference](#flags-reference)
7. [Enum Reference](#enum-reference)
8. [Entity Relationship Summary](#entity-relationship-summary)

---

## Conventions

| Convention | Rule |
|---|---|
| Primary keys | `UUID`, generated with `gen_random_uuid()` |
| `created` | Set once at insert, never changed |
| `modified` | Auto-updated by trigger on every `UPDATE` |
| `<table>_flags` | `BIGINT` bitmask — replaces individual boolean columns. Bits documented in [Flags Reference](#flags-reference) |
| Timestamps | `TIMESTAMPTZ` (always UTC) |
| Enums | Defined as PostgreSQL `TYPE` |
| Identifiers | `snake_case` throughout |
| Derived data | Never stored in base tables. Use the read-only views below to join across tables |

**Column order within every table:**

```
<table>_id        — primary key
[data columns]    — the fields that belong to this entity
created
modified
[foreign keys]    — one per referenced table
<table>_flags     — always last
```

Authentication is JWT-based. The `sub` claim in the token holds the user's UUID. Both `tenant` and `staff_user` tables store a `password_hash`; the API is responsible for issuing tokens after credential verification.

---

## Tables at a Glance

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

---

## Shared Types & Trigger

Run these once before creating any tables.

```sql
-- Enums
CREATE TYPE user_role AS ENUM (
  'root_admin',
  'admin',
  'housing_manager',
  'maintenance_staff'
);

CREATE TYPE issue_status AS ENUM (
  'pending',
  'assigned',
  'in_progress',
  'completed',
  'rejected'
);

-- Auto-update trigger function (applied per table below)
CREATE OR REPLACE FUNCTION set_modified()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.modified = NOW();
  RETURN NEW;
END;
$$;
```

---

## Tables

### `housing`

Housing estates / complexes. Each housing has one or more addresses.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `housing_id` | `UUID` | NO | Primary key |
| `name` | `TEXT` | NO | Display name, e.g. "Rentemestervej Boligforening" |
| `city` | `TEXT` | NO | City for display grouping |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `housing_flags` | `BIGINT` | NO | See flags reference |

```sql
CREATE TABLE housing (
  housing_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name          TEXT         NOT NULL,
  city          TEXT         NOT NULL,
  created       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  housing_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE TRIGGER trg_housing_modified
  BEFORE UPDATE ON housing
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `address`

A single dwelling unit within a `housing`. Models the Danish address format
(street + number + floor + side).

| Column | Type | Nullable | Description |
|---|---|---|---|
| `address_id` | `UUID` | NO | Primary key |
| `street` | `TEXT` | NO | Street name |
| `number` | `VARCHAR(16)` | NO | Street number |
| `floor` | `VARCHAR(8)` | YES | `"st"` (ground), `"kl"` (basement), `"1"`, `"2"`, … |
| `side` | `VARCHAR(8)` | YES | `"tv"` (left), `"th"` (right), `"mf"` (middle) |
| `postal_code` | `VARCHAR(10)` | NO | Danish postal code |
| `city` | `TEXT` | NO | |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `housing_id` | `UUID` | NO | FK → `housing` |
| `address_flags` | `BIGINT` | NO | Bit 0: `is_occupied` |

```sql
CREATE TABLE address (
  address_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  street        TEXT         NOT NULL,
  number        VARCHAR(16)  NOT NULL,
  floor         VARCHAR(8),
  side          VARCHAR(8),
  postal_code   VARCHAR(10)  NOT NULL,
  city          TEXT         NOT NULL,
  created       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  housing_id    UUID         NOT NULL REFERENCES housing (housing_id),
  address_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_address_housing ON address (housing_id);

CREATE TRIGGER trg_address_modified
  BEFORE UPDATE ON address
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `staff_user`

All staff accounts. `role` determines API access and what the app shows.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `staff_user_id` | `UUID` | NO | Primary key |
| `email` | `TEXT` | NO | Unique login email |
| `name` | `TEXT` | NO | Full display name |
| `first_name` | `VARCHAR(64)` | NO | Shown to tenants on assigned issues |
| `role` | `user_role` | NO | Enum — see [Enum Reference](#enum-reference) |
| `password_hash` | `TEXT` | NO | `argon2id` or `bcrypt` hash |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `staff_user_flags` | `BIGINT` | NO | Bit 0: `is_active` |

```sql
CREATE TABLE staff_user (
  staff_user_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email            TEXT         NOT NULL UNIQUE,
  name             TEXT         NOT NULL,
  first_name       VARCHAR(64)  NOT NULL,
  role             user_role    NOT NULL,
  password_hash    TEXT         NOT NULL,
  created          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  staff_user_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE TRIGGER trg_staff_user_modified
  BEFORE UPDATE ON staff_user
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `staff_housing_access`

Which housing complexes a staff user can access. Admins and root admins
typically cover all; maintenance staff are scoped to specific ones.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `staff_housing_access_id` | `UUID` | NO | Primary key |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `staff_user_id` | `UUID` | NO | FK → `staff_user` |
| `housing_id` | `UUID` | NO | FK → `housing` |
| `staff_housing_access_flags` | `BIGINT` | NO | Reserved |

```sql
CREATE TABLE staff_housing_access (
  staff_housing_access_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created                    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified                   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  staff_user_id              UUID         NOT NULL REFERENCES staff_user (staff_user_id),
  housing_id                 UUID         NOT NULL REFERENCES housing (housing_id),
  staff_housing_access_flags BIGINT       NOT NULL DEFAULT 0,
  UNIQUE (staff_user_id, housing_id)
);

CREATE INDEX idx_sha_staff   ON staff_housing_access (staff_user_id);
CREATE INDEX idx_sha_housing ON staff_housing_access (housing_id);

CREATE TRIGGER trg_staff_housing_access_modified
  BEFORE UPDATE ON staff_housing_access
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `tenant`

Tenant accounts. A tenant selects their housing and address after first login
(onboarding). Until then, `current_housing_id` and `current_address_id` are
null.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `tenant_id` | `UUID` | NO | Primary key |
| `email` | `TEXT` | NO | Unique login email |
| `phone_number` | `VARCHAR(32)` | YES | Contact number supplied at signup |
| `password_hash` | `TEXT` | NO | `argon2id` or `bcrypt` hash |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `current_housing_id` | `UUID` | YES | FK → `housing`; null until onboarded |
| `current_address_id` | `UUID` | YES | FK → `address`; null until onboarded |
| `tenant_flags` | `BIGINT` | NO | Bit 0: `is_onboarded` |

```sql
CREATE TABLE tenant (
  tenant_id          UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email              TEXT         NOT NULL UNIQUE,
  phone_number       VARCHAR(32),
  password_hash      TEXT         NOT NULL,
  created            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  current_housing_id UUID         REFERENCES housing (housing_id),
  current_address_id UUID         REFERENCES address (address_id),
  tenant_flags       BIGINT       NOT NULL DEFAULT 0
);

CREATE TRIGGER trg_tenant_modified
  BEFORE UPDATE ON tenant
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `tenancy_record`

Historical record of each tenant's stay at an address. Used by admins to audit
issue history across tenancies (e.g. was the mold fixed before the next tenant
moved in?).

| Column | Type | Nullable | Description |
|---|---|---|---|
| `tenancy_record_id` | `UUID` | NO | Primary key |
| `moved_in_at` | `TIMESTAMPTZ` | NO | Start of tenancy |
| `moved_out_at` | `TIMESTAMPTZ` | YES | End of tenancy; `NULL` = currently active |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `address_id` | `UUID` | NO | FK → `address` |
| `tenant_id` | `UUID` | NO | FK → `tenant` |
| `tenancy_record_flags` | `BIGINT` | NO | Reserved |

```sql
CREATE TABLE tenancy_record (
  tenancy_record_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  moved_in_at          TIMESTAMPTZ  NOT NULL,
  moved_out_at         TIMESTAMPTZ,
  created              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  address_id           UUID         NOT NULL REFERENCES address (address_id),
  tenant_id            UUID         NOT NULL REFERENCES tenant (tenant_id),
  tenancy_record_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_tenancy_address ON tenancy_record (address_id);
CREATE INDEX idx_tenancy_tenant  ON tenancy_record (tenant_id);

CREATE TRIGGER trg_tenancy_record_modified
  BEFORE UPDATE ON tenancy_record
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `issue`

A maintenance issue reported by a tenant.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `issue_id` | `UUID` | NO | Primary key |
| `description` | `TEXT` | NO | Free-text description from tenant |
| `status` | `issue_status` | NO | Current workflow state; see [Enum Reference](#enum-reference) |
| `alternative_contact_phone` | `VARCHAR(32)` | YES | Alt. contact for the visit |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `tenant_id` | `UUID` | NO | FK → `tenant` (reporter) |
| `address_id` | `UUID` | NO | FK → `address` |
| `maintenance_staff_id` | `UUID` | YES | FK → `staff_user`; set when assigned |
| `issue_flags` | `BIGINT` | NO | Bit 0: `needs_assistance` |

> `housing_id` and `assigned_to_name` are not stored here. Use [`v_issue`](#v_issue) to get both via join.

```sql
CREATE TABLE issue (
  issue_id                  UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description               TEXT          NOT NULL,
  status                    issue_status  NOT NULL DEFAULT 'pending',
  alternative_contact_phone VARCHAR(32),
  created                   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  modified                  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  tenant_id                 UUID          NOT NULL REFERENCES tenant (tenant_id),
  address_id                UUID          NOT NULL REFERENCES address (address_id),
  maintenance_staff_id      UUID          REFERENCES staff_user (staff_user_id),
  issue_flags               BIGINT        NOT NULL DEFAULT 0
);

CREATE INDEX idx_issue_tenant  ON issue (tenant_id);
CREATE INDEX idx_issue_address ON issue (address_id);
CREATE INDEX idx_issue_status  ON issue (status);

CREATE TRIGGER trg_issue_modified
  BEFORE UPDATE ON issue
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `issue_photo`

Photos submitted by the tenant when reporting an issue. Stored as object
storage URLs (S3-compatible or similar).

| Column | Type | Nullable | Description |
|---|---|---|---|
| `issue_photo_id` | `UUID` | NO | Primary key |
| `url` | `TEXT` | NO | Object storage URL |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `issue_id` | `UUID` | NO | FK → `issue` |
| `issue_photo_flags` | `BIGINT` | NO | Reserved |

```sql
CREATE TABLE issue_photo (
  issue_photo_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  url               TEXT         NOT NULL,
  created           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  issue_id          UUID         NOT NULL REFERENCES issue (issue_id) ON DELETE CASCADE,
  issue_photo_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_issue_photo_issue ON issue_photo (issue_id);

CREATE TRIGGER trg_issue_photo_modified
  BEFORE UPDATE ON issue_photo
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `issue_comment`

Comments left by staff on an issue. Private comments (`is_private` flag set)
are hidden from the tenant and visible only to admin and maintenance staff.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `issue_comment_id` | `UUID` | NO | Primary key |
| `body` | `TEXT` | NO | Comment text |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `issue_id` | `UUID` | NO | FK → `issue` |
| `author_id` | `UUID` | NO | FK → `staff_user` |
| `issue_comment_flags` | `BIGINT` | NO | Bit 0: `is_private` |

> `author_name` is not stored here. Use [`v_issue_comment`](#v_issue_comment) to get it via join.

```sql
CREATE TABLE issue_comment (
  issue_comment_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  body                TEXT         NOT NULL,
  created             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  issue_id            UUID         NOT NULL REFERENCES issue (issue_id) ON DELETE CASCADE,
  author_id           UUID         NOT NULL REFERENCES staff_user (staff_user_id),
  issue_comment_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_issue_comment_issue ON issue_comment (issue_id);

CREATE TRIGGER trg_issue_comment_modified
  BEFORE UPDATE ON issue_comment
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `maintenance_update`

A work-completion record logged by a maintenance worker after visiting the
address.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `maintenance_update_id` | `UUID` | NO | Primary key |
| `description` | `TEXT` | NO | What was done |
| `completed_at` | `TIMESTAMPTZ` | NO | When the work was completed |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `issue_id` | `UUID` | NO | FK → `issue` |
| `maintenance_staff_id` | `UUID` | NO | FK → `staff_user` (who did the work) |
| `maintenance_update_flags` | `BIGINT` | NO | Reserved |

```sql
CREATE TABLE maintenance_update (
  maintenance_update_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description              TEXT         NOT NULL,
  completed_at             TIMESTAMPTZ  NOT NULL,
  created                  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified                 TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  issue_id                 UUID         NOT NULL REFERENCES issue (issue_id) ON DELETE CASCADE,
  maintenance_staff_id     UUID         NOT NULL REFERENCES staff_user (staff_user_id),
  maintenance_update_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_maintenance_update_issue ON maintenance_update (issue_id);

CREATE TRIGGER trg_maintenance_update_modified
  BEFORE UPDATE ON maintenance_update
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

### `maintenance_update_photo`

Proof photos attached to a maintenance update.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `maintenance_update_photo_id` | `UUID` | NO | Primary key |
| `url` | `TEXT` | NO | Object storage URL |
| `created` | `TIMESTAMPTZ` | NO | |
| `modified` | `TIMESTAMPTZ` | NO | |
| `maintenance_update_id` | `UUID` | NO | FK → `maintenance_update` |
| `maintenance_update_photo_flags` | `BIGINT` | NO | Reserved |

```sql
CREATE TABLE maintenance_update_photo (
  maintenance_update_photo_id    UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  url                            TEXT         NOT NULL,
  created                        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified                       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  maintenance_update_id          UUID         NOT NULL REFERENCES maintenance_update (maintenance_update_id) ON DELETE CASCADE,
  maintenance_update_photo_flags BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_mu_photo_update ON maintenance_update_photo (maintenance_update_id);

CREATE TRIGGER trg_maintenance_update_photo_modified
  BEFORE UPDATE ON maintenance_update_photo
  FOR EACH ROW EXECUTE FUNCTION set_modified();
```

---

## Read-only Views

The API should query these views rather than base tables wherever joined data
is needed. Base tables stay normalized; the views present the same shape the
app expects in JSON.

---

### `v_issue`

Enriches `issue` with the housing it belongs to (via `address`) and the first
name of the assigned worker (via `staff_user`).

```sql
CREATE VIEW v_issue AS
SELECT
  i.issue_id,
  i.description,
  i.status,
  i.alternative_contact_phone,
  i.created,
  i.modified,
  i.tenant_id,
  i.address_id,
  a.housing_id,
  i.maintenance_staff_id,
  s.first_name           AS assigned_to_name,
  i.issue_flags
FROM issue i
JOIN      address    a ON a.address_id    = i.address_id
LEFT JOIN staff_user s ON s.staff_user_id = i.maintenance_staff_id;
```

**Typical usage:**

```sql
-- All open issues for a housing complex, newest first
SELECT * FROM v_issue
WHERE housing_id = $1
  AND status NOT IN ('completed', 'rejected')
ORDER BY created DESC;

-- All issues for a tenant
SELECT * FROM v_issue
WHERE tenant_id = $1
ORDER BY created DESC;
```

---

### `v_issue_comment`

Enriches `issue_comment` with the author's display name from `staff_user`.

```sql
CREATE VIEW v_issue_comment AS
SELECT
  ic.issue_comment_id,
  ic.body,
  ic.created,
  ic.modified,
  ic.issue_id,
  ic.author_id,
  s.name                 AS author_name,
  ic.issue_comment_flags
FROM issue_comment ic
JOIN staff_user s ON s.staff_user_id = ic.author_id;
```

**Typical usage:**

```sql
-- Public comments for a tenant-facing detail screen
SELECT * FROM v_issue_comment
WHERE issue_id = $1
  AND (issue_comment_flags & 1) = 0
ORDER BY created;

-- All comments for a staff detail screen
SELECT * FROM v_issue_comment
WHERE issue_id = $1
ORDER BY created;
```

---

### `v_maintenance_update`

Enriches `maintenance_update` with the worker's display name.

```sql
CREATE VIEW v_maintenance_update AS
SELECT
  mu.maintenance_update_id,
  mu.description,
  mu.completed_at,
  mu.created,
  mu.modified,
  mu.issue_id,
  mu.maintenance_staff_id,
  s.name                 AS staff_name,
  mu.maintenance_update_flags
FROM maintenance_update mu
JOIN staff_user s ON s.staff_user_id = mu.maintenance_staff_id;
```

---

### `v_issue_detail`

Full single-issue view used by the staff detail screen. Returns one row per
issue and joins address, housing, and assigned worker in a single query.

```sql
CREATE VIEW v_issue_detail AS
SELECT
  i.issue_id,
  i.description,
  i.status,
  i.alternative_contact_phone,
  i.created,
  i.modified,
  i.tenant_id,
  i.address_id,
  i.maintenance_staff_id,
  i.issue_flags,
  a.housing_id,
  a.street,
  a.number,
  a.floor,
  a.side,
  a.postal_code,
  a.city                  AS address_city,
  h.name                  AS housing_name,
  s.first_name            AS assigned_to_name,
  s.name                  AS assigned_to_full_name
FROM issue i
JOIN      address    a ON a.address_id    = i.address_id
JOIN      housing    h ON h.housing_id    = a.housing_id
LEFT JOIN staff_user s ON s.staff_user_id = i.maintenance_staff_id;
```

**Typical usage:**

```sql
-- Fetch everything needed to render the issue detail screen
SELECT * FROM v_issue_detail WHERE issue_id = $1;
```

---

## Flags Reference

Each `_flags` column is a `BIGINT` bitmask. Only the bits defined below are in
use; all others are reserved and must be left as `0`.

| Table | Bit | Mask | Meaning |
|---|---|---|---|
| `address` | 0 | `0x01` | `is_occupied` — address currently has an active tenant |
| `staff_user` | 0 | `0x01` | `is_active` — account is enabled; disabled accounts cannot log in |
| `tenant` | 0 | `0x01` | `is_onboarded` — tenant has selected housing and address |
| `issue` | 0 | `0x01` | `needs_assistance` — admin has flagged as requiring extra support |
| `issue_comment` | 0 | `0x01` | `is_private` — hidden from tenant; visible to staff only |

**Example queries:**

```sql
-- Occupied addresses
SELECT * FROM address WHERE (address_flags & 1) = 1;

-- Active staff accounts only
SELECT * FROM staff_user WHERE (staff_user_flags & 1) = 1;

-- Issues flagged for assistance
SELECT * FROM v_issue WHERE (issue_flags & 1) = 1;

-- Public comments (tenant-visible)
SELECT * FROM v_issue_comment
WHERE issue_id = $1
  AND (issue_comment_flags & 1) = 0
ORDER BY created;

-- Private (staff-only) comments
SELECT * FROM v_issue_comment
WHERE issue_id = $1
  AND (issue_comment_flags & 1) = 1
ORDER BY created;
```

---

## Enum Reference

### `user_role`

| Value | Who | Access |
|---|---|---|
| `root_admin` | System owner | Everything |
| `admin` | Property manager | Manages housing, assigns issues, sees all comments |
| `housing_manager` | On-site manager | Scoped to assigned housing complexes |
| `maintenance_staff` | Technician / worker | Scoped to assigned housing; logs updates and comments |

### `issue_status`

| Value | Meaning | Typical transition |
|---|---|---|
| `pending` | Submitted, not yet reviewed | → `assigned` or `rejected` |
| `assigned` | Assigned to a worker | → `in_progress` |
| `in_progress` | Worker has started | → `completed` |
| `completed` | Work is done | (terminal) |
| `rejected` | Issue dismissed | (terminal) |

---

## Entity Relationship Summary

```
housing ──< address ──< tenancy_record >── tenant
               │
               └──< issue ──< issue_photo
                        │──< issue_comment
                        └──< maintenance_update ──< maintenance_update_photo
                                  │
staff_user >──< staff_housing_access >── housing
staff_user ────────────────────────────> issue (maintenance_staff_id)
staff_user ────────────────────────────> issue_comment (author_id)
staff_user ────────────────────────────> maintenance_update (maintenance_staff_id)
```
