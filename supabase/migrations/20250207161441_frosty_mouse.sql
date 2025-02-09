-- Drop existing policies for online_users
DROP POLICY IF EXISTS "online_users_select" ON online_users;
DROP POLICY IF EXISTS "online_users_insert" ON online_users;
DROP POLICY IF EXISTS "online_users_update" ON online_users;
DROP POLICY IF EXISTS "online_users_delete" ON online_users;

-- Create new, more permissive policies for online_users
CREATE POLICY "online_users_select"
  ON online_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "online_users_insert"
  ON online_users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "online_users_update"
  ON online_users
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "online_users_delete"
  ON online_users
  FOR DELETE
  TO authenticated
  USING (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';