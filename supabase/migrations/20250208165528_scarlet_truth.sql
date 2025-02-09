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

-- Create messages table
CREATE TABLE medichat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES medichat_conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE medichat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE medichat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE medichat_messages ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX idx_medichat_participants_conversation ON medichat_participants(conversation_id);
CREATE INDEX idx_medichat_participants_user ON medichat_participants(user_id);
CREATE INDEX idx_medichat_messages_conversation ON medichat_messages(conversation_id);
CREATE INDEX idx_medichat_messages_sender ON medichat_messages(sender_id);
CREATE INDEX idx_medichat_messages_created_at ON medichat_messages(created_at);

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

-- Add module type for MediChat
DO $$
BEGIN
  -- First remove the constraint
  ALTER TABLE user_module_access
    DROP CONSTRAINT IF EXISTS user_module_access_module_type_check;
  
  -- Then add it back with medichat
  ALTER TABLE user_module_access
    ADD CONSTRAINT user_module_access_module_type_check 
    CHECK (module_type IN ('training', 'events', 'medichat'));
END $$;

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