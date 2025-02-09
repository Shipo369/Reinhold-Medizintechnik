-- Add missing foreign key relationships and fix profile references
DO $$ 
BEGIN
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'exam_attempts_user_id_fkey'
  ) THEN
    ALTER TABLE exam_attempts DROP CONSTRAINT exam_attempts_user_id_fkey;
  END IF;

  -- Add new constraint to auth.users
  ALTER TABLE exam_attempts
    ADD CONSTRAINT exam_attempts_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id)
    ON DELETE CASCADE;
END $$;

-- Create function to get profile data for attempts
CREATE OR REPLACE FUNCTION get_profile_for_attempt(attempt_user_id UUID)
RETURNS TABLE (
  email TEXT,
  full_name TEXT
) 
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.email,
    p.full_name
  FROM profiles p
  WHERE p.id = attempt_user_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_profile_for_attempt TO authenticated;

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