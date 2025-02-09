-- First, drop all existing policies, triggers, and functions
DO $$ 
BEGIN
  -- Drop all policies
  DROP POLICY IF EXISTS "read_own_profile" ON profiles;
  DROP POLICY IF EXISTS "update_own_profile" ON profiles;
  DROP POLICY IF EXISTS "profiles_read_own" ON profiles;
  DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
  DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
  DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
  DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
  DROP POLICY IF EXISTS "Admin access based on role column" ON profiles;
  
  -- Drop triggers
  DROP TRIGGER IF EXISTS protect_role_changes ON profiles;
  DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
  
  -- Drop functions
  DROP FUNCTION IF EXISTS check_role_change();
  DROP FUNCTION IF EXISTS handle_auth_user_registration();
  DROP FUNCTION IF EXISTS is_approved_admin();
  DROP FUNCTION IF EXISTS is_approved_user();
END $$;

-- Clean up all existing data
TRUNCATE auth.users CASCADE;
TRUNCATE profiles CASCADE;

-- Reset all sequences
ALTER SEQUENCE IF EXISTS auth.users_id_seq RESTART;
ALTER SEQUENCE IF EXISTS profiles_id_seq RESTART;

-- Create admin user
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  last_sign_in_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'juan',
  crypt('123123', gen_salt('bf')),
  NOW(),
  '{"provider": "username", "providers": ["username"]}',
  '{"username": "juan"}',
  NOW(),
  NOW(),
  NOW()
);

-- Create admin profile
INSERT INTO profiles (
  id,
  email,
  role,
  status,
  created_at,
  full_name
)
SELECT
  id,
  email,
  'admin',
  'approved',
  NOW(),
  'Juan'
FROM auth.users
WHERE email = 'juan';

-- Create registration handler
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO profiles (
    id,
    email,
    role,
    status,
    created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    'user',
    'pending',
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

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create basic profile policies
CREATE POLICY "basic_profile_access"
  ON profiles
  FOR ALL
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'approved'
    )
  );

-- Function to check admin status
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
    AND status = 'approved'
  );
END;
$$;

-- Create admin policies for other tables
DO $$
DECLARE
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT IN ('profiles')
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
        );
    ', table_name, table_name);
  END LOOP;
END
$$;

-- Set permissions
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';