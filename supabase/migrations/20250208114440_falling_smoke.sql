-- Drop existing function
DROP FUNCTION IF EXISTS create_group_chat(TEXT, TEXT, UUID[]);

-- Create improved group chat function
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
    RAISE EXCEPTION 'Gruppenname ist erforderlich';
  END IF;

  IF p_member_ids IS NULL OR array_length(p_member_ids, 1) = 0 THEN
    RAISE EXCEPTION 'Mindestens ein Mitglied muss ausgewählt werden';
  END IF;

  -- Create new group conversation
  INSERT INTO chat_conversations (
    name,
    description,
    is_group,
    created_by,
    created_at
  )
  VALUES (
    p_name,
    p_description,
    true,
    auth.uid(),
    NOW()
  )
  RETURNING id INTO v_conversation_id;

  -- Add creator as participant
  INSERT INTO chat_participants (conversation_id, user_id, created_at)
  VALUES (v_conversation_id, auth.uid(), NOW());

  -- Add other members
  FOREACH v_member_id IN ARRAY p_member_ids
  LOOP
    -- Skip if member ID is the same as creator
    IF v_member_id != auth.uid() THEN
      BEGIN
        INSERT INTO chat_participants (conversation_id, user_id, created_at)
        VALUES (v_conversation_id, v_member_id, NOW());
      EXCEPTION WHEN OTHERS THEN
        -- Log error but continue with other members
        RAISE WARNING 'Konnte Mitglied % nicht hinzufügen: %', v_member_id, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Create system message to announce group creation
  INSERT INTO chat_messages (
    conversation_id,
    sender_id,
    content,
    created_at
  )
  VALUES (
    v_conversation_id,
    auth.uid(),
    'Gruppe wurde erstellt',
    NOW()
  );

  RETURN v_conversation_id;
END;
$$;

-- Create function to get group details
CREATE OR REPLACE FUNCTION get_group_details(p_conversation_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  image_url TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  member_count BIGINT,
  members JSONB
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
    c.created_by,
    c.created_at,
    COUNT(DISTINCT cp.user_id)::BIGINT as member_count,
    jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'email', p.email,
        'avatar_url', p.avatar_url
      )
    ) as members
  FROM chat_conversations c
  JOIN chat_participants cp ON c.id = cp.conversation_id
  JOIN profiles p ON cp.user_id = p.id
  WHERE c.id = p_conversation_id
  AND c.is_group = true
  GROUP BY c.id;
END;
$$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';