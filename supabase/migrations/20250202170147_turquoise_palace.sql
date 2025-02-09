-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS handle_new_registration_trigger ON auth.users;
DROP TRIGGER IF EXISTS sync_auth_users_trigger ON auth.users;
DROP FUNCTION IF EXISTS handle_new_registration();
DROP FUNCTION IF EXISTS sync_auth_users();

-- Create improved function to handle new registrations
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- For new registrations, always create a pending profile
  INSERT INTO public.profiles (
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
    status = 'pending',
    email = EXCLUDED.email,
    updated_at = NOW()
  WHERE 
    profiles.email = NEW.email;

  -- For existing email addresses, ensure they are marked as pending
  UPDATE profiles
  SET 
    status = 'pending',
    updated_at = NOW()
  WHERE 
    email = NEW.email 
    AND id != NEW.id
    AND status != 'pending';
  
  RETURN NEW;
END;
$$;

-- Create new trigger
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Reset any existing profiles that should be pending
UPDATE profiles 
SET 
  status = 'pending',
  updated_at = NOW()
WHERE 
  email IN (
    SELECT email 
    FROM auth.users 
    GROUP BY email 
    HAVING COUNT(*) > 1
  )
  AND status != 'pending';