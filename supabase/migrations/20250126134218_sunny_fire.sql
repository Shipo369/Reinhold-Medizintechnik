-- Add function to reset exam attempts
CREATE OR REPLACE FUNCTION reset_exam_attempts(
  p_user_id UUID,
  p_exam_id UUID
)
RETURNS BOOLEAN
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
    RETURN false;
  END IF;

  -- Mark existing attempts as reset
  UPDATE exam_attempts
  SET status = 'reset'
  WHERE user_id = p_user_id
  AND exam_id = p_exam_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION reset_exam_attempts(UUID, UUID) TO authenticated;

-- Add policy for admins to update exam attempts
DROP POLICY IF EXISTS "Admins can update exam attempts" ON exam_attempts;
CREATE POLICY "Admins can update exam attempts"
  ON exam_attempts
  FOR UPDATE
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