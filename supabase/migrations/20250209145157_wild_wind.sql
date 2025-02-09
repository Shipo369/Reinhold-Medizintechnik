-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;

-- Then drop the function
DROP FUNCTION IF EXISTS handle_auth_user_registration() CASCADE;

-- Create simple registration handler
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create a new profile
  INSERT INTO profiles (
    id,
    email,
    role,
    status,
    created_at,
    full_name,
    email_verified
  )
  VALUES (
    NEW.id,
    NEW.email,
    'user',
    'pending',
    NOW(),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    FALSE
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    updated_at = NOW();

  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();