-- Drop existing function and trigger first
DROP TRIGGER IF EXISTS check_exam_attempts_trigger ON exam_attempts;
DROP FUNCTION IF EXISTS check_exam_attempts();

-- Recreate module_exams table with correct schema
CREATE TABLE IF NOT EXISTS module_exams_new (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  passing_score INTEGER NOT NULL DEFAULT 70,
  time_limit INTEGER NOT NULL DEFAULT 60,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Copy data from old table if it exists
INSERT INTO module_exams_new (
  id, 
  device_model_id, 
  title, 
  description, 
  passing_score, 
  time_limit, 
  max_attempts, 
  created_at, 
  updated_at
)
SELECT 
  id, 
  device_model_id, 
  title, 
  description, 
  passing_score, 
  time_limit, 
  COALESCE(max_attempts, 3), 
  created_at, 
  updated_at
FROM module_exams;

-- Drop old table and rename new one
DROP TABLE IF EXISTS module_exams CASCADE;
ALTER TABLE module_exams_new RENAME TO module_exams;

-- Recreate foreign key references
ALTER TABLE exam_questions
  ADD CONSTRAINT exam_questions_exam_id_fkey 
  FOREIGN KEY (exam_id) 
  REFERENCES module_exams(id) 
  ON DELETE CASCADE;

ALTER TABLE exam_attempts
  ADD CONSTRAINT exam_attempts_exam_id_fkey 
  FOREIGN KEY (exam_id) 
  REFERENCES module_exams(id) 
  ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX idx_module_exams_max_attempts 
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

-- Recreate RLS policies
ALTER TABLE module_exams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view exams"
  ON module_exams
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage exams"
  ON module_exams
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Force schema cache refresh
NOTIFY pgrst, 'reload schema';