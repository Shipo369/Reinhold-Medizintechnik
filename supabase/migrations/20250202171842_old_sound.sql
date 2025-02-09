-- First check if admin exists in auth.users
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = '8ac9a2e7-b335-4e08-95ab-1721fae83b97'
  ) THEN
    -- Insert admin user if not exists
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
    );
  END IF;
END $$;

-- Then check if admin profile exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = '8ac9a2e7-b335-4e08-95ab-1721fae83b97'
  ) THEN
    -- Insert admin profile if not exists
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
  ELSE
    -- Update existing profile to ensure admin status
    UPDATE profiles
    SET
      email = 'juan_jano@hotmail.de',
      role = 'admin',
      status = 'approved',
      updated_at = NOW()
    WHERE id = '8ac9a2e7-b335-4e08-95ab-1721fae83b97';
  END IF;
END $$;