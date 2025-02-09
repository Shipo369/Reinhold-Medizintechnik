-- Strengthen RLS policies and admin role protection

-- First, ensure RLS is enabled on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_presentations ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificate_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admin access based on role column" ON profiles;

-- Create more restrictive policies for profiles
CREATE POLICY "profiles_read_own"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'approved'
    )
  );

CREATE POLICY "profiles_update_own"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR
    (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
        AND status = 'approved'
      )
    )
  );

-- Function to check if user is approved admin
CREATE OR REPLACE FUNCTION is_approved_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
    AND status = 'approved'
    AND email_verified = true
  );
END;
$$;

-- Function to check if user is approved
CREATE OR REPLACE FUNCTION is_approved_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND status = 'approved'
    AND email_verified = true
  );
END;
$$;

-- Function to prevent role changes
CREATE OR REPLACE FUNCTION check_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If role is being changed
  IF TG_OP = 'UPDATE' AND OLD.role IS DISTINCT FROM NEW.role THEN
    -- Only allow if user is admin
    IF NOT EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'approved'
    ) THEN
      RAISE EXCEPTION 'Only administrators can change roles';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger for role protection
DROP TRIGGER IF EXISTS protect_role_changes ON profiles;
CREATE TRIGGER protect_role_changes
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION check_role_change();

-- Update admin user to ensure proper permissions
UPDATE auth.users
SET 
  raw_app_meta_data = jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']::text[],
    'role', 'authenticated'
  ),
  raw_user_meta_data = jsonb_build_object(
    'role', 'admin'
  ),
  is_super_admin = true
WHERE email = 'juan_jano@hotmail.de';

-- Ensure admin profile has correct settings
UPDATE profiles
SET 
  role = 'admin',
  status = 'approved',
  email_verified = true,
  email_verified_at = NOW()
WHERE email = 'juan_jano@hotmail.de';

-- Revoke direct table access from anonymous users
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon;

-- Grant minimal permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create policies for admin-only tables
DO $$
DECLARE
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT IN ('profiles')
  LOOP
    EXECUTE format('
      DROP POLICY IF EXISTS "Admin full access" ON %I;
      CREATE POLICY "Admin full access" ON %I
        FOR ALL
        TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = ''admin''
            AND status = ''approved''
            AND email_verified = true
          )
        );
    ', table_name, table_name);
  END LOOP;
END
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';