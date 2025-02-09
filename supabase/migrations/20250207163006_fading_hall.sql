-- Drop existing functions and recreate with fixes
DROP FUNCTION IF EXISTS start_conversation(UUID);
DROP FUNCTION IF EXISTS update_last_seen();

-- Create improved start_conversation function
CREATE OR REPLACE FUNCTION start_conversation(p_recipient_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conversation_id UUID;
  v_existing_conversation_id UUID;
BEGIN
  -- Check if conversation already exists
  WITH participant_pairs AS (
    SELECT p1.conversation_id
    FROM chat_participants p1
    INNER JOIN chat_participants p2 
      ON p1.conversation_id = p2.conversation_id
    WHERE p1.user_id = auth.uid()
      AND p2.user_id = p_recipient_id
  )
  SELECT conversation_id INTO v_existing_conversation_id
  FROM participant_pairs
  LIMIT 1;

  IF v_existing_conversation_id IS NOT NULL THEN
    RETURN v_existing_conversation_id;
  END IF;

  -- Create new conversation
  INSERT INTO chat_conversations DEFAULT VALUES
  RETURNING id INTO v_conversation_id;

  -- Add participants with explicit timestamps
  INSERT INTO chat_participants (conversation_id, user_id, last_read_at, created_at)
  VALUES
    (v_conversation_id, auth.uid(), NOW(), NOW()),
    (v_conversation_id, p_recipient_id, NOW(), NOW());

  RETURN v_conversation_id;
END;
$$;

-- Create improved online status function
CREATE OR REPLACE FUNCTION update_online_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO online_users (user_id, last_seen_at)
  VALUES (NEW.id, NOW())
  ON CONFLICT (user_id) 
  DO UPDATE SET last_seen_at = NOW();
  RETURN NEW;
END;
$$;

-- Create trigger for online status
DROP TRIGGER IF EXISTS update_online_status_trigger ON profiles;
CREATE TRIGGER update_online_status_trigger
  AFTER INSERT OR UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_online_status();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';