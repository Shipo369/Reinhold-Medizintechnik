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
  invited_at,
  confirmation_token,
  confirmation_sent_at,
  recovery_token,
  recovery_sent_at,
  email_change_token_new,
  email_change,
  email_change_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at,
  phone,
  phone_confirmed_at,
  phone_change,
  phone_change_token,
  phone_change_sent_at,
  email_change_token_current,
  email_change_confirm_status,
  banned_until,
  reauthentication_token,
  reauthentication_sent_at,
  is_sso_user,
  deleted_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
  'authenticated',
  'authenticated',
  'juan_jano@hotmail.de',
  crypt('369369', gen_salt('bf')),
  NOW(),
  NULL,
  '',
  NULL,
  '',
  NULL,
  '',
  '',
  NULL,
  NOW(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  FALSE,
  NOW(),
  NOW(),
  NULL,
  NULL,
  '',
  '',
  NULL,
  '',
  0,
  NULL,
  '',
  NULL,
  FALSE,
  NULL
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

-- Create improved registration handler with transaction handling
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Wait a short moment to ensure the auth user is fully created
  PERFORM pg_sleep(0.1);

  -- Create a new profile
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
  EXCEPTION 
    WHEN unique_violation THEN
      -- If profile already exists, do nothing
      NULL;
    WHEN OTHERS THEN
      -- For any other error, log it but don't fail
      RAISE WARNING 'Error creating profile: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;

-- Create trigger for new registrations
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();