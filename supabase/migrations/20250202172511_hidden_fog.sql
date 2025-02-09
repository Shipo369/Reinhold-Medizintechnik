-- Drop all existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Clean up all existing profiles except admin
DELETE FROM profiles 
WHERE id != '8ac9a2e7-b335-4e08-95ab-1721fae83b97';

-- Delete all auth users except admin
DELETE FROM auth.users 
WHERE id != '8ac9a2e7-b335-4e08-95ab-1721fae83b97';

-- Delete admin user to ensure clean recreation
DELETE FROM auth.users 
WHERE id = '8ac9a2e7-b335-4e08-95ab-1721fae83b97';

-- Recreate admin user with correct credentials
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
  '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
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

-- Ensure admin profile exists with correct permissions
INSERT INTO profiles (
  id,
  email,
  role,
  status,
  created_at
)
VALUES (
  '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
  'juan_jano@hotmail.de',
  'admin',
  'approved',
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET
  email = EXCLUDED.email,
  role = 'admin',
  status = 'approved',
  updated_at = NOW();

-- Create simple registration handler
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
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail
  RAISE WARNING 'Error in handle_auth_user_registration: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- Create trigger for new registrations
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);