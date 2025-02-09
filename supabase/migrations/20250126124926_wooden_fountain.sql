-- Drop existing foreign key if it exists
ALTER TABLE exam_attempts
  DROP CONSTRAINT IF EXISTS exam_attempts_user_id_fkey;

-- Add new foreign key reference to profiles
ALTER TABLE exam_attempts
  ADD CONSTRAINT exam_attempts_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES profiles(id)
  ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_exam_attempts_user_id
  ON exam_attempts(user_id);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';