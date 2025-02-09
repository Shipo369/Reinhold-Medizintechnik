-- Drop existing function
DROP FUNCTION IF EXISTS get_user_conversations_v2();

-- Create improved function with unread count and fixed column references
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
  WITH RECURSIVE user_convs AS (
    -- Get all conversations where user is a participant
    SELECT DISTINCT c.*
    FROM chat_conversations c
    JOIN chat_participants cp ON c.id = cp.conversation_id
    WHERE cp.user_id = v_user_id
  ),
  last_msgs AS (
    -- Get last message for each conversation
    SELECT DISTINCT ON (conversation_id)
      conversation_id,
      id as message_id,
      content,
      sender_id,
      file_path,
      file_type,
      created_at,
      p.full_name,
      p.email,
      p.avatar_url
    FROM chat_messages m
    JOIN profiles p ON m.sender_id = p.id
    WHERE conversation_id IN (SELECT id FROM user_convs)
    ORDER BY conversation_id, created_at DESC
  ),
  conv_participants AS (
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
    WHERE cp.conversation_id IN (SELECT id FROM user_convs)
    GROUP BY cp.conversation_id
  ),
  unread_counts AS (
    -- Calculate unread messages for each conversation
    SELECT 
      m.conversation_id,
      COUNT(*) as unread_count
    FROM chat_messages m
    JOIN chat_participants cp ON m.conversation_id = cp.conversation_id
    WHERE cp.user_id = v_user_id
    AND m.created_at > cp.last_read_at
    AND m.sender_id != v_user_id
    GROUP BY m.conversation_id
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
    COALESCE(uc2.unread_count, 0) as unread_count
  FROM user_convs uc
  LEFT JOIN last_msgs lm ON uc.id = lm.conversation_id
  LEFT JOIN conv_participants cp ON uc.id = cp.conversation_id
  LEFT JOIN unread_counts uc2 ON uc.id = uc2.conversation_id
  ORDER BY COALESCE(lm.created_at, uc.created_at) DESC;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';