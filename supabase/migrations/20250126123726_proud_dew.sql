-- Drop existing function and trigger first
DROP TRIGGER IF EXISTS check_exam_attempts_trigger ON exam_attempts;
DROP FUNCTION IF EXISTS check_exam_attempts();

-- Ensure max_attempts column exists and has correct properties
DO $$ 
BEGIN
  -- Drop the column if it exists to ensure clean state
  ALTER TABLE module_exams 
    DROP COLUMN IF EXISTS max_attempts;
  
  -- Add the column with correct properties
  ALTER TABLE module_exams 
    ADD COLUMN max_attempts INTEGER NOT NULL DEFAULT 3;
END $$;

-- Update any existing records
UPDATE module_exams 
SET max_attempts = 3 
WHERE max_attempts IS NULL;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_module_exams_max_attempts 
ON module_exams(max_attempts);

-- Recreate function with proper error handling
CREATE OR REPLACE FUNCTION check_exam_attempts()
RETURNS TRIGGER AS $$
DECLARE
  attempt_count INTEGER;
  max_attempts INTEGER;
BEGIN
  -- Get max attempts for this exam
  SELECT COALESCE(max_attempts, 3) INTO max_attempts
  FROM module_exams
  WHERE id = NEW.exam_id;

  -- Count existing attempts
  SELECT COUNT(*) INTO attempt_count
  FROM exam_attempts
  WHERE exam_id = NEW.exam_id
  AND user_id = NEW.user_id;

  -- If max attempts reached, prevent new attempt
  IF attempt_count >= max_attempts THEN
    RAISE EXCEPTION 'Maximum number of attempts (%) reached for this exam', max_attempts;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER check_exam_attempts_trigger
  BEFORE INSERT ON exam_attempts
  FOR EACH ROW
  EXECUTE FUNCTION check_exam_attempts();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';