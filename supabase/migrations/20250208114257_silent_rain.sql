-- Drop existing policies first
DO $$ 
BEGIN
  -- Drop chat conversation policies if they exist
  DROP POLICY IF EXISTS "chat_conversations_select_v5" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_insert_v5" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_update_v5" ON chat_conversations;
  
  -- Drop chat participant policies if they exist
  DROP POLICY IF EXISTS "chat_participants_select_v5" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_insert_v5" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_update_v5" ON chat_participants;
  
  -- Drop chat message policies if they exist
  DROP POLICY IF EXISTS "chat_messages_select" ON chat_messages;
  DROP POLICY IF EXISTS "chat_messages_insert" ON chat_messages;
END $$;

-- Create non-recursive policies for chat conversations
CREATE POLICY "chat_conversations_access_v6"
  ON chat_conversations
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create non-recursive policies for chat participants
CREATE POLICY "chat_participants_access_v6"
  ON chat_participants
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create non-recursive policies for chat messages
CREATE POLICY "chat_messages_access_v6"
  ON chat_messages
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create function to get user conversations without recursion
CREATE OR REPLACE FUNCTION get_user_conversations_v2()
RETURNS TABLE (
  conversation_id UUID,
  name TEXT,
  description TEXT,
  image_url TEXT,
  is_group BOOLEAN,
  created_by UUID,
  last_message JSONB,
  participants JSONB,
  unread_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH user_convs AS (
    SELECT DISTINCT c.*
    FROM chat_conversations c
    JOIN chat_participants cp ON c.id = cp.conversation_id
    WHERE cp.user_id = auth.uid()
  ),
  last_msgs AS (
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
    WHERE m.conversation_id IN (SELECT id FROM user_convs)
    ORDER BY m.conversation_id, m.created_at DESC
  ),
  conv_participants AS (
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
    WHERE cp.conversation_id IN (SELECT id FROM user_convs)
    GROUP BY cp.conversation_id
  ),
  unread_counts AS (
    SELECT 
      m.conversation_id,
      COUNT(*) as unread_count
    FROM chat_messages m
    JOIN chat_participants cp ON m.conversation_id = cp.conversation_id
    WHERE cp.user_id = auth.uid()
    AND m.created_at > cp.last_read_at
    AND m.sender_id != auth.uid()
    GROUP BY m.conversation_id
  )
  SELECT 
    uc.id as conversation_id,
    uc.name,
    uc.description,
    uc.image_url,
    uc.is_group,
    uc.created_by,
    COALESCE(lm.message_data, NULL) as last_message,
    COALESCE(cp.participants, '[]'::jsonb) as participants,
    COALESCE(uc.unread_count, 0) as unread_count
  FROM user_convs uc
  LEFT JOIN last_msgs lm ON uc.id = lm.conversation_id
  LEFT JOIN conv_participants cp ON uc.id = cp.conversation_id
  LEFT JOIN unread_counts uc2 ON uc.id = uc2.conversation_id
  ORDER BY COALESCE((lm.message_data->>'created_at')::timestamptz, uc.created_at) DESC;
END;
$$;

-- Create function to mark conversation as read without recursion
CREATE OR REPLACE FUNCTION mark_conversation_read_v2(p_conversation_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE chat_participants
  SET last_read_at = NOW()
  WHERE conversation_id = p_conversation_id
  AND user_id = auth.uid();
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';