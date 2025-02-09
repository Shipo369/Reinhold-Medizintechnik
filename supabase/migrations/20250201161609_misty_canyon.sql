-- Drop existing storage policies
DROP POLICY IF EXISTS "documents_read" ON storage.objects;
DROP POLICY IF EXISTS "documents_admin" ON storage.objects;

-- Make module-documents bucket public
UPDATE storage.buckets
SET public = true
WHERE id = 'module-documents';

-- Create new storage policies
CREATE POLICY "documents_read"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'module-documents');

CREATE POLICY "documents_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'module-documents' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "documents_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'module-documents' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );