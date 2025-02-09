-- Drop existing trigger and function
DROP TRIGGER IF EXISTS check_exam_attempts_trigger ON exam_attempts;
DROP FUNCTION IF EXISTS check_exam_attempts();

-- Create improved function to check attempt limits
CREATE OR REPLACE FUNCTION check_exam_attempts()
RETURNS TRIGGER AS $$
DECLARE
  attempt_count INTEGER;
  max_allowed INTEGER;
  has_passed BOOLEAN;
BEGIN
  -- Get allowed attempts for this exam
  SELECT allowed_attempts INTO max_allowed
  FROM module_exams
  WHERE id = NEW.exam_id;

  -- Check if user has already passed this exam
  SELECT EXISTS (
    SELECT 1
    FROM exam_attempts
    WHERE exam_id = NEW.exam_id
    AND user_id = NEW.user_id
    AND passed = true
    AND status = 'active'
  ) INTO has_passed;

  -- If already passed, prevent new attempt
  IF has_passed THEN
    RAISE EXCEPTION 'Sie haben diese Prüfung bereits bestanden und können sie nicht erneut durchführen.';
  END IF;

  -- Count existing active attempts
  SELECT COUNT(*) INTO attempt_count
  FROM exam_attempts
  WHERE exam_id = NEW.exam_id
  AND user_id = NEW.user_id
  AND status = 'active'
  AND completed_at IS NOT NULL;  -- Nur abgeschlossene Versuche zählen

  -- If max attempts reached, prevent new attempt
  IF attempt_count >= max_allowed THEN
    RAISE EXCEPTION 'Sie haben die maximale Anzahl von % Versuchen für diese Prüfung erreicht.', max_allowed;
  END IF;

  -- Automatically mark any existing incomplete attempts as 'reset'
  UPDATE exam_attempts 
  SET status = 'reset'
  WHERE exam_id = NEW.exam_id
  AND user_id = NEW.user_id
  AND completed_at IS NULL
  AND status = 'active';

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER check_exam_attempts_trigger
  BEFORE INSERT ON exam_attempts
  FOR EACH ROW
  EXECUTE FUNCTION check_exam_attempts();

-- Grant permissions
GRANT EXECUTE ON FUNCTION check_exam_attempts() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';