-- First, drop all existing policies
DO $$ 
BEGIN
  -- Drop policies for profiles
  DROP POLICY IF EXISTS "profiles_read_own" ON profiles;
  DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
  DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
  DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
  DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
  DROP POLICY IF EXISTS "Admin access based on role column" ON profiles;
END $$;

-- Drop existing triggers and functions in correct order
DROP TRIGGER IF EXISTS protect_role_changes ON profiles;
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS check_role_change();
DROP FUNCTION IF EXISTS handle_auth_user_registration();
DROP FUNCTION IF EXISTS is_approved_admin();
DROP FUNCTION IF EXISTS is_approved_user();

-- Clean up all existing data
TRUNCATE auth.users CASCADE;
TRUNCATE profiles CASCADE;

-- Reset all sequences
ALTER SEQUENCE IF EXISTS auth.users_id_seq RESTART;
ALTER SEQUENCE IF EXISTS profiles_id_seq RESTART;

-- Create admin user with new credentials
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
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'juan',
  crypt('123123', gen_salt('bf')),
  NOW(),
  jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']::text[],
    'role', 'admin'
  ),
  jsonb_build_object(
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
SELECT
  id,
  email,
  'admin',
  'approved',
  NOW(),
  'Juan',
  TRUE,
  NOW()
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
  -- Create a new profile
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

-- Ensure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create new RLS policies
CREATE POLICY "read_own_profile"
  ON profiles
  FOR SELECT
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

CREATE POLICY "update_own_profile"
  ON profiles
  FOR UPDATE
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

-- Function to check if user is approved admin
CREATE OR REPLACE FUNCTION is_approved_admin()
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
    AND email_verified = true
  );
END;
$$;

-- Function to prevent role changes
CREATE OR REPLACE FUNCTION check_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If role is being changed
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    -- Only allow if user is admin
    IF NOT EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'approved'
    ) THEN
      RAISE EXCEPTION 'Only administrators can change roles';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger for role protection
CREATE TRIGGER protect_role_changes
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION check_role_change();

-- Create policies for admin-only tables
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
      DROP POLICY IF EXISTS "Admin full access" ON %I;
      CREATE POLICY "Admin full access" ON %I
        FOR ALL
        TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = ''admin''
            AND status = ''approved''
            AND email_verified = true
          )
        );
    ', table_name, table_name);
  END LOOP;
END
$$;

-- Revoke direct table access from anonymous users
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon;

-- Grant minimal permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';