-- Create verification_codes table if it doesn't exist
CREATE TABLE IF NOT EXISTS verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours'),
  verified_at TIMESTAMPTZ,
  attempts INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_verification_codes_email ON verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_verification_codes_code ON verification_codes(code);
CREATE INDEX IF NOT EXISTS idx_verification_codes_expires_at ON verification_codes(expires_at);

-- Enable RLS
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can view their own verification codes" ON verification_codes;
  DROP POLICY IF EXISTS "Users can insert verification codes" ON verification_codes;
  DROP POLICY IF EXISTS "Users can update their own verification codes" ON verification_codes;
END $$;

-- Create new policies
CREATE POLICY "Users can view their own verification codes"
  ON verification_codes
  FOR SELECT
  TO authenticated
  USING (email = auth.email());

CREATE POLICY "Users can insert verification codes"
  ON verification_codes
  FOR INSERT
  TO authenticated
  WITH CHECK (email = auth.email());

CREATE POLICY "Users can update their own verification codes"
  ON verification_codes
  FOR UPDATE
  TO authenticated
  USING (email = auth.email());

-- Function to generate a new verification code
CREATE OR REPLACE FUNCTION generate_verification_code(p_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_code TEXT;
BEGIN
  -- Generate a random 6-digit code
  v_code := lpad(floor(random() * 1000000)::text, 6, '0');
  
  -- Insert the new code
  INSERT INTO verification_codes (
    email, 
    code
  )
  VALUES (
    p_email, 
    v_code
  );
  
  RETURN v_code;
END;
$$;

-- Function to verify a code
CREATE OR REPLACE FUNCTION verify_code(p_email TEXT, p_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_code_record RECORD;
BEGIN
  -- Get the latest unverified code for this email
  SELECT *
  INTO v_code_record
  FROM verification_codes
  WHERE email = p_email
    AND verified_at IS NULL
    AND expires_at > now()
  ORDER BY created_at DESC
  LIMIT 1;
  
  -- If no valid code exists
  IF v_code_record IS NULL THEN
    RETURN false;
  END IF;
  
  -- Update attempts counter
  UPDATE verification_codes
  SET attempts = attempts + 1
  WHERE id = v_code_record.id;
  
  -- If code matches, mark as verified
  IF v_code_record.code = p_code THEN
    UPDATE verification_codes
    SET verified_at = now()
    WHERE id = v_code_record.id;
    
    -- Update profile verification status
    UPDATE profiles
    SET 
      email_verified = true,
      email_verified_at = now()
    WHERE email = p_email;
    
    RETURN true;
  END IF;
  
  RETURN false;
END;
$$;