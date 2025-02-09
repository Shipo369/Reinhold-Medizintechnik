-- Drop existing storage policies
DROP POLICY IF EXISTS "chat_files_select" ON storage.objects;
DROP POLICY IF EXISTS "chat_files_insert" ON storage.objects;
DROP POLICY IF EXISTS "chat_files_delete" ON storage.objects;

-- Create storage bucket for chat files if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-files',
  'chat-files',
  true, -- Make bucket public for easier image display
  52428800, -- 50MB limit
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
) ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ];

-- Create more permissive storage policies
CREATE POLICY "chat_files_select"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'chat-files');

CREATE POLICY "chat_files_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'chat-files');

CREATE POLICY "chat_files_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'chat-files');

-- Update chat_messages policies to be more permissive for file handling
DROP POLICY IF EXISTS "chat_messages_all_access" ON chat_messages;

CREATE POLICY "chat_messages_all_access"
  ON chat_messages
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';