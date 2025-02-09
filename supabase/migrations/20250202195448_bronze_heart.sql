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

-- Create admin user with username-based credentials
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
  last_sign_in_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change_token_current,
  is_super_admin,
  is_sso_user,
  deleted_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
  'authenticated',
  'authenticated',
  'juan',
  crypt('123123', gen_salt('bf')),
  NOW(),
  jsonb_build_object(
    'provider', 'username',
    'providers', ARRAY['username']::text[],
    'role', 'authenticated'
  ),
  jsonb_build_object(
    'username', 'juan',
    'role', 'admin'
  ),
  NOW(),
  NOW(),
  NOW(),
  '',
  '',
  '',
  '',
  TRUE,
  FALSE,
  NULL
);

-- Create admin profile
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
  'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
  'juan',
  'admin',
  'approved',
  NOW(),
  'Juan',
  TRUE,
  NOW()
);

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
    created_at,
    full_name
  )
  VALUES (
    NEW.id,
    NEW.email,
    'user',
    'pending',
    NOW(),
    NEW.raw_user_meta_data->>'username'
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
CREATE POLICY "basic_access"
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