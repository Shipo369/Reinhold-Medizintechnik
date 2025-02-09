-- Drop existing policies for online_users
DROP POLICY IF EXISTS "online_users_select" ON online_users;
DROP POLICY IF EXISTS "online_users_insert" ON online_users;
DROP POLICY IF EXISTS "online_users_update" ON online_users;
DROP POLICY IF EXISTS "online_users_delete" ON online_users;

-- Create more permissive policies for online_users
CREATE POLICY "online_users_all_access"
  ON online_users
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Update chat_participants policies to be more permissive
DROP POLICY IF EXISTS "chat_participants_select" ON chat_participants;
DROP POLICY IF EXISTS "chat_participants_insert" ON chat_participants;

CREATE POLICY "chat_participants_all_access"
  ON chat_participants
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Update chat_messages policies to be more permissive
DROP POLICY IF EXISTS "chat_messages_select" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert" ON chat_messages;

CREATE POLICY "chat_messages_all_access"
  ON chat_messages
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Update chat_conversations policies to be more permissive
DROP POLICY IF EXISTS "chat_conversations_select" ON chat_conversations;
DROP POLICY IF EXISTS "chat_conversations_insert" ON chat_conversations;

CREATE POLICY "chat_conversations_all_access"
  ON chat_conversations
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';