-- Function to sync auth users with profiles
CREATE OR REPLACE FUNCTION sync_auth_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create profile if it doesn't exist
  INSERT INTO public.profiles (id, email, role, status)
  VALUES (
    NEW.id,
    NEW.email,
    'user',
    'pending'
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Create trigger to automatically create profiles
DROP TRIGGER IF EXISTS sync_auth_users_trigger ON auth.users;
CREATE TRIGGER sync_auth_users_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_auth_users();

-- Sync existing users
INSERT INTO public.profiles (id, email, role, status)
SELECT 
  id,
  email,
  'user',
  'pending'
FROM auth.users
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles WHERE profiles.id = users.id
);