-- Drop existing policies
DROP POLICY IF EXISTS "chat_conversations_select" ON chat_conversations;
DROP POLICY IF EXISTS "chat_conversations_insert" ON chat_conversations;
DROP POLICY IF EXISTS "chat_conversations_update" ON chat_conversations;
DROP POLICY IF EXISTS "chat_conversations_delete" ON chat_conversations;

-- Create more permissive policies for chat_conversations
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

CREATE POLICY "chat_conversations_update"
  ON chat_conversations
  FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid());

CREATE POLICY "chat_conversations_delete"
  ON chat_conversations
  FOR DELETE
  TO authenticated
  USING (created_by = auth.uid());

-- Update storage policies for group avatars
DROP POLICY IF EXISTS "group_avatars_select" ON storage.objects;
DROP POLICY IF EXISTS "group_avatars_insert" ON storage.objects;
DROP POLICY IF EXISTS "group_avatars_delete" ON storage.objects;

CREATE POLICY "group_avatars_select"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'group-avatars');

CREATE POLICY "group_avatars_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'group-avatars');

CREATE POLICY "group_avatars_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'group-avatars');

-- Update chat_participants policies to be more permissive
DROP POLICY IF EXISTS "chat_participants_select" ON chat_participants;
DROP POLICY IF EXISTS "chat_participants_insert" ON chat_participants;
DROP POLICY IF EXISTS "chat_participants_update" ON chat_participants;
DROP POLICY IF EXISTS "chat_participants_delete" ON chat_participants;

CREATE POLICY "chat_participants_select"
  ON chat_participants
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "chat_participants_insert"
  ON chat_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_participants_update"
  ON chat_participants
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "chat_participants_delete"
  ON chat_participants
  FOR DELETE
  TO authenticated
  USING (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';