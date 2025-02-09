-- Drop all existing policies, triggers, and functions
DO $$ 
BEGIN
  -- Drop all policies
  DROP POLICY IF EXISTS "basic_profile_access" ON profiles;
  DROP POLICY IF EXISTS "admin_access" ON profiles;
  DROP POLICY IF EXISTS "read_own_profile" ON profiles;
  DROP POLICY IF EXISTS "update_own_profile" ON profiles;
  DROP POLICY IF EXISTS "profiles_read_own" ON profiles;
  DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
  DROP POLICY IF EXISTS "basic_access" ON profiles;
  
  -- Drop triggers
  DROP TRIGGER IF EXISTS protect_role_changes ON profiles;
  DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
  
  -- Drop functions
  DROP FUNCTION IF EXISTS check_role_change();
  DROP FUNCTION IF EXISTS handle_auth_user_registration();
  DROP FUNCTION IF EXISTS is_admin();
END $$;

-- Clean up all existing data
TRUNCATE auth.users CASCADE;
TRUNCATE profiles CASCADE;

-- Reset all sequences
ALTER SEQUENCE IF EXISTS auth.users_id_seq RESTART;
ALTER SEQUENCE IF EXISTS profiles_id_seq RESTART;

-- Create simple registration handler
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create a new profile with admin role and approved status
  INSERT INTO profiles (
    id,
    email,
    role,
    status,
    created_at,
    full_name,
    email_verified,
    email_verified_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    'admin',  -- Everyone is admin
    'approved',  -- Everyone is approved
    NOW(),
    NEW.email,
    TRUE,  -- Everyone is verified
    NOW()
  );
  RETURN NEW;
END;
$$;

-- Create trigger for new registrations
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Enable RLS but make it permissive
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create permissive policy that allows all authenticated users to do everything
CREATE POLICY "full_access"
  ON profiles
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create permissive policies for all other tables
DO $$
DECLARE
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('
      DROP POLICY IF EXISTS "full_access" ON %I;
      CREATE POLICY "full_access" ON %I
        FOR ALL
        TO authenticated
        USING (true)
        WITH CHECK (true);
    ', table_name, table_name);
  END LOOP;
END
$$;

-- Set permissions
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';