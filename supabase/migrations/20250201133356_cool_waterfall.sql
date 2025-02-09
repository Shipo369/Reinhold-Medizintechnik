-- Drop existing storage policies
DROP POLICY IF EXISTS "presentations_read" ON storage.objects;
DROP POLICY IF EXISTS "presentations_insert" ON storage.objects;
DROP POLICY IF EXISTS "presentations_delete" ON storage.objects;

-- Update storage bucket configuration to allow image types
UPDATE storage.buckets
SET public = true,
    file_size_limit = 5242880, -- 5MB
    allowed_mime_types = ARRAY[
      'image/png',
      'image/jpeg',
      'image/gif',
      'image/webp',
      'image/svg+xml'
    ]
WHERE id = 'presentations';

-- Create new storage policies
CREATE POLICY "presentations_read"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'presentations');

CREATE POLICY "presentations_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'presentations' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "presentations_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'presentations' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';