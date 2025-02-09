-- Drop existing function
DROP FUNCTION IF EXISTS get_user_conversations_v2();

-- Create improved function with explicit column references
CREATE OR REPLACE FUNCTION get_user_conversations_v2()
RETURNS TABLE (
  id UUID,
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
DECLARE
  v_user_id UUID;
BEGIN
  -- Get current user ID once
  v_user_id := auth.uid();

  RETURN QUERY
  WITH user_conversations AS (
    -- Get all conversations where user is a participant with explicit column references
    SELECT DISTINCT 
      chat_conversations.id,
      chat_conversations.name,
      chat_conversations.description,
      chat_conversations.image_url,
      chat_conversations.is_group,
      chat_conversations.created_by,
      chat_conversations.created_at
    FROM chat_conversations
    JOIN chat_participants ON chat_conversations.id = chat_participants.conversation_id
    WHERE chat_participants.user_id = v_user_id
  ),
  latest_messages AS (
    -- Get last message for each conversation with explicit column references
    SELECT DISTINCT ON (chat_messages.conversation_id)
      chat_messages.conversation_id,
      chat_messages.id as message_id,
      chat_messages.content,
      chat_messages.sender_id,
      chat_messages.file_path,
      chat_messages.file_type,
      chat_messages.created_at,
      profiles.full_name,
      profiles.email,
      profiles.avatar_url
    FROM chat_messages
    JOIN profiles ON chat_messages.sender_id = profiles.id
    WHERE chat_messages.conversation_id IN (SELECT id FROM user_conversations)
    ORDER BY chat_messages.conversation_id, chat_messages.created_at DESC
  ),
  conversation_participants AS (
    -- Get all participants for each conversation with explicit column references
    SELECT 
      chat_participants.conversation_id,
      jsonb_agg(
        jsonb_build_object(
          'id', profiles.id,
          'full_name', profiles.full_name,
          'email', profiles.email,
          'avatar_url', profiles.avatar_url
        )
      ) as participants
    FROM chat_participants
    JOIN profiles ON chat_participants.user_id = profiles.id
    WHERE chat_participants.conversation_id IN (SELECT id FROM user_conversations)
    GROUP BY chat_participants.conversation_id
  ),
  unread_message_counts AS (
    -- Calculate unread messages for each conversation with explicit column references
    SELECT 
      chat_messages.conversation_id,
      COUNT(*) as unread_count
    FROM chat_messages
    JOIN chat_participants ON chat_messages.conversation_id = chat_participants.conversation_id
    WHERE chat_participants.user_id = v_user_id
    AND chat_messages.created_at > chat_participants.last_read_at
    AND chat_messages.sender_id != v_user_id
    GROUP BY chat_messages.conversation_id
  )
  SELECT 
    uc.id,
    uc.name,
    uc.description,
    uc.image_url,
    uc.is_group,
    uc.created_by,
    CASE 
      WHEN lm.message_id IS NOT NULL THEN
        jsonb_build_object(
          'id', lm.message_id,
          'content', lm.content,
          'sender_id', lm.sender_id,
          'file_path', lm.file_path,
          'file_type', lm.file_type,
          'created_at', lm.created_at,
          'sender', jsonb_build_object(
            'full_name', lm.full_name,
            'email', lm.email,
            'avatar_url', lm.avatar_url
          )
        )
      ELSE NULL
    END as last_message,
    COALESCE(cp.participants, '[]'::jsonb) as participants,
    COALESCE(umc.unread_count, 0) as unread_count
  FROM user_conversations uc
  LEFT JOIN latest_messages lm ON uc.id = lm.conversation_id
  LEFT JOIN conversation_participants cp ON uc.id = cp.conversation_id
  LEFT JOIN unread_message_counts umc ON uc.id = umc.conversation_id
  ORDER BY COALESCE(lm.created_at, uc.created_at) DESC;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';