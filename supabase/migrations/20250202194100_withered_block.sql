-- Clean up and recreate admin user
DO $$ 
DECLARE
  v_user_exists boolean;
  v_profile_exists boolean;
BEGIN
  -- Check if user exists
  SELECT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = 'juan_jano@hotmail.de'
  ) INTO v_user_exists;

  -- Check if profile exists
  SELECT EXISTS (
    SELECT 1 FROM profiles 
    WHERE email = 'juan_jano@hotmail.de'
  ) INTO v_profile_exists;

  -- Delete existing user and profile if they exist
  IF v_user_exists THEN
    DELETE FROM auth.users WHERE email = 'juan_jano@hotmail.de';
  END IF;

  IF v_profile_exists THEN
    DELETE FROM profiles WHERE email = 'juan_jano@hotmail.de';
  END IF;

  -- Wait for deletions to complete
  PERFORM pg_sleep(0.1);

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
    '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
    'authenticated',
    'authenticated',
    'juan_jano@hotmail.de',
    crypt('369369', gen_salt('bf')),
    NOW(),
    jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']::text[]
    ),
    jsonb_build_object(
      'full_name', 'Juan Jano',
      'organization', 'Reinhold Medizintechnik GmbH',
      'gender', 'male',
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
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    updated_at = NOW();

  -- Create or update admin profile
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
    '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
    'juan_jano@hotmail.de',
    'admin',
    'approved',
    NOW(),
    'Juan Jano',
    'Reinhold Medizintechnik GmbH',
    'male',
    '1970-01-01',
    TRUE,
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    status = EXCLUDED.status,
    full_name = EXCLUDED.full_name,
    organization = EXCLUDED.organization,
    gender = EXCLUDED.gender,
    birth_date = EXCLUDED.birth_date,
    email_verified = EXCLUDED.email_verified,
    email_verified_at = EXCLUDED.email_verified_at,
    updated_at = NOW();

END $$;