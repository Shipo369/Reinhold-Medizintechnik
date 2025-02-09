-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS protect_role_changes ON profiles;
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS check_role_change();
DROP FUNCTION IF EXISTS handle_auth_user_registration();
DROP FUNCTION IF EXISTS is_admin();

-- Drop existing policies
DO $$
DECLARE
  t record;
BEGIN
  FOR t IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "authenticated_full_access" ON %I', t.tablename);
  END LOOP;
END $$;

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
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t.tablename);
    
    -- Create permissive policy for each table
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