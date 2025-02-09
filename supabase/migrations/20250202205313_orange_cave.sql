-- Drop existing policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "profiles_select" ON profiles;
  DROP POLICY IF EXISTS "profiles_update" ON profiles;
END $$;

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
  'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
  'authenticated',
  'authenticated',
  'juan_jano@hotmail.de',
  crypt('369369', gen_salt('bf')),
  NOW(),
  jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']::text[],
    'role', 'authenticated'
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
)
ON CONFLICT (id) DO UPDATE
SET
  email = EXCLUDED.email,
  encrypted_password = EXCLUDED.encrypted_password,
  raw_app_meta_data = EXCLUDED.raw_app_meta_data,
  raw_user_meta_data = EXCLUDED.raw_user_meta_data,
  is_super_admin = EXCLUDED.is_super_admin,
  updated_at = NOW();

-- Create admin profile
INSERT INTO profiles (
  id,
  email,
  role,
  status,
  created_at,
  full_name,
  email_verified,
  email_verified_at
)
VALUES (
  'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
  'juan_jano@hotmail.de',
  'admin',
  'approved',
  NOW(),
  'Juan Jano',
  TRUE,
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET
  email = EXCLUDED.email,
  role = EXCLUDED.role,
  status = EXCLUDED.status,
  full_name = EXCLUDED.full_name,
  email_verified = EXCLUDED.email_verified,
  email_verified_at = EXCLUDED.email_verified_at,
  updated_at = NOW();

-- Create simple policies
CREATE POLICY "allow_read"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_update"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR
    role = 'admin'
  );

-- Create policies for other tables
DO $$
DECLARE
  t record;
BEGIN
  FOR t IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename != 'profiles'
  LOOP
    EXECUTE format('
      DROP POLICY IF EXISTS "admin_access" ON %I;
      CREATE POLICY "admin_access" ON %I
        FOR ALL
        TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = ''admin''
            AND status = ''approved''
          )
        )
    ', t.tablename, t.tablename);
  END LOOP;
END $$;

-- Set permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';