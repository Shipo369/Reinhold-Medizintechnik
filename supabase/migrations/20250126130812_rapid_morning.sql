-- Create function to get exam attempt details
CREATE OR REPLACE FUNCTION get_exam_attempt_details(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  exam_id UUID,
  user_id UUID,
  score INTEGER,
  passed BOOLEAN,
  created_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  email TEXT,
  full_name TEXT,
  exam_title TEXT,
  passing_score INTEGER,
  max_attempts INTEGER
) 
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.exam_id,
    a.user_id,
    a.score,
    a.passed,
    a.created_at,
    a.completed_at,
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
      WHERE id = p_user_id
      AND role = 'admin'
    )
    OR
    -- Users can see their own attempts
    a.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_exam_attempt_details TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';