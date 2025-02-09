-- Drop all existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Clean up all existing profiles except admin
DELETE FROM profiles 
WHERE id != '8ac9a2e7-b335-4e08-95ab-1721fae83b97';

-- Delete all auth users except admin
DELETE FROM auth.users 
WHERE id != '8ac9a2e7-b335-4e08-95ab-1721fae83b97';

-- Ensure admin exists in auth.users with correct password
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  last_sign_in_at
)
VALUES (
  '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
  'juan_jano@hotmail.de',
  crypt('369369', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET 
  email = EXCLUDED.email,
  encrypted_password = crypt('369369', gen_salt('bf')),
  updated_at = NOW();

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
END;
$$;

-- Create trigger for new registrations
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();