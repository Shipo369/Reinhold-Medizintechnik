-- Drop existing policies first
DO $$ 
BEGIN
  -- Drop chat conversation policies if they exist
  DROP POLICY IF EXISTS "chat_conversations_all_access" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_select" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_insert" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_update" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_delete" ON chat_conversations;

  -- Drop chat participant policies if they exist
  DROP POLICY IF EXISTS "chat_participants_all_access" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_select" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_insert" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_update" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_delete" ON chat_participants;

  -- Drop storage policies if they exist
  DROP POLICY IF EXISTS "group_avatars_all_access" ON storage.objects;
  DROP POLICY IF EXISTS "group_avatars_select" ON storage.objects;
  DROP POLICY IF EXISTS "group_avatars_insert" ON storage.objects;
  DROP POLICY IF EXISTS "group_avatars_delete" ON storage.objects;
END $$;

-- Create new policies with unique names
CREATE POLICY "chat_conversations_access_v2"
  ON chat_conversations
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "chat_participants_access_v2"
  ON chat_participants
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "group_avatars_access_v2"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'group-avatars')
  WITH CHECK (bucket_id = 'group-avatars');

-- Create function to create a group chat with simpler logic
CREATE OR REPLACE FUNCTION create_group_chat(
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_member_ids UUID[] DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conversation_id UUID;
  v_member_id UUID;
BEGIN
  -- Create new group conversation
  INSERT INTO chat_conversations (
    name,
    description,
    is_group,
    created_by
  )
  VALUES (
    p_name,
    p_description,
    true,
    auth.uid()
  )
  RETURNING id INTO v_conversation_id;

  -- Add creator as participant
  INSERT INTO chat_participants (conversation_id, user_id)
  VALUES (v_conversation_id, auth.uid());

  -- Add other members if provided
  IF p_member_ids IS NOT NULL THEN
    FOREACH v_member_id IN ARRAY p_member_ids
    LOOP
      -- Skip if member ID is the same as creator
      IF v_member_id != auth.uid() THEN
        INSERT INTO chat_participants (conversation_id, user_id)
        VALUES (v_conversation_id, v_member_id)
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  RETURN v_conversation_id;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';