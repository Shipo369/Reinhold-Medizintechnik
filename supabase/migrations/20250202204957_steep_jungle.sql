-- Drop all existing policies
DO $$ 
BEGIN
  -- Drop policies if they exist
  DROP POLICY IF EXISTS "authenticated_full_access" ON profiles;
  DROP POLICY IF EXISTS "users_read_own" ON profiles;
  DROP POLICY IF EXISTS "users_update_own" ON profiles;
  DROP POLICY IF EXISTS "admin_access" ON profiles;
END $$;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create non-recursive policies for profiles
CREATE POLICY "profiles_select"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    CASE 
      WHEN id = auth.uid() THEN true  -- Users can always read their own profile
      WHEN role = 'admin' AND status = 'approved' THEN true  -- Admins can read all profiles
      ELSE false
    END
  );

CREATE POLICY "profiles_update"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    CASE 
      WHEN id = auth.uid() THEN true  -- Users can always update their own profile
      WHEN role = 'admin' AND status = 'approved' THEN true  -- Admins can update all profiles
      ELSE false
    END
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
          CASE 
            WHEN EXISTS (
              SELECT 1 FROM profiles
              WHERE id = auth.uid()
              AND role = ''admin''
              AND status = ''approved''
            ) THEN true
            ELSE false
          END
        )
    ', t.tablename, t.tablename);
  END LOOP;
END $$;

-- Set permissions
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';