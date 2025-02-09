-- Drop existing policy if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'verification_codes' 
    AND policyname = 'Users can update their own verification codes'
  ) THEN
    DROP POLICY "Users can update their own verification codes" ON verification_codes;
  END IF;
END $$;

-- Create update policy for verification codes
CREATE POLICY "Users can update their own verification codes"
  ON verification_codes
  FOR UPDATE
  TO authenticated
  USING (email = auth.email());