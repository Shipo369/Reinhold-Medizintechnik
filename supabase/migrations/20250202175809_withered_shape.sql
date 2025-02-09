-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Clean up all existing profiles and users
TRUNCATE auth.users CASCADE;
TRUNCATE profiles CASCADE;

-- Reset all sequences
ALTER SEQUENCE IF EXISTS auth.users_id_seq RESTART;
ALTER SEQUENCE IF EXISTS profiles_id_seq RESTART;

-- Create admin user with correct credentials
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
  'admin@reinhold-medizintechnik.de',
  crypt('admin123', gen_salt('bf')),
  NOW(),
  jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']::text[]
  ),
  jsonb_build_object(
    'full_name', 'Admin',
    'organization', 'Reinhold Medizintechnik GmbH',
    'gender', 'prefer_not_to_say',
    'birth_date', '1970-01-01'
  ),
  NOW(),
  NOW(),
  NOW(),
  '',
  '',
  '',
  '',
  FALSE,
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
  organization,
  gender,
  birth_date,
  email_verified,
  email_verified_at
)
VALUES (
  'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
  'admin@reinhold-medizintechnik.de',
  'admin',
  'approved',
  NOW(),
  'Admin',
  'Reinhold Medizintechnik GmbH',
  'prefer_not_to_say',
  '1970-01-01',
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
  -- Create a new profile
  INSERT INTO profiles (
    id,
    email,
    role,
    status,
    created_at,
    full_name,
    organization,
    gender,
    birth_date,
    email_verified
  )
  VALUES (
    NEW.id,
    NEW.email,
    'user',
    'pending',
    NOW(),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'organization',
    COALESCE(NEW.raw_user_meta_data->>'gender', 'prefer_not_to_say'),
    COALESCE((NEW.raw_user_meta_data->>'birth_date')::date, '1970-01-01'::date),
    FALSE
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

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON profiles
  FOR ALL
  TO authenticated
  USING (
    role = 'admin'
  );

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';