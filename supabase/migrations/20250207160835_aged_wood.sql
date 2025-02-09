-- Drop existing policies
DO $$ 
BEGIN
  -- Drop chat conversation policies
  DROP POLICY IF EXISTS "Users can view their conversations" ON chat_conversations;
  DROP POLICY IF EXISTS "Users can create conversations" ON chat_conversations;
  
  -- Drop chat participant policies  
  DROP POLICY IF EXISTS "Users can view their chat participants" ON chat_participants;
  DROP POLICY IF EXISTS "Users can join conversations" ON chat_participants;
  DROP POLICY IF EXISTS "Users can update their last read timestamp" ON chat_participants;

  -- Drop chat message policies
  DROP POLICY IF EXISTS "Users can view conversation messages" ON chat_messages;
  DROP POLICY IF EXISTS "Users can send messages" ON chat_messages;

  -- Drop online user policies
  DROP POLICY IF EXISTS "view_online_status" ON online_users;
  DROP POLICY IF EXISTS "update_own_online_status" ON online_users;
  DROP POLICY IF EXISTS "modify_own_online_status" ON online_users;
  DROP POLICY IF EXISTS "delete_own_online_status" ON online_users;
END $$;

-- Recreate policies with unique names
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

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';