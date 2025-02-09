-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;
DROP FUNCTION IF EXISTS handle_auth_user_registration();

-- Create improved registration handler
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete any existing profiles for this user ID
  DELETE FROM profiles WHERE id = NEW.id;
  
  -- Create a new profile
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

-- Clean up any existing duplicate profiles by ID
DELETE FROM profiles a USING profiles b
WHERE a.id < b.id 
AND a.email = b.email;

-- Add unique constraint on email
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_email_unique;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_email_unique UNIQUE (email);