-- Drop all existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Clean up all existing profiles except admin
DELETE FROM profiles 
WHERE id != '8ac9a2e7-b335-4e08-95ab-1721fae83b97';

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

-- Ensure admin exists and has correct permissions
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