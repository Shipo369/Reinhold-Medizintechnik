-- Drop trigger first to remove dependency
DROP TRIGGER IF EXISTS check_exam_attempts_trigger ON exam_attempts;

-- Now we can safely drop the functions
DROP FUNCTION IF EXISTS get_exam_attempts_with_details();
DROP FUNCTION IF EXISTS check_exam_attempts();

-- Rename max_attempts column in module_exams to be more specific
ALTER TABLE module_exams 
  RENAME COLUMN max_attempts TO allowed_attempts;

-- Create new function with unambiguous column names
CREATE OR REPLACE FUNCTION get_exam_attempts_with_details()
RETURNS TABLE (
  id UUID,
  user_id UUID,
  exam_id UUID,
  score INTEGER,
  passed BOOLEAN,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  email TEXT,
  full_name TEXT,
  exam_title TEXT,
  passing_score INTEGER,
  allowed_attempts INTEGER
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT DISTINCT ON (a.id)
    a.id,
    a.user_id,
    a.exam_id,
    a.score,
    a.passed,
    a.started_at,
    a.completed_at,
    a.created_at,
    p.email,
    p.full_name,
    e.title as exam_title,
    e.passing_score,
    e.allowed_attempts
  FROM exam_attempts a
  JOIN profiles p ON a.user_id = p.id
  JOIN module_exams e ON a.exam_id = e.id
  WHERE a.status = 'active'
  ORDER BY a.id, a.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Create function to check attempt limits with new column name
CREATE OR REPLACE FUNCTION check_exam_attempts()
RETURNS TRIGGER AS $$
DECLARE
  attempt_count INTEGER;
  max_allowed INTEGER;
BEGIN
  -- Get allowed attempts for this exam
  SELECT allowed_attempts INTO max_allowed
  FROM module_exams
  WHERE id = NEW.exam_id;

  -- Count existing attempts
  SELECT COUNT(*) INTO attempt_count
  FROM exam_attempts
  WHERE exam_id = NEW.exam_id
  AND user_id = NEW.user_id
  AND status = 'active';

  -- If max attempts reached, prevent new attempt
  IF attempt_count >= max_allowed THEN
    RAISE EXCEPTION 'Maximum number of attempts (%) reached for this exam', max_allowed;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger after function is defined
CREATE TRIGGER check_exam_attempts_trigger
  BEFORE INSERT ON exam_attempts
  FOR EACH ROW
  EXECUTE FUNCTION check_exam_attempts();

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_exam_attempts_with_details() TO authenticated;
GRANT EXECUTE ON FUNCTION check_exam_attempts() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';