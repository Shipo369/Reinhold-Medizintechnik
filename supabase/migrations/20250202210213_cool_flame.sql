-- Drop existing policies first
DO $$ 
BEGIN
  -- Drop all policies for profiles
  DROP POLICY IF EXISTS "profiles_read_access" ON profiles;
  DROP POLICY IF EXISTS "profiles_write_access" ON profiles;
  DROP POLICY IF EXISTS "allow_read" ON profiles;
  DROP POLICY IF EXISTS "allow_update" ON profiles;
  DROP POLICY IF EXISTS "admin_access" ON profiles;
  DROP POLICY IF EXISTS "authenticated_full_access" ON profiles;
  DROP POLICY IF EXISTS "full_access_policy" ON profiles;
  DROP POLICY IF EXISTS "basic_access" ON profiles;
  DROP POLICY IF EXISTS "allow_all_profiles" ON profiles;
END $$;

-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Create registration handler that makes everyone admin
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create a new profile with admin role and approved status
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
    NEW.id,
    NEW.email,
    'admin',  -- Everyone is admin
    'approved',  -- Everyone is approved
    NOW(),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    TRUE,  -- Everyone is verified
    NOW()
  );
  RETURN NEW;
END;
$$;

-- Create trigger for new registrations
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Enable RLS but make it permissive
DO $$
DECLARE
  t record;
BEGIN
  -- Enable RLS on all public tables
  FOR t IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
  LOOP
    -- First drop any existing policies
    EXECUTE format('DROP POLICY IF EXISTS "authenticated_full_access" ON %I', t.tablename);
    EXECUTE format('DROP POLICY IF EXISTS "allow_all_%s" ON %I', t.tablename, t.tablename);
    
    -- Enable RLS
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t.tablename);
    
    -- Create new permissive policy with unique name
    EXECUTE format('
      CREATE POLICY "allow_all_%s" ON %I
        FOR ALL
        TO authenticated
        USING (true)
        WITH CHECK (true)
    ', t.tablename, t.tablename);
  END LOOP;
END $$;

-- Set permissions
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';