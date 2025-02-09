-- Add file handling columns to chat_messages
ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS file_path TEXT,
  ADD COLUMN IF NOT EXISTS file_type TEXT;

-- Create storage bucket for chat files if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-files', 'chat-files', false)
ON CONFLICT DO NOTHING;

-- Create storage policies for chat files
CREATE POLICY "chat_files_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'chat-files' AND
    (EXISTS (
      SELECT 1 FROM chat_messages m
      JOIN chat_participants p ON m.conversation_id = p.conversation_id
      WHERE m.file_path = name
      AND p.user_id = auth.uid()
    ))
  );

CREATE POLICY "chat_files_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'chat-files' AND
    (EXISTS (
      SELECT 1 FROM chat_participants
      WHERE conversation_id = (SELECT conversation_id FROM chat_messages WHERE file_path = name LIMIT 1)
      AND user_id = auth.uid()
    ))
  );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';