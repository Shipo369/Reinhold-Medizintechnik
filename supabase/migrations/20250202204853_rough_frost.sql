-- Drop existing policies without truncating data
DO $$ 
BEGIN
  -- Drop policies if they exist
  DROP POLICY IF EXISTS "authenticated_full_access" ON profiles;
  DROP POLICY IF EXISTS "full_access_policy" ON profiles;
  DROP POLICY IF EXISTS "basic_access" ON profiles;
END $$;

-- Create registration handler that respects roles
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create a new profile as regular user
  INSERT INTO profiles (
    id,
    email,
    role,
    status,
    created_at,
    full_name
  )
  VALUES (
    NEW.id,
    NEW.email,
    'user',  -- Default to regular user
    'pending',  -- Start as pending
    NOW(),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  );
  RETURN NEW;
END;
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create proper RLS policies
CREATE POLICY "users_read_own"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR  -- Users can read own profile
    EXISTS (  -- Admins can read all profiles
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'approved'
    )
  );

CREATE POLICY "users_update_own"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR  -- Users can update own profile
    EXISTS (  -- Admins can update all profiles
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'approved'
    )
  );

-- Create admin-only policies for other tables
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

-- Ensure admin exists
DO $$
BEGIN
  -- Only create admin if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE email = 'juan_jano@hotmail.de'
    AND role = 'admin'
  ) THEN
    -- Create admin user if needed
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
      last_sign_in_at
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      'e89d6e6a-8f5e-4c1e-9438-1f4f79e5da2a',
      'authenticated',
      'authenticated',
      'juan_jano@hotmail.de',
      crypt('369369', gen_salt('bf')),
      NOW(),
      '{"provider": "email", "providers": ["email"]}',
      '{}',
      NOW(),
      NOW(),
      NOW()
    );

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
    );
  END IF;
END $$;

-- Set permissions
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';