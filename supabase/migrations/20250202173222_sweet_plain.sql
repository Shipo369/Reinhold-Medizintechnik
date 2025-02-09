-- Drop all existing triggers and functions
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
  '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
  'authenticated',
  'authenticated',
  'juan_jano@hotmail.de',
  crypt('369369', gen_salt('bf')),
  NOW(),
  '{"provider": "email", "providers": ["email"], "role": "admin"}',
  '{"role": "admin"}',
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
  created_at
)
VALUES (
  '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
  'juan_jano@hotmail.de',
  'admin',
  'approved',
  NOW()
);

-- Create registration handler with proper error handling
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Add a small delay to ensure transaction consistency
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
      -- If profile exists, update it
      UPDATE profiles
      SET 
        email = NEW.email,
        updated_at = NOW()
      WHERE id = NEW.id;
    WHEN OTHERS THEN
      -- Log error but don't fail
      RAISE WARNING 'Error in handle_auth_user_registration: %', SQLERRM;
  END;

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

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- Grant specific permissions for auth schema
GRANT USAGE ON SCHEMA auth TO postgres, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO postgres, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO postgres, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA auth TO postgres, authenticated, service_role;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';