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
DECLARE
  v_existing_profile profiles%ROWTYPE;
BEGIN
  -- Check if a profile with this email already exists
  SELECT * INTO v_existing_profile
  FROM profiles
  WHERE email = NEW.email;

  IF v_existing_profile.id IS NOT NULL THEN
    -- If profile exists with different ID, update it
    UPDATE profiles
    SET 
      id = NEW.id,
      email = NEW.email,
      status = 'pending',
      updated_at = NOW()
    WHERE id = v_existing_profile.id;
  ELSE
    -- Create new profile
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
  END IF;

  RETURN NEW;
END;
$$;

-- Create new trigger
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Clean up any duplicate profiles
WITH ranked_profiles AS (
  SELECT 
    id,
    email,
    status,
    ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) as rn
  FROM profiles
)
DELETE FROM profiles
WHERE id IN (
  SELECT id FROM ranked_profiles WHERE rn > 1
);

-- Sync any missing profiles
INSERT INTO profiles (id, email, role, status, created_at)
SELECT 
  u.id,
  u.email,
  'user',
  'pending',
  NOW()
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Update all non-approved profiles to pending
UPDATE profiles
SET status = 'pending'
WHERE status != 'approved';