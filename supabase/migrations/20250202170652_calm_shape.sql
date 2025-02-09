-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Create improved function to handle new registrations
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete any existing profiles with the same email but different ID
  DELETE FROM profiles
  WHERE email = NEW.email AND id != NEW.id;

  -- Create or update profile
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
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    status = CASE 
      WHEN profiles.status = 'approved' THEN 'approved'
      ELSE 'pending'
    END,
    updated_at = NOW();

  RETURN NEW;
END;
$$;

-- Create new trigger
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Clean up existing data
DO $$
BEGIN
  -- First, delete any duplicate profiles keeping only the latest one
  WITH duplicates AS (
    SELECT id, email,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) as rn
    FROM profiles
  )
  DELETE FROM profiles
  WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
  );

  -- Then sync with auth.users
  WITH latest_users AS (
    SELECT DISTINCT ON (email) id, email
    FROM auth.users
    ORDER BY email, created_at DESC
  )
  UPDATE profiles p
  SET 
    id = lu.id,
    email = lu.email,
    status = CASE 
      WHEN p.status = 'approved' THEN 'approved'
      ELSE 'pending'
    END,
    updated_at = NOW()
  FROM latest_users lu
  WHERE p.email = lu.email AND p.id != lu.id;

  -- Finally, create any missing profiles
  INSERT INTO profiles (id, email, role, status, created_at)
  SELECT 
    u.id,
    u.email,
    'user',
    'pending',
    NOW()
  FROM auth.users u
  WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.email = u.email
  );
END $$;

-- Add unique constraint on email if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'profiles_email_key'
  ) THEN
    ALTER TABLE profiles ADD CONSTRAINT profiles_email_key UNIQUE (email);
  END IF;
END $$;