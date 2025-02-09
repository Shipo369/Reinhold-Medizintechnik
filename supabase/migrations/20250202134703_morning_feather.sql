-- Create function to handle certificate request reset
CREATE OR REPLACE FUNCTION handle_exam_attempt_reset()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- When exam attempts are reset (status changed to 'reset')
  IF NEW.status = 'reset' THEN
    -- Reset any certificate requests for this exam and user
    UPDATE certificate_requests
    SET status = 'pending',
        file_path = NULL
    WHERE user_id = NEW.user_id
    AND exam_id = NEW.exam_id;

    -- Delete the certificate file from storage if it exists
    -- Note: This is handled by the storage bucket's ON DELETE CASCADE
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger to automatically reset certificate requests
CREATE TRIGGER reset_certificate_requests_on_attempt_reset
  AFTER UPDATE ON exam_attempts
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'reset')
  EXECUTE FUNCTION handle_exam_attempt_reset();