-- Drop existing policies first
DO $$ 
BEGIN
  -- Drop all policies for profiles
  DROP POLICY IF EXISTS "profiles_select" ON profiles;
  DROP POLICY IF EXISTS "profiles_update" ON profiles;
  DROP POLICY IF EXISTS "allow_read" ON profiles;
  DROP POLICY IF EXISTS "allow_update" ON profiles;
  DROP POLICY IF EXISTS "admin_access" ON profiles;
  DROP POLICY IF EXISTS "authenticated_full_access" ON profiles;
  DROP POLICY IF EXISTS "full_access_policy" ON profiles;
  DROP POLICY IF EXISTS "basic_access" ON profiles;
  DROP POLICY IF EXISTS "allow_all_profiles" ON profiles;
END $$;

-- Create simple policies with unique names
CREATE POLICY "profiles_read_access"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profiles_write_access"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR
    role = 'admin'
  );

-- Create policies for other tables
DO $$
DECLARE
  t record;
BEGIN
  FOR t IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename != 'profiles'
  LOOP
    EXECUTE format('
      DROP POLICY IF EXISTS "admin_access" ON %I;
      CREATE POLICY "admin_access" ON %I
        FOR ALL
        TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = ''admin''
            AND status = ''approved''
          )
        )
    ', t.tablename, t.tablename);
  END LOOP;
END $$;

-- Set permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';