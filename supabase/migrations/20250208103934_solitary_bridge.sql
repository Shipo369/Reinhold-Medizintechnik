-- Drop existing status check constraint if it exists
ALTER TABLE profiles 
  DROP CONSTRAINT IF EXISTS profiles_status_check;

-- Add status column with proper check constraint
ALTER TABLE profiles
  ADD CONSTRAINT profiles_status_check
  CHECK (status IN ('pending', 'approved', 'rejected'));

-- Add status column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'status'
  ) THEN
    ALTER TABLE profiles ADD COLUMN status TEXT NOT NULL DEFAULT 'pending';
  END IF;
END $$;

-- Update any NULL status values to 'pending'
UPDATE profiles 
SET status = 'pending' 
WHERE status IS NULL;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';