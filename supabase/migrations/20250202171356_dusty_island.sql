-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Create improved registration handler with proper transaction handling
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Ensure we're in a transaction
  IF NOT EXISTS (SELECT 1 FROM pg_stat_activity WHERE backend_xid IS NOT NULL AND pid = pg_backend_pid()) THEN
    RAISE EXCEPTION 'Function must be called within a transaction';
  END IF;

  -- First, delete any existing profile with this email
  DELETE FROM profiles 
  WHERE email = NEW.email;

  -- Wait for deletion to complete
  PERFORM pg_sleep(0.1);
  
  -- Then create a new profile
  INSERT INTO profiles (
    id,
    email,
    role,
    status,
    created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    'user',
    'pending',
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

-- Clean up any existing duplicate profiles
DELETE FROM profiles a USING (
  SELECT email, MIN(created_at) as first_created
  FROM profiles
  GROUP BY email
  HAVING COUNT(*) > 1
) b
WHERE a.email = b.email
AND a.created_at > b.first_created;

-- Add unique constraint on email
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_email_unique CASCADE;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_email_unique UNIQUE (email);