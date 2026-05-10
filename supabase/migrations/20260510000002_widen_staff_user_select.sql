-- Staff profiles are visible to all authenticated users.
-- Staff first names and display names appear on issue cards and comment threads,
-- so tenants and other staff members need to be able to read them.
DROP POLICY "staff_user_select_own" ON staff_user;

CREATE POLICY "staff_user_select_authenticated"
  ON staff_user FOR SELECT
  USING (auth.uid() IS NOT NULL);
