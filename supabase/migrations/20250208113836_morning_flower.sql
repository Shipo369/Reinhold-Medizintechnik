-- Drop existing policies first
DO $$ 
BEGIN
  -- Drop chat conversation policies if they exist
  DROP POLICY IF EXISTS "chat_conversations_access_v2" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_select" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_insert" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_update" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_delete" ON chat_conversations;

  -- Drop chat participant policies if they exist
  DROP POLICY IF EXISTS "chat_participants_access_v2" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_select" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_insert" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_update" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_delete" ON chat_participants;
END $$;

-- Create new policies for chat conversations
CREATE POLICY "chat_conversations_select_v3"
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

CREATE POLICY "chat_conversations_insert_v3"
  ON chat_conversations
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_conversations_update_v3"
  ON chat_conversations
  FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid());

-- Create new policies for chat participants
CREATE POLICY "chat_participants_select_v3"
  ON chat_participants
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE conversation_id = chat_participants.conversation_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "chat_participants_insert_v3"
  ON chat_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_participants_update_v3"
  ON chat_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Create function to create a group chat with improved error handling
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
  -- Validate input
  IF p_name IS NULL OR length(trim(p_name)) = 0 THEN
    RAISE EXCEPTION 'Group name is required';
  END IF;

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
  IF p_member_ids IS NOT NULL AND array_length(p_member_ids, 1) > 0 THEN
    FOREACH v_member_id IN ARRAY p_member_ids
    LOOP
      -- Skip if member ID is the same as creator
      IF v_member_id != auth.uid() THEN
        BEGIN
          INSERT INTO chat_participants (conversation_id, user_id)
          VALUES (v_conversation_id, v_member_id);
        EXCEPTION WHEN OTHERS THEN
          -- Log error but continue with other members
          RAISE WARNING 'Could not add member %: %', v_member_id, SQLERRM;
        END;
      END IF;
    END LOOP;
  END IF;

  RETURN v_conversation_id;
END;
$$;

-- Create function to get conversation details
CREATE OR REPLACE FUNCTION get_conversation_details(p_conversation_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  image_url TEXT,
  is_group BOOLEAN,
  created_by UUID,
  participant_count BIGINT,
  is_member BOOLEAN,
  is_admin BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.name,
    c.description,
    c.image_url,
    c.is_group,
    c.created_by,
    COUNT(DISTINCT p.user_id)::BIGINT as participant_count,
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE conversation_id = c.id
      AND user_id = auth.uid()
    ) as is_member,
    (c.created_by = auth.uid()) as is_admin
  FROM chat_conversations c
  LEFT JOIN chat_participants p ON c.id = p.conversation_id
  WHERE c.id = p_conversation_id
  GROUP BY c.id;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';