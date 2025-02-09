-- First drop any existing chat-related triggers
DROP TRIGGER IF EXISTS grant_chat_access_trigger ON profiles;
DROP TRIGGER IF EXISTS auto_grant_chat_access ON profiles;

-- Drop any existing chat-related functions
DROP FUNCTION IF EXISTS auto_grant_chat_access();

-- Drop the auth registration trigger
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;

-- Drop the registration handler function
DROP FUNCTION IF EXISTS handle_auth_user_registration() CASCADE;

-- Create improved registration handler
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile_exists boolean;
BEGIN
  -- Check if profile already exists
  SELECT EXISTS (
    SELECT 1 FROM profiles WHERE id = NEW.id
  ) INTO v_profile_exists;

  IF v_profile_exists THEN
    -- Update existing profile
    UPDATE profiles
    SET 
      email = NEW.email,
      updated_at = NOW()
    WHERE id = NEW.id;
  ELSE
    -- Create new profile
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
      'user',
      'pending',
      NOW(),
      COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
      FALSE,
      NULL
    );
  END IF;

  RETURN NEW;
EXCEPTION 
  WHEN OTHERS THEN
    -- Log error but don't fail
    RAISE WARNING 'Error in handle_auth_user_registration: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create auth registration trigger
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Ensure all existing auth users have profiles
INSERT INTO profiles (
  id,
  email,
  role,
  status,
  created_at,
  full_name,
  email_verified
)
SELECT 
  u.id,
  u.email,
  'user',
  'pending',
  COALESCE(u.created_at, NOW()),
  COALESCE(u.raw_user_meta_data->>'full_name', u.email),
  FALSE
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM profiles p WHERE p.id = u.id
)
ON CONFLICT (id) DO NOTHING;

-- Add index for better profile lookup performance
CREATE INDEX IF NOT EXISTS idx_profiles_id_email 
  ON profiles(id, email);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';