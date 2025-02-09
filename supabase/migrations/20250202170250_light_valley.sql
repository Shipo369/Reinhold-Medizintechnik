-- Drop existing triggers and functions
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
  ON CONFLICT (email) DO UPDATE
  SET 
    status = 'pending',
    updated_at = NOW()
  WHERE 
    profiles.status != 'pending';

  RETURN NEW;
END;
$$;

-- Create new trigger
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Sync missing users
INSERT INTO public.profiles (id, email, role, status, created_at)
SELECT 
  id,
  email,
  'user',
  'pending',
  NOW()
FROM auth.users
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles WHERE profiles.email = users.email
);

-- Reset status for existing users
UPDATE profiles
SET 
  status = 'pending',
  updated_at = NOW()
WHERE 
  email IN (
    SELECT email 
    FROM auth.users 
    WHERE email NOT IN (
      SELECT email 
      FROM profiles 
      WHERE status = 'approved'
    )
  );