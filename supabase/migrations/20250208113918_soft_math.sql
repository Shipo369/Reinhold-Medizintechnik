-- Drop existing policies first
DO $$ 
BEGIN
  -- Drop chat conversation policies if they exist
  DROP POLICY IF EXISTS "chat_conversations_select_v3" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_insert_v3" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_conversations_update_v3" ON chat_conversations;
  
  -- Drop chat participant policies if they exist
  DROP POLICY IF EXISTS "chat_participants_select_v3" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_insert_v3" ON chat_participants;
  DROP POLICY IF EXISTS "chat_participants_update_v3" ON chat_participants;
END $$;

-- Create simplified policies for chat conversations
CREATE POLICY "chat_conversations_select_v4"
  ON chat_conversations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "chat_conversations_insert_v4"
  ON chat_conversations
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_conversations_update_v4"
  ON chat_conversations
  FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid());

-- Create simplified policies for chat participants
CREATE POLICY "chat_participants_select_v4"
  ON chat_participants
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "chat_participants_insert_v4"
  ON chat_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "chat_participants_update_v4"
  ON chat_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Create function to get conversation participants
CREATE OR REPLACE FUNCTION get_conversation_participants(p_conversation_id UUID)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  email TEXT,
  avatar_url TEXT,
  is_admin BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.full_name,
    p.email,
    p.avatar_url,
    (c.created_by = p.id) as is_admin
  FROM chat_participants cp
  JOIN profiles p ON cp.user_id = p.id
  JOIN chat_conversations c ON cp.conversation_id = c.id
  WHERE cp.conversation_id = p_conversation_id;
END;
$$;

-- Create function to get user conversations
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
  WITH last_messages AS (
    SELECT DISTINCT ON (conversation_id)
      conversation_id,
      jsonb_build_object(
        'id', m.id,
        'content', m.content,
        'sender_id', m.sender_id,
        'created_at', m.created_at,
        'sender', jsonb_build_object(
          'full_name', p.full_name,
          'email', p.email,
          'avatar_url', p.avatar_url
        )
      ) as message_data
    FROM chat_messages m
    JOIN profiles p ON m.sender_id = p.id
    ORDER BY conversation_id, m.created_at DESC
  )
  SELECT 
    c.id as conversation_id,
    c.name,
    c.description,
    c.image_url,
    c.is_group,
    c.created_by,
    lm.message_data as last_message,
    jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'email', p.email,
        'avatar_url', p.avatar_url
      )
    ) as participants
  FROM chat_conversations c
  JOIN chat_participants cp ON c.id = cp.conversation_id
  JOIN profiles p ON cp.user_id = p.id
  LEFT JOIN last_messages lm ON c.id = lm.conversation_id
  WHERE EXISTS (
    SELECT 1 FROM chat_participants
    WHERE conversation_id = c.id
    AND user_id = auth.uid()
  )
  GROUP BY c.id, lm.message_data;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';