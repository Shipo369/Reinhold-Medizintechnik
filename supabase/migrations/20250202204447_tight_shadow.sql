-- Drop all existing policies, triggers, and functions
DO $$ 
BEGIN
  -- Drop all policies
  DROP POLICY IF EXISTS "full_access_policy" ON profiles;
  DROP POLICY IF EXISTS "read_own_profile" ON profiles;
  DROP POLICY IF EXISTS "update_own_profile" ON profiles;
  DROP POLICY IF EXISTS "basic_access" ON profiles;
  DROP POLICY IF EXISTS "full_access" ON profiles;
  
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
  'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
  'authenticated',
  'authenticated',
  'juan_jano@hotmail.de',
  crypt('369369', gen_salt('bf')),
  NOW(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
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
  full_name,
  email_verified,
  email_verified_at
)
VALUES (
  'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
  'juan_jano@hotmail.de',
  'admin',
  'approved',
  NOW(),
  'Juan Jano',
  TRUE,
  NOW()
);

-- Create registration handler that makes everyone admin
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
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
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
DO $$
DECLARE
  t record;
BEGIN
  -- Enable RLS on all public tables
  FOR t IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t.tablename);
    
    -- Create permissive policy for each table
    EXECUTE format('
      CREATE POLICY "authenticated_full_access" ON %I
        FOR ALL
        TO authenticated
        USING (true)
        WITH CHECK (true)
    ', t.tablename);
  END LOOP;
END $$;

-- Set permissions
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';