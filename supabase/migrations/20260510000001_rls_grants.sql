-- ============================================================
-- Schema access
-- ============================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- anon: public lookup tables only (signup housing/address picker)
GRANT SELECT ON housing TO anon;
GRANT SELECT ON address TO anon;

-- authenticated: all tables they may interact with
-- RLS policies below control what each user can actually see/do.
GRANT SELECT                    ON housing                    TO authenticated;
GRANT SELECT                    ON address                    TO authenticated;
GRANT SELECT, INSERT, UPDATE    ON tenant                     TO authenticated;
GRANT SELECT                    ON tenancy_record             TO authenticated;
GRANT SELECT, INSERT, UPDATE    ON issue                      TO authenticated;
GRANT SELECT, INSERT            ON issue_photo                TO authenticated;
GRANT SELECT, INSERT            ON issue_comment              TO authenticated;
GRANT SELECT                    ON staff_user                 TO authenticated;
GRANT SELECT                    ON staff_housing_access       TO authenticated;
GRANT SELECT, INSERT            ON maintenance_update         TO authenticated;
GRANT SELECT, INSERT            ON maintenance_update_photo   TO authenticated;

-- ============================================================
-- Enable RLS on every table in the public schema
-- ============================================================

ALTER TABLE housing                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE address                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_user               ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_housing_access     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenancy_record           ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_photo              ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_comment            ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_update       ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_update_photo ENABLE ROW LEVEL SECURITY;

-- Views run as the calling user so the underlying RLS applies
ALTER VIEW v_issue              SET (security_invoker = on);
ALTER VIEW v_issue_comment      SET (security_invoker = on);
ALTER VIEW v_maintenance_update SET (security_invoker = on);
ALTER VIEW v_issue_detail       SET (security_invoker = on);

-- ============================================================
-- housing — readable by everyone (signup + navigation)
-- ============================================================

CREATE POLICY "housing_select_all"
  ON housing FOR SELECT USING (true);

-- ============================================================
-- address — readable by everyone (signup address picker)
-- ============================================================

CREATE POLICY "address_select_all"
  ON address FOR SELECT USING (true);

-- ============================================================
-- tenant
-- ============================================================

-- Read own profile
CREATE POLICY "tenant_select_own"
  ON tenant FOR SELECT
  USING (tenant_id = auth.uid());

-- Create own profile row after Supabase Auth signup
CREATE POLICY "tenant_insert_own"
  ON tenant FOR INSERT
  WITH CHECK (tenant_id = auth.uid());

-- Update own profile (onboarding housing/address selection)
CREATE POLICY "tenant_update_own"
  ON tenant FOR UPDATE
  USING (tenant_id = auth.uid());

-- ============================================================
-- tenancy_record
-- ============================================================

CREATE POLICY "tenancy_record_select_tenant"
  ON tenancy_record FOR SELECT
  USING (tenant_id = auth.uid());

CREATE POLICY "tenancy_record_select_staff"
  ON tenancy_record FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM address a
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE a.address_id = tenancy_record.address_id
        AND sha.staff_user_id = auth.uid()
    )
  );

-- ============================================================
-- staff_user
-- ============================================================

CREATE POLICY "staff_user_select_own"
  ON staff_user FOR SELECT
  USING (staff_user_id = auth.uid());

-- ============================================================
-- staff_housing_access
-- ============================================================

CREATE POLICY "sha_select_own"
  ON staff_housing_access FOR SELECT
  USING (staff_user_id = auth.uid());

-- ============================================================
-- issue
-- ============================================================

CREATE POLICY "issue_select_tenant"
  ON issue FOR SELECT
  USING (tenant_id = auth.uid());

CREATE POLICY "issue_insert_tenant"
  ON issue FOR INSERT
  WITH CHECK (tenant_id = auth.uid());

CREATE POLICY "issue_select_staff"
  ON issue FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM address a
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE a.address_id = issue.address_id
        AND sha.staff_user_id = auth.uid()
    )
  );

-- UPDATE also needs a USING clause or it silently returns 0 rows
CREATE POLICY "issue_update_staff"
  ON issue FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM address a
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE a.address_id = issue.address_id
        AND sha.staff_user_id = auth.uid()
    )
  );

-- ============================================================
-- issue_photo
-- ============================================================

CREATE POLICY "issue_photo_select_tenant"
  ON issue_photo FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM issue
      WHERE issue.issue_id = issue_photo.issue_id
        AND issue.tenant_id = auth.uid()
    )
  );

CREATE POLICY "issue_photo_insert_tenant"
  ON issue_photo FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM issue
      WHERE issue.issue_id = issue_photo.issue_id
        AND issue.tenant_id = auth.uid()
    )
  );

CREATE POLICY "issue_photo_select_staff"
  ON issue_photo FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM issue i
      JOIN address a ON a.address_id = i.address_id
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE i.issue_id = issue_photo.issue_id
        AND sha.staff_user_id = auth.uid()
    )
  );

-- ============================================================
-- issue_comment
-- ============================================================

-- Tenants see only public comments (bit 0 = 0) on their own issues
CREATE POLICY "issue_comment_select_tenant"
  ON issue_comment FOR SELECT
  USING (
    (issue_comment_flags & 1) = 0
    AND EXISTS (
      SELECT 1 FROM issue
      WHERE issue.issue_id = issue_comment.issue_id
        AND issue.tenant_id = auth.uid()
    )
  );

-- Staff see all comments (including private) on accessible issues
CREATE POLICY "issue_comment_select_staff"
  ON issue_comment FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM issue i
      JOIN address a ON a.address_id = i.address_id
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE i.issue_id = issue_comment.issue_id
        AND sha.staff_user_id = auth.uid()
    )
  );

CREATE POLICY "issue_comment_insert_staff"
  ON issue_comment FOR INSERT
  WITH CHECK (
    author_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM issue i
      JOIN address a ON a.address_id = i.address_id
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE i.issue_id = issue_comment.issue_id
        AND sha.staff_user_id = auth.uid()
    )
  );

-- ============================================================
-- maintenance_update
-- ============================================================

CREATE POLICY "maintenance_update_select_tenant"
  ON maintenance_update FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM issue
      WHERE issue.issue_id = maintenance_update.issue_id
        AND issue.tenant_id = auth.uid()
    )
  );

CREATE POLICY "maintenance_update_select_staff"
  ON maintenance_update FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM issue i
      JOIN address a ON a.address_id = i.address_id
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE i.issue_id = maintenance_update.issue_id
        AND sha.staff_user_id = auth.uid()
    )
  );

CREATE POLICY "maintenance_update_insert_staff"
  ON maintenance_update FOR INSERT
  WITH CHECK (
    maintenance_staff_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM issue i
      JOIN address a ON a.address_id = i.address_id
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE i.issue_id = maintenance_update.issue_id
        AND sha.staff_user_id = auth.uid()
    )
  );

-- ============================================================
-- maintenance_update_photo
-- ============================================================

CREATE POLICY "mu_photo_select_tenant"
  ON maintenance_update_photo FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM maintenance_update mu
      JOIN issue i ON i.issue_id = mu.issue_id
      WHERE mu.maintenance_update_id = maintenance_update_photo.maintenance_update_id
        AND i.tenant_id = auth.uid()
    )
  );

CREATE POLICY "mu_photo_select_staff"
  ON maintenance_update_photo FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM maintenance_update mu
      JOIN issue i ON i.issue_id = mu.issue_id
      JOIN address a ON a.address_id = i.address_id
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE mu.maintenance_update_id = maintenance_update_photo.maintenance_update_id
        AND sha.staff_user_id = auth.uid()
    )
  );

CREATE POLICY "mu_photo_insert_staff"
  ON maintenance_update_photo FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM maintenance_update mu
      JOIN issue i ON i.issue_id = mu.issue_id
      JOIN address a ON a.address_id = i.address_id
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE mu.maintenance_update_id = maintenance_update_photo.maintenance_update_id
        AND sha.staff_user_id = auth.uid()
    )
  );
