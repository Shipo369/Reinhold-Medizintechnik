-- Drop existing storage policies for presentations bucket
DROP POLICY IF EXISTS "Allow read access to all authenticated users for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow upload access to admins for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete access to admins for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access for presentations" ON storage.objects;
DROP POLICY IF EXISTS "Allow admin upload for presentations" ON storage.objects;
DROP POLICY IF EXISTS "Allow admin delete for presentations" ON storage.objects;

-- Make presentations bucket public and set correct configuration
UPDATE storage.buckets
SET public = true,
    file_size_limit = 52428800, -- 50MB
    allowed_mime_types = ARRAY['application/pdf']
WHERE id = 'presentations';

-- Create new storage policies with simpler names
CREATE POLICY "presentations_public_read"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'presentations');

CREATE POLICY "presentations_admin_upload"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'presentations' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    ) AND
    (LOWER(RIGHT(name, 4)) = '.pdf')
  );

CREATE POLICY "presentations_admin_delete"
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