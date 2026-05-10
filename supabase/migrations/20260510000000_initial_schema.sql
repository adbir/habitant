-- ============================================================
-- Shared types & trigger
-- ============================================================

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

CREATE OR REPLACE FUNCTION set_modified()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.modified = NOW();
  RETURN NEW;
END;
$$;

-- ============================================================
-- housing
-- ============================================================

CREATE TABLE housing (
  housing_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name          TEXT        NOT NULL,
  city          TEXT        NOT NULL,
  created       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  housing_flags BIGINT      NOT NULL DEFAULT 0
);

CREATE TRIGGER trg_housing_modified
  BEFORE UPDATE ON housing
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- address
-- ============================================================

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

-- ============================================================
-- staff_user  (PK = auth.users.id — no password stored here)
-- ============================================================

CREATE TABLE staff_user (
  staff_user_id    UUID        NOT NULL PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email            TEXT        NOT NULL UNIQUE,
  name             TEXT        NOT NULL,
  first_name       VARCHAR(64) NOT NULL,
  role             user_role   NOT NULL,
  created          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  staff_user_flags BIGINT      NOT NULL DEFAULT 0
);

CREATE TRIGGER trg_staff_user_modified
  BEFORE UPDATE ON staff_user
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- staff_housing_access
-- ============================================================

CREATE TABLE staff_housing_access (
  staff_housing_access_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  staff_user_id              UUID        NOT NULL REFERENCES staff_user (staff_user_id),
  housing_id                 UUID        NOT NULL REFERENCES housing (housing_id),
  staff_housing_access_flags BIGINT      NOT NULL DEFAULT 0,
  UNIQUE (staff_user_id, housing_id)
);

CREATE INDEX idx_sha_staff   ON staff_housing_access (staff_user_id);
CREATE INDEX idx_sha_housing ON staff_housing_access (housing_id);

CREATE TRIGGER trg_staff_housing_access_modified
  BEFORE UPDATE ON staff_housing_access
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- tenant  (PK = auth.users.id — no password stored here)
-- ============================================================

CREATE TABLE tenant (
  tenant_id          UUID        NOT NULL PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email              TEXT        NOT NULL UNIQUE,
  phone_number       VARCHAR(32),
  created            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_housing_id UUID        REFERENCES housing (housing_id),
  current_address_id UUID        REFERENCES address (address_id),
  tenant_flags       BIGINT      NOT NULL DEFAULT 0
);

CREATE TRIGGER trg_tenant_modified
  BEFORE UPDATE ON tenant
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- tenancy_record
-- ============================================================

CREATE TABLE tenancy_record (
  tenancy_record_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  moved_in_at          TIMESTAMPTZ NOT NULL,
  moved_out_at         TIMESTAMPTZ,
  created              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  address_id           UUID        NOT NULL REFERENCES address (address_id),
  tenant_id            UUID        NOT NULL REFERENCES tenant (tenant_id),
  tenancy_record_flags BIGINT      NOT NULL DEFAULT 0
);

CREATE INDEX idx_tenancy_address ON tenancy_record (address_id);
CREATE INDEX idx_tenancy_tenant  ON tenancy_record (tenant_id);

CREATE TRIGGER trg_tenancy_record_modified
  BEFORE UPDATE ON tenancy_record
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- issue
-- ============================================================

CREATE TABLE issue (
  issue_id                  UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description               TEXT         NOT NULL,
  status                    issue_status NOT NULL DEFAULT 'pending',
  alternative_contact_phone VARCHAR(32),
  created                   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  modified                  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  tenant_id                 UUID         NOT NULL REFERENCES tenant (tenant_id),
  address_id                UUID         NOT NULL REFERENCES address (address_id),
  maintenance_staff_id      UUID         REFERENCES staff_user (staff_user_id),
  issue_flags               BIGINT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_issue_tenant  ON issue (tenant_id);
CREATE INDEX idx_issue_address ON issue (address_id);
CREATE INDEX idx_issue_status  ON issue (status);

CREATE TRIGGER trg_issue_modified
  BEFORE UPDATE ON issue
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- issue_photo
-- ============================================================

CREATE TABLE issue_photo (
  issue_photo_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  url               TEXT        NOT NULL,
  created           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  issue_id          UUID        NOT NULL REFERENCES issue (issue_id) ON DELETE CASCADE,
  issue_photo_flags BIGINT      NOT NULL DEFAULT 0
);

CREATE INDEX idx_issue_photo_issue ON issue_photo (issue_id);

CREATE TRIGGER trg_issue_photo_modified
  BEFORE UPDATE ON issue_photo
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- issue_comment
-- ============================================================

CREATE TABLE issue_comment (
  issue_comment_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  body                TEXT        NOT NULL,
  created             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  issue_id            UUID        NOT NULL REFERENCES issue (issue_id) ON DELETE CASCADE,
  author_id           UUID        NOT NULL REFERENCES staff_user (staff_user_id),
  issue_comment_flags BIGINT      NOT NULL DEFAULT 0
);

CREATE INDEX idx_issue_comment_issue ON issue_comment (issue_id);

CREATE TRIGGER trg_issue_comment_modified
  BEFORE UPDATE ON issue_comment
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- maintenance_update
-- ============================================================

CREATE TABLE maintenance_update (
  maintenance_update_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description              TEXT        NOT NULL,
  completed_at             TIMESTAMPTZ NOT NULL,
  created                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  issue_id                 UUID        NOT NULL REFERENCES issue (issue_id) ON DELETE CASCADE,
  maintenance_staff_id     UUID        NOT NULL REFERENCES staff_user (staff_user_id),
  maintenance_update_flags BIGINT      NOT NULL DEFAULT 0
);

CREATE INDEX idx_maintenance_update_issue ON maintenance_update (issue_id);

CREATE TRIGGER trg_maintenance_update_modified
  BEFORE UPDATE ON maintenance_update
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- maintenance_update_photo
-- ============================================================

CREATE TABLE maintenance_update_photo (
  maintenance_update_photo_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  url                            TEXT        NOT NULL,
  created                        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified                       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  maintenance_update_id          UUID        NOT NULL REFERENCES maintenance_update (maintenance_update_id) ON DELETE CASCADE,
  maintenance_update_photo_flags BIGINT      NOT NULL DEFAULT 0
);

CREATE INDEX idx_mu_photo_update ON maintenance_update_photo (maintenance_update_id);

CREATE TRIGGER trg_maintenance_update_photo_modified
  BEFORE UPDATE ON maintenance_update_photo
  FOR EACH ROW EXECUTE FUNCTION set_modified();

-- ============================================================
-- Read-only views
-- ============================================================

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
  s.first_name        AS assigned_to_name,
  i.issue_flags
FROM issue i
JOIN      address    a ON a.address_id    = i.address_id
LEFT JOIN staff_user s ON s.staff_user_id = i.maintenance_staff_id;

CREATE VIEW v_issue_comment AS
SELECT
  ic.issue_comment_id,
  ic.body,
  ic.created,
  ic.modified,
  ic.issue_id,
  ic.author_id,
  s.name              AS author_name,
  ic.issue_comment_flags
FROM issue_comment ic
JOIN staff_user s ON s.staff_user_id = ic.author_id;

CREATE VIEW v_maintenance_update AS
SELECT
  mu.maintenance_update_id,
  mu.description,
  mu.completed_at,
  mu.created,
  mu.modified,
  mu.issue_id,
  mu.maintenance_staff_id,
  s.name              AS staff_name,
  mu.maintenance_update_flags
FROM maintenance_update mu
JOIN staff_user s ON s.staff_user_id = mu.maintenance_staff_id;

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
  a.city              AS address_city,
  h.name              AS housing_name,
  s.first_name        AS assigned_to_name,
  s.name              AS assigned_to_full_name
FROM issue i
JOIN      address    a ON a.address_id    = i.address_id
JOIN      housing    h ON h.housing_id    = a.housing_id
LEFT JOIN staff_user s ON s.staff_user_id = i.maintenance_staff_id;
