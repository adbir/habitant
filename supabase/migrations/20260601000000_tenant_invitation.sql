CREATE TABLE tenant_invitation (
  invitation_id    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  token            UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  address_id       UUID        NOT NULL REFERENCES address(address_id) ON DELETE CASCADE,
  created_by       UUID        NOT NULL REFERENCES staff_user(staff_user_id),
  expires_at       TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
  cancelled_at     TIMESTAMPTZ,
  invitation_flags BIGINT      NOT NULL DEFAULT 0,
  created          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  modified         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invitation_token   ON tenant_invitation (token);
CREATE INDEX idx_invitation_address ON tenant_invitation (address_id);

CREATE TRIGGER trg_invitation_modified
  BEFORE UPDATE ON tenant_invitation
  FOR EACH ROW EXECUTE FUNCTION set_modified();

ALTER TABLE tenant_invitation ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON tenant_invitation TO anon, authenticated;
GRANT INSERT, UPDATE ON tenant_invitation TO authenticated;

-- Unauthenticated users may read active (non-expired, non-cancelled)
-- invitations by token. Required so /join can show the address preview
-- before the user has created an account.
CREATE POLICY "invitation_select_active"
  ON tenant_invitation FOR SELECT
  USING (cancelled_at IS NULL AND expires_at > NOW());

-- Staff may insert invitations only for addresses in housings they manage.
CREATE POLICY "invitation_insert_staff"
  ON tenant_invitation FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM address a
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE a.address_id = tenant_invitation.address_id
        AND sha.staff_user_id = auth.uid()
    )
  );

-- Staff may cancel (set cancelled_at) invitations for housings they manage.
CREATE POLICY "invitation_update_staff"
  ON tenant_invitation FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM address a
      JOIN staff_housing_access sha ON sha.housing_id = a.housing_id
      WHERE a.address_id = tenant_invitation.address_id
        AND sha.staff_user_id = auth.uid()
    )
  );
