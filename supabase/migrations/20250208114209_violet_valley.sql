-- Drop existing policies first
DO $$ 
BEGIN
  -- Drop chat conversation policies if they exist
  DROP POLICY IF EXISTS "chat_conversations_select_v4" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_insert_v4" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_update_v4" ON chat_conversations;
  
  -- Drop chat participant policies if they exist
  DROP POLICY IF EXISTS "chat_participants_select_v4" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_insert_v4" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_update_v4" ON chat_participants;
END $$;

-- Create simplified policies for chat conversations
CREATE POLICY "chat_conversations_select_v5"
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

CREATE POLICY "chat_conversations_insert_v5"
  ON chat_conversations
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_conversations_update_v5"
  ON chat_conversations
  FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid());

-- Create simplified policies for chat participants
CREATE POLICY "chat_participants_select_v5"
  ON chat_participants
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM chat_participants cp2
      WHERE cp2.conversation_id = chat_participants.conversation_id
      AND cp2.user_id = auth.uid()
    )
  );

CREATE POLICY "chat_participants_insert_v5"
  ON chat_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow if user is adding themselves or is the group creator
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM chat_conversations
      WHERE id = conversation_id
      AND created_by = auth.uid()
    )
  );

CREATE POLICY "chat_participants_update_v5"
  ON chat_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Create improved function to get user conversations
CREATE OR REPLACE FUNCTION get_user_conversations()
RETURNS TABLE (
  conversation_id UUID,
  name TEXT,
  description TEXT,
  image_url TEXT,
  is_group BOOLEAN,
  created_by UUID,
  last_message JSONB,
  participants JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH user_conversations AS (
    -- Get all conversations where user is a participant
    SELECT DISTINCT c.*
    FROM chat_conversations c
    JOIN chat_participants cp ON c.id = cp.conversation_id
    WHERE cp.user_id = auth.uid()
  ),
  last_messages AS (
    -- Get last message for each conversation
    SELECT DISTINCT ON (m.conversation_id)
      m.conversation_id,
      jsonb_build_object(
        'id', m.id,
        'content', m.content,
        'sender_id', m.sender_id,
        'file_path', m.file_path,
        'file_type', m.file_type,
        'created_at', m.created_at,
        'sender', jsonb_build_object(
          'full_name', p.full_name,
          'email', p.email,
          'avatar_url', p.avatar_url
        )
      ) as message_data
    FROM chat_messages m
    JOIN profiles p ON m.sender_id = p.id
    WHERE m.conversation_id IN (SELECT id FROM user_conversations)
    ORDER BY m.conversation_id, m.created_at DESC
  ),
  conversation_participants AS (
    -- Get all participants for each conversation
    SELECT 
      cp.conversation_id,
      jsonb_agg(
        jsonb_build_object(
          'id', p.id,
          'full_name', p.full_name,
          'email', p.email,
          'avatar_url', p.avatar_url
        )
      ) as participants
    FROM chat_participants cp
    JOIN profiles p ON cp.user_id = p.id
    WHERE cp.conversation_id IN (SELECT id FROM user_conversations)
    GROUP BY cp.conversation_id
  )
  SELECT 
    uc.id as conversation_id,
    uc.name,
    uc.description,
    uc.image_url,
    uc.is_group,
    uc.created_by,
    COALESCE(lm.message_data, NULL) as last_message,
    COALESCE(cp.participants, '[]'::jsonb) as participants
  FROM user_conversations uc
  LEFT JOIN last_messages lm ON uc.id = lm.conversation_id
  LEFT JOIN conversation_participants cp ON uc.id = cp.conversation_id
  ORDER BY COALESCE((lm.message_data->>'created_at')::timestamptz, uc.created_at) DESC;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';