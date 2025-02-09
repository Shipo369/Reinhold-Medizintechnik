-- Create MediChat tables

-- Create conversations table
CREATE TABLE medichat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  description TEXT,
  image_url TEXT,
  is_group BOOLEAN DEFAULT false,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create participants table
CREATE TABLE medichat_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES medichat_conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  last_read_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(conversation_id, user_id)
);

-- Create messages table with HIPAA compliance features
CREATE TABLE medichat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES medichat_conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_encrypted BOOLEAN DEFAULT true,
  is_delivered BOOLEAN DEFAULT false,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create pinned messages table with limit constraint
CREATE TABLE medichat_pinned_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES medichat_messages(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES medichat_conversations(id) ON DELETE CASCADE,
  pinned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(message_id, conversation_id)
);

-- Enable RLS
ALTER TABLE medichat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE medichat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE medichat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE medichat_pinned_messages ENABLE ROW LEVEL SECURITY;

-- Create storage bucket for profile pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'medichat-avatars',
  'medichat-avatars',
  true,
  2097152, -- 2MB limit
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
) ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 2097152,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Create indexes for better performance
CREATE INDEX idx_medichat_participants_conversation ON medichat_participants(conversation_id);
CREATE INDEX idx_medichat_participants_user ON medichat_participants(user_id);
CREATE INDEX idx_medichat_messages_conversation ON medichat_messages(conversation_id);
CREATE INDEX idx_medichat_messages_sender ON medichat_messages(sender_id);
CREATE INDEX idx_medichat_messages_created_at ON medichat_messages(created_at);
CREATE INDEX idx_medichat_pinned_messages_conversation ON medichat_pinned_messages(conversation_id);

-- Create RLS policies
CREATE POLICY "medichat_conversations_select"
  ON medichat_conversations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM medichat_participants
      WHERE conversation_id = id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "medichat_conversations_insert"
  ON medichat_conversations
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "medichat_participants_select"
  ON medichat_participants
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM medichat_participants
    WHERE conversation_id = medichat_participants.conversation_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "medichat_participants_insert"
  ON medichat_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "medichat_participants_update"
  ON medichat_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "medichat_messages_select"
  ON medichat_messages
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM medichat_participants
      WHERE conversation_id = medichat_messages.conversation_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "medichat_messages_insert"
  ON medichat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM medichat_participants
      WHERE conversation_id = medichat_messages.conversation_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "medichat_pinned_messages_select"
  ON medichat_pinned_messages
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM medichat_participants
      WHERE conversation_id = medichat_pinned_messages.conversation_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "medichat_pinned_messages_insert"
  ON medichat_pinned_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM medichat_participants
      WHERE conversation_id = medichat_pinned_messages.conversation_id
      AND user_id = auth.uid()
    )
  );

-- Create function to check pinned message limit
CREATE OR REPLACE FUNCTION check_pinned_message_limit()
RETURNS TRIGGER AS $$
DECLARE
  pinned_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO pinned_count
  FROM medichat_pinned_messages
  WHERE conversation_id = NEW.conversation_id;
  
  IF pinned_count >= 3 THEN
    RAISE EXCEPTION 'Maximum number of pinned messages (3) reached for this conversation';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for pinned message limit
CREATE TRIGGER check_pinned_message_limit_trigger
  BEFORE INSERT ON medichat_pinned_messages
  FOR EACH ROW
  EXECUTE FUNCTION check_pinned_message_limit();

-- Create function to update last read timestamp
CREATE OR REPLACE FUNCTION update_medichat_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE medichat_participants
  SET last_read_at = NOW()
  WHERE conversation_id = NEW.conversation_id
  AND user_id = NEW.sender_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for last seen updates
CREATE TRIGGER update_medichat_last_seen_trigger
  AFTER INSERT ON medichat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_medichat_last_seen();

-- Create function to enforce max group members
CREATE OR REPLACE FUNCTION check_medichat_group_size()
RETURNS TRIGGER AS $$
BEGIN
  IF (
    SELECT COUNT(*) 
    FROM medichat_participants
    WHERE conversation_id = NEW.conversation_id
  ) >= 50 THEN
    RAISE EXCEPTION 'Maximum group size of 50 members reached';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for group size check
CREATE TRIGGER check_medichat_group_size_trigger
  BEFORE INSERT ON medichat_participants
  FOR EACH ROW
  EXECUTE FUNCTION check_medichat_group_size();

-- Add module type for MediChat
ALTER TABLE user_module_access
  DROP CONSTRAINT IF EXISTS user_module_access_module_type_check,
  ADD CONSTRAINT user_module_access_module_type_check 
  CHECK (module_type IN ('training', 'events', 'medichat'));

-- Grant MediChat access to all users
INSERT INTO user_module_access (user_id, module_type)
SELECT DISTINCT p.id, 'medichat'
FROM profiles p
WHERE NOT EXISTS (
  SELECT 1 
  FROM user_module_access uma 
  WHERE uma.user_id = p.id 
  AND uma.module_type = 'medichat'
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';