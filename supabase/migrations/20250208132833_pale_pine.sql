-- Drop existing function
DROP FUNCTION IF EXISTS get_user_conversations_v2();

-- Create improved function with explicit column references and better CTEs
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
    -- Get all conversations where user is a participant
    SELECT DISTINCT 
      c.id as conversation_id,
      c.name,
      c.description,
      c.image_url,
      c.is_group,
      c.created_by,
      c.created_at
    FROM chat_conversations c
    JOIN chat_participants p ON c.id = p.conversation_id
    WHERE p.user_id = v_user_id
  ),
  latest_messages AS (
    -- Get last message for each conversation
    SELECT DISTINCT ON (m.conversation_id)
      m.conversation_id,
      m.id as message_id,
      m.content,
      m.sender_id,
      m.file_path,
      m.file_type,
      m.created_at,
      p.full_name,
      p.email,
      p.avatar_url
    FROM chat_messages m
    JOIN profiles p ON m.sender_id = p.id
    WHERE m.conversation_id IN (SELECT conversation_id FROM user_conversations)
    ORDER BY m.conversation_id, m.created_at DESC
  ),
  conversation_participants AS (
    -- Get all participants for each conversation
    SELECT 
      p.conversation_id,
      jsonb_agg(
        jsonb_build_object(
          'id', pr.id,
          'full_name', pr.full_name,
          'email', pr.email,
          'avatar_url', pr.avatar_url
        )
      ) as participants
    FROM chat_participants p
    JOIN profiles pr ON p.user_id = pr.id
    WHERE p.conversation_id IN (SELECT conversation_id FROM user_conversations)
    GROUP BY p.conversation_id
  ),
  unread_message_counts AS (
    -- Calculate unread messages for each conversation
    SELECT 
      m.conversation_id,
      COUNT(*) as unread_count
    FROM chat_messages m
    JOIN chat_participants p ON m.conversation_id = p.conversation_id
    WHERE p.user_id = v_user_id
    AND m.created_at > p.last_read_at
    AND m.sender_id != v_user_id
    GROUP BY m.conversation_id
  )
  SELECT 
    uc.conversation_id as id,
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
  LEFT JOIN latest_messages lm ON uc.conversation_id = lm.conversation_id
  LEFT JOIN conversation_participants cp ON uc.conversation_id = cp.conversation_id
  LEFT JOIN unread_message_counts umc ON uc.conversation_id = umc.conversation_id
  ORDER BY COALESCE(lm.created_at, uc.created_at) DESC;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';