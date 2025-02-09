-- Drop all existing storage policies for presentations bucket
DO $$ 
BEGIN
  -- Drop policies if they exist
  DROP POLICY IF EXISTS "presentations_public_read" ON storage.objects;
  DROP POLICY IF EXISTS "presentations_admin_upload" ON storage.objects;
  DROP POLICY IF EXISTS "presentations_admin_delete" ON storage.objects;
  DROP POLICY IF EXISTS "Allow read access to all authenticated users for presentations storage" ON storage.objects;
  DROP POLICY IF EXISTS "Allow upload access to admins for presentations storage" ON storage.objects;
  DROP POLICY IF EXISTS "Allow delete access to admins for presentations storage" ON storage.objects;
  DROP POLICY IF EXISTS "Allow public read access for presentations storage" ON storage.objects;
  DROP POLICY IF EXISTS "Allow public read access for presentations" ON storage.objects;
  DROP POLICY IF EXISTS "Allow admin upload for presentations" ON storage.objects;
  DROP POLICY IF EXISTS "Allow admin delete for presentations" ON storage.objects;
END $$;

-- Ensure bucket exists and is configured correctly
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'presentations',
  'presentations',
  true,
  52428800,
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO UPDATE
SET 
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['application/pdf'];

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
    ) AND
    (LOWER(RIGHT(name, 4)) = '.pdf')
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

-- Ensure RLS is enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';