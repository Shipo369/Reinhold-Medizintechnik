-- Add group chat support
ALTER TABLE chat_conversations
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- Create group admins table
CREATE TABLE chat_group_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES chat_conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(conversation_id, user_id)
);

-- Enable RLS
ALTER TABLE chat_group_admins ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_chat_conversations_is_group ON chat_conversations(is_group);
CREATE INDEX idx_chat_group_admins_conversation ON chat_group_admins(conversation_id);
CREATE INDEX idx_chat_group_admins_user ON chat_group_admins(user_id);

-- Create storage bucket for group images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'group-avatars',
  'group-avatars',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Create policies
CREATE POLICY "group_admins_access"
  ON chat_group_admins
  FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM chat_group_admins
      WHERE conversation_id = chat_group_admins.conversation_id
      AND user_id = auth.uid()
    )
  );

-- Create function to create a group chat
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

  -- Add creator as admin
  INSERT INTO chat_group_admins (conversation_id, user_id)
  VALUES (v_conversation_id, auth.uid());

  -- Add creator as participant
  INSERT INTO chat_participants (conversation_id, user_id)
  VALUES (v_conversation_id, auth.uid());

  -- Add other members if provided
  IF p_member_ids IS NOT NULL THEN
    FOREACH v_member_id IN ARRAY p_member_ids
    LOOP
      INSERT INTO chat_participants (conversation_id, user_id)
      VALUES (v_conversation_id, v_member_id)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN v_conversation_id;
END;
$$;

-- Create function to add members to a group
CREATE OR REPLACE FUNCTION add_group_members(
  p_conversation_id UUID,
  p_member_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_member_id UUID;
BEGIN
  -- Check if user is group admin
  IF NOT EXISTS (
    SELECT 1 FROM chat_group_admins
    WHERE conversation_id = p_conversation_id
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only group admins can add members';
  END IF;

  -- Add members
  FOREACH v_member_id IN ARRAY p_member_ids
  LOOP
    INSERT INTO chat_participants (conversation_id, user_id)
    VALUES (p_conversation_id, v_member_id)
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$;

-- Create function to remove members from a group
CREATE OR REPLACE FUNCTION remove_group_member(
  p_conversation_id UUID,
  p_member_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if user is group admin
  IF NOT EXISTS (
    SELECT 1 FROM chat_group_admins
    WHERE conversation_id = p_conversation_id
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only group admins can remove members';
  END IF;

  -- Remove member
  DELETE FROM chat_participants
  WHERE conversation_id = p_conversation_id
  AND user_id = p_member_id;

  -- Also remove from admins if they were an admin
  DELETE FROM chat_group_admins
  WHERE conversation_id = p_conversation_id
  AND user_id = p_member_id;
END;
$$;

-- Create function to make a member an admin
CREATE OR REPLACE FUNCTION make_group_admin(
  p_conversation_id UUID,
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if user is group admin
  IF NOT EXISTS (
    SELECT 1 FROM chat_group_admins
    WHERE conversation_id = p_conversation_id
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only group admins can promote members to admin';
  END IF;

  -- Make user an admin
  INSERT INTO chat_group_admins (conversation_id, user_id)
  VALUES (p_conversation_id, p_user_id)
  ON CONFLICT DO NOTHING;
END;
$$;

-- Create storage policies for group avatars
CREATE POLICY "group_avatars_select"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'group-avatars');

CREATE POLICY "group_avatars_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'group-avatars' AND
    EXISTS (
      SELECT 1 FROM chat_group_admins
      WHERE conversation_id = (storage.foldername(name))[1]::uuid
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "group_avatars_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'group-avatars' AND
    EXISTS (
      SELECT 1 FROM chat_group_admins
      WHERE conversation_id = (storage.foldername(name))[1]::uuid
      AND user_id = auth.uid()
    )
  );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';