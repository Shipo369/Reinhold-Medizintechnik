-- First drop the trigger
DROP TRIGGER IF EXISTS on_auth_user_registration ON auth.users;

-- Then drop the function
DROP FUNCTION IF EXISTS handle_auth_user_registration() CASCADE;

-- Create improved registration handler with better error handling
CREATE OR REPLACE FUNCTION handle_auth_user_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Add a small delay to ensure auth user is fully created
  PERFORM pg_sleep(0.1);
  
  -- Create a new profile
  BEGIN
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
    );
  EXCEPTION 
    WHEN unique_violation THEN
      -- If profile already exists, update it
      UPDATE profiles
      SET 
        email = NEW.email,
        updated_at = NOW()
      WHERE id = NEW.id;
    WHEN OTHERS THEN
      -- Log error but don't fail
      RAISE WARNING 'Error in handle_auth_user_registration: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_registration
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_registration();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';