-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Create improved registration handler
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
    birth_date
  )
  VALUES (
    NEW.id,
    NEW.email,
    CASE 
      WHEN NEW.email = 'admin@reinhold-medizintechnik.de' THEN 'admin'
      ELSE 'user'
    END,
    CASE 
      WHEN NEW.email = 'admin@reinhold-medizintechnik.de' THEN 'approved'
      ELSE 'pending'
    END,
    NOW(),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'organization',
    COALESCE(NEW.raw_user_meta_data->>'gender', 'prefer_not_to_say'),
    COALESCE((NEW.raw_user_meta_data->>'birth_date')::date, '1970-01-01'::date)
  );

  RETURN NEW;
END;
$$;

-- Create trigger for new registrations
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Ensure admin exists with correct credentials
DO $$
BEGIN
  -- Delete existing admin user if exists
  DELETE FROM auth.users 
  WHERE email = 'admin@reinhold-medizintechnik.de';

  -- Create new admin user
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
      'providers', ARRAY['email']::text[],
      'role', 'admin'
    ),
    jsonb_build_object(
      'role', 'admin',
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
    TRUE,
    FALSE,
    NULL
  );
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';