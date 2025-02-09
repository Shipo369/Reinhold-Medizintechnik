-- Drop existing policies and functions first
DO $$ 
BEGIN
  -- Drop policies if they exist
  DROP POLICY IF EXISTS "view_online_status" ON online_users;
  DROP POLICY IF EXISTS "update_own_online_status" ON online_users;
  DROP POLICY IF EXISTS "modify_own_online_status" ON online_users;
  DROP POLICY IF EXISTS "delete_own_online_status" ON online_users;
  
  -- Drop functions if they exist
  DROP FUNCTION IF EXISTS update_last_seen();
  DROP FUNCTION IF EXISTS get_unread_count(UUID);
  DROP FUNCTION IF EXISTS start_conversation(UUID);
  DROP FUNCTION IF EXISTS mark_conversation_read(UUID);
END $$;

-- Create policies for online_users table
CREATE POLICY "view_online_status"
  ON online_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "update_own_online_status"
  ON online_users
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "modify_own_online_status"
  ON online_users
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "delete_own_online_status"
  ON online_users
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Create function to update user's last seen timestamp
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO online_users (user_id, last_seen_at)
  VALUES (auth.uid(), NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET last_seen_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get unread message count
CREATE OR REPLACE FUNCTION get_unread_count(p_conversation_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
  v_last_read TIMESTAMPTZ;
BEGIN
  -- Get user's last read timestamp for the conversation
  SELECT last_read_at INTO v_last_read
  FROM chat_participants
  WHERE conversation_id = p_conversation_id
  AND user_id = auth.uid();

  -- Count unread messages
  SELECT COUNT(*) INTO v_count
  FROM chat_messages
  WHERE conversation_id = p_conversation_id
  AND created_at > v_last_read
  AND sender_id != auth.uid();

  RETURN v_count;
END;
$$;

-- Create function to start a new conversation
CREATE OR REPLACE FUNCTION start_conversation(p_recipient_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_conversation_id UUID;
  v_existing_conversation_id UUID;
BEGIN
  -- Check if conversation already exists
  SELECT conversation_id INTO v_existing_conversation_id
  FROM chat_participants p1
  JOIN chat_participants p2 ON p1.conversation_id = p2.conversation_id
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

-- Create function to mark conversation as read
CREATE OR REPLACE FUNCTION mark_conversation_read(p_conversation_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE chat_participants
  SET last_read_at = NOW()
  WHERE conversation_id = p_conversation_id
  AND user_id = auth.uid();
END;
$$;

-- Enable realtime for chat messages
DO $$
BEGIN
  -- Drop existing publication if it exists
  DROP PUBLICATION IF EXISTS supabase_realtime;
  
  -- Create new publication
  CREATE PUBLICATION supabase_realtime FOR TABLE 
    chat_messages,
    chat_conversations,
    chat_participants,
    online_users;
END $$;