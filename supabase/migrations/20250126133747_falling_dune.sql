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
    WHERE id = auth.uid()
    AND role = 'admin'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH attempt_details AS (
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
      e.title,
      e.passing_score,
      e.max_attempts
    FROM exam_attempts a
    JOIN profiles p ON a.user_id = p.id
    JOIN module_exams e ON a.exam_id = e.id
    WHERE a.status = 'active'
    ORDER BY a.id, a.created_at DESC
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

-- Ensure exam_attempts has correct foreign key relationships
ALTER TABLE exam_attempts
  DROP CONSTRAINT IF EXISTS exam_attempts_user_id_fkey,
  ADD CONSTRAINT exam_attempts_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES profiles(id)
  ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exam_attempts_composite 
  ON exam_attempts(user_id, exam_id, status);

-- Update RLS policies
ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own attempts" ON exam_attempts;
CREATE POLICY "Users can view their own attempts"
  ON exam_attempts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all attempts" ON exam_attempts;
CREATE POLICY "Admins can view all attempts"
  ON exam_attempts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';