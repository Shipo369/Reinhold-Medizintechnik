-- Drop existing status check constraint
ALTER TABLE profiles 
  DROP CONSTRAINT IF EXISTS profiles_status_check;

-- Add status column if it doesn't exist (without constraint)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'status'
  ) THEN
    ALTER TABLE profiles ADD COLUMN status TEXT;
  END IF;
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';