-- Create function to get exam attempt details
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
  max_attempts INTEGER
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
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
    e.max_attempts
  FROM exam_attempts a
  JOIN profiles p ON a.user_id = p.id
  JOIN module_exams e ON a.exam_id = e.id
  WHERE 
    -- Admin can see all attempts
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    );
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_exam_attempts_with_details() TO authenticated;