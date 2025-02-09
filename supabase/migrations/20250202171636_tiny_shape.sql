-- Check and clean up auth users
DO $$
BEGIN
  -- Delete all existing auth users
  DELETE FROM auth.users;
  
  -- Reset all related sequences
  ALTER SEQUENCE IF EXISTS auth.users_id_seq RESTART;
  ALTER SEQUENCE IF EXISTS profiles_id_seq RESTART;
END $$;