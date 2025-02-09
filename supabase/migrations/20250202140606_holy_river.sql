-- Create storage bucket for certificates if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'certificates',
  'certificates',
  false,
  5242880, -- 5MB limit
  ARRAY['application/pdf']
) ON CONFLICT (id) DO UPDATE
SET 
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['application/pdf'];

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Allow admin upload access for certificates" ON storage.objects;
DROP POLICY IF EXISTS "Allow admin delete access for certificates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to download certificates" ON storage.objects;
DROP POLICY IF EXISTS "certificates_admin_upload" ON storage.objects;
DROP POLICY IF EXISTS "certificates_admin_delete" ON storage.objects;
DROP POLICY IF EXISTS "certificates_download" ON storage.objects;

-- Create new storage policies
CREATE POLICY "certificates_admin_upload"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'certificates' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "certificates_admin_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'certificates' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "certificates_download"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'certificates' AND
    EXISTS (
      SELECT 1 FROM certificate_requests cr
      WHERE cr.file_path = name
      AND (
        cr.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles
          WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'
        )
      )
    )
  );