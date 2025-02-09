-- Add status column to exam_attempts if it doesn't exist
ALTER TABLE exam_attempts 
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_exam_attempts_status
  ON exam_attempts(status);

-- Update existing attempts to have 'active' status
UPDATE exam_attempts
SET status = 'active'
WHERE status IS NULL;

-- Add check constraint for valid status values
ALTER TABLE exam_attempts
  ADD CONSTRAINT exam_attempts_status_check
  CHECK (status IN ('active', 'reset'));