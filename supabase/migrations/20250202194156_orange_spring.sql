-- Update admin user and profile
DO $$ 
BEGIN
  -- Update admin user metadata and permissions
  UPDATE auth.users
  SET 
    raw_app_meta_data = jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']::text[],
      'role', 'admin'
    ),
    raw_user_meta_data = jsonb_build_object(
      'role', 'admin',
      'full_name', 'Juan Jano',
      'organization', 'Reinhold Medizintechnik GmbH',
      'gender', 'male',
      'birth_date', '1970-01-01'
    ),
    is_super_admin = TRUE,
    updated_at = NOW()
  WHERE email = 'juan_jano@hotmail.de';

  -- Ensure admin profile has correct role and status
  UPDATE profiles
  SET 
    role = 'admin',
    status = 'approved',
    email_verified = TRUE,
    email_verified_at = NOW(),
    updated_at = NOW()
  WHERE email = 'juan_jano@hotmail.de';

END $$;