-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_exam_attempts_with_details();

-- Create function to get exam attempts with details
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
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH attempt_details AS (
    SELECT DISTINCT ON (ea.id)
      ea.id,
      ea.user_id,
      ea.exam_id,
      ea.score,
      ea.passed,
      ea.started_at,
      ea.completed_at,
      ea.created_at,
      p.email,
      p.full_name,
      me.title,
      me.passing_score,
      me.max_attempts
    FROM exam_attempts ea
    JOIN profiles p ON ea.user_id = p.id
    JOIN module_exams me ON ea.exam_id = me.id
    WHERE ea.status = 'active'
    ORDER BY ea.id, ea.created_at DESC
  )
  SELECT 
    ad.id,
    ad.user_id,
    ad.exam_id,
    ad.score,
    ad.passed,
    ad.started_at,
    ad.completed_at,
    ad.created_at,
    ad.email,
    ad.full_name,
    ad.title as exam_title,
    ad.passing_score,
    ad.max_attempts
  FROM attempt_details ad
  ORDER BY ad.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_exam_attempts_with_details() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';