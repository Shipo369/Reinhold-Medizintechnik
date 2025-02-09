-- Function to handle new registrations
CREATE OR REPLACE FUNCTION handle_new_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If the user already exists in auth.users but not in profiles,
  -- or if their profile exists but they're trying to register again,
  -- set their status back to 'pending'
  INSERT INTO public.profiles (id, email, role, status)
  VALUES (
    NEW.id,
    NEW.email,
    'user',
    'pending'
  )
  ON CONFLICT (id) DO UPDATE
  SET status = 'pending',
      email = EXCLUDED.email
  WHERE profiles.status != 'pending';
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger
DROP TRIGGER IF EXISTS sync_auth_users_trigger ON auth.users;

-- Create new trigger
CREATE TRIGGER handle_new_registration_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_registration();

-- Reset status for existing users who try to register again
UPDATE profiles
SET status = 'pending'
WHERE id IN (
  SELECT id FROM auth.users
  WHERE email IN (
    SELECT email FROM auth.users
    GROUP BY email
    HAVING COUNT(*) > 1
  )
);