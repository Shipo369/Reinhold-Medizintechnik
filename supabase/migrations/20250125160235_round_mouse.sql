-- Part 3: Create functions
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
  
  -- Insert the new code with explicit expires_at
  INSERT INTO verification_codes (
    email, 
    code, 
    expires_at
  )
  VALUES (
    p_email, 
    v_code, 
    now() + interval '24 hours'
  );
  
  RETURN v_code;
END;
$$;

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