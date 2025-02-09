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

-- Force sync all users that should be pending
WITH auth_users AS (
  SELECT DISTINCT ON (email) id, email
  FROM auth.users
  ORDER BY email, created_at DESC
)
INSERT INTO public.profiles (id, email, role, status, created_at)
SELECT 
  au.id,
  au.email,
  'user',
  'pending',
  NOW()
FROM auth_users au
WHERE NOT EXISTS (
  SELECT 1 FROM profiles p 
  WHERE p.email = au.email
)
ON CONFLICT (id) DO UPDATE
SET 
  email = EXCLUDED.email,
  status = CASE 
    WHEN profiles.status = 'approved' THEN 'approved'
    ELSE 'pending'
  END,
  updated_at = NOW();