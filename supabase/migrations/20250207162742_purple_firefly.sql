-- Drop existing functions
DROP FUNCTION IF EXISTS start_conversation(UUID);
DROP FUNCTION IF EXISTS update_last_seen();

-- Create improved start_conversation function with fixed query
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
  -- Check if conversation already exists with fixed query
  SELECT p1.conversation_id INTO v_existing_conversation_id
  FROM chat_participants p1
  INNER JOIN chat_participants p2 
    ON p1.conversation_id = p2.conversation_id
  WHERE p1.user_id = auth.uid()
    AND p2.user_id = p_recipient_id
  LIMIT 1;

  IF v_existing_conversation_id IS NOT NULL THEN
    RETURN v_existing_conversation_id;
  END IF;

  -- Create new conversation
  INSERT INTO chat_conversations DEFAULT VALUES
  RETURNING id INTO v_conversation_id;

  -- Add participants
  INSERT INTO chat_participants (conversation_id, user_id)
  VALUES
    (v_conversation_id, auth.uid()),
    (v_conversation_id, p_recipient_id);

  RETURN v_conversation_id;
END;
$$;

-- Create improved update_last_seen function with upsert handling
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  -- Use a proper upsert with ON CONFLICT DO UPDATE
  INSERT INTO online_users (user_id, last_seen_at)
  VALUES (auth.uid(), NOW())
  ON CONFLICT (user_id) 
  DO UPDATE SET last_seen_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';