-- First check if admin exists in auth.users
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
END $$;

-- Then handle the profile
DO $$
BEGIN
  -- Delete existing profile if exists
  DELETE FROM profiles 
  WHERE email = 'admin@reinhold-medizintechnik.de';

  -- Create new admin profile
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
    'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
    'admin@reinhold-medizintechnik.de',
    'admin',
    'approved',
    NOW(),
    'Admin',
    'Reinhold Medizintechnik GmbH',
    'prefer_not_to_say',
    '1970-01-01'
  );
END $$;