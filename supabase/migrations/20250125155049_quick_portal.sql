-- Drop existing function
DROP FUNCTION IF EXISTS verify_code(TEXT, TEXT);

-- Recreate verify_code function with LIMIT 1
CREATE OR REPLACE FUNCTION verify_code(p_email TEXT, p_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_valid BOOLEAN;
  v_verification_code RECORD;
BEGIN
  -- Get the latest unverified code
  SELECT *
  INTO v_verification_code
  FROM verification_codes
  WHERE email = p_email
    AND verified_at IS NULL
    AND expires_at > now()
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF v_verification_code IS NULL THEN
    RETURN false;
  END IF;
  
  -- Update verification status
  UPDATE verification_codes
  SET verified_at = CASE 
    WHEN code = p_code THEN now()
    ELSE verified_at
  END
  WHERE id = v_verification_code.id
  RETURNING (code = p_code) INTO v_valid;
  
  IF v_valid THEN
    UPDATE profiles
    SET email_verified = true,
        email_verified_at = now()
    WHERE email = p_email;
  END IF;
  
  RETURN COALESCE(v_valid, false);
END;
$$;