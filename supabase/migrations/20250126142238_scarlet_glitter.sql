-- Drop existing function
DROP FUNCTION IF EXISTS get_exam_attempts_with_details();

-- Create function with explicit table aliases and column references
CREATE OR REPLACE FUNCTION get_exam_attempts_with_details()
RETURNS TABLE (
  attempt_id UUID,
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
  SELECT DISTINCT ON (attempts.id)
    attempts.id AS attempt_id,
    attempts.user_id,
    attempts.exam_id,
    attempts.score,
    attempts.passed,
    attempts.started_at,
    attempts.completed_at,
    attempts.created_at,
    profiles.email,
    profiles.full_name,
    exams.title AS exam_title,
    exams.passing_score,
    exams.allowed_attempts
  FROM exam_attempts attempts
  JOIN profiles ON attempts.user_id = profiles.id
  JOIN module_exams exams ON attempts.exam_id = exams.id
  WHERE attempts.status = 'active'
  ORDER BY attempts.id, attempts.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_exam_attempts_with_details() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';