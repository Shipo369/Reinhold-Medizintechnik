-- Add missing foreign key relationships
ALTER TABLE exam_attempts
  DROP CONSTRAINT IF EXISTS exam_attempts_user_id_fkey,
  ADD CONSTRAINT exam_attempts_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- Ensure status column exists with correct properties
ALTER TABLE exam_attempts 
  DROP CONSTRAINT IF EXISTS exam_attempts_status_check,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD CONSTRAINT exam_attempts_status_check
  CHECK (status IN ('active', 'reset'));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exam_attempts_composite 
  ON exam_attempts(user_id, exam_id, status);

-- Update existing attempts to have correct status
UPDATE exam_attempts
SET status = 'active'
WHERE status IS NULL;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';