-- Ensure max_attempts column exists and has correct properties
DO $$ 
BEGIN
  -- Add column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'module_exams' 
    AND column_name = 'max_attempts'
  ) THEN
    ALTER TABLE module_exams
      ADD COLUMN max_attempts INTEGER DEFAULT 3;
  END IF;
END $$;

-- Create function to check attempt limits
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

-- Create trigger to check attempts before insert
DROP TRIGGER IF EXISTS check_exam_attempts_trigger ON exam_attempts;
CREATE TRIGGER check_exam_attempts_trigger
  BEFORE INSERT ON exam_attempts
  FOR EACH ROW
  EXECUTE FUNCTION check_exam_attempts();

-- Add index for better performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_exam_attempts_user_exam
  ON exam_attempts(user_id, exam_id);

-- Update existing exams to have default max attempts
UPDATE module_exams
SET max_attempts = 3
WHERE max_attempts IS NULL;