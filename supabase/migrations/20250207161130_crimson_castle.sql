-- Drop existing tables if they exist
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_participants CASCADE;
DROP TABLE IF EXISTS chat_conversations CASCADE;
DROP TABLE IF EXISTS online_users CASCADE;

-- Create chat_conversations table
CREATE TABLE chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create chat_participants table
CREATE TABLE chat_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES chat_conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  last_read_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(conversation_id, user_id)
);

-- Create chat_messages table
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES chat_conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create online_users table for tracking user status
CREATE TABLE online_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  last_seen_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE online_users ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_chat_participants_conversation ON chat_participants(conversation_id);
CREATE INDEX idx_chat_participants_user ON chat_participants(user_id);
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_sender ON chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_online_users_last_seen ON online_users(last_seen_at);

-- Create RLS policies with unique names
CREATE POLICY "chat_conversations_select"
  ON chat_conversations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE conversation_id = id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "chat_conversations_insert"
  ON chat_conversations
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_participants_select"
  ON chat_participants
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM chat_participants
    WHERE conversation_id = chat_participants.conversation_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "chat_participants_insert"
  ON chat_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "chat_participants_update"
  ON chat_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "chat_messages_select"
  ON chat_messages
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE conversation_id = chat_messages.conversation_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "chat_messages_insert"
  ON chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE conversation_id = chat_messages.conversation_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "online_users_select"
  ON online_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "online_users_insert"
  ON online_users
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "online_users_update"
  ON online_users
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "online_users_delete"
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