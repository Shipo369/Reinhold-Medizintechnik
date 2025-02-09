-- Drop existing storage policies for presentations bucket
DROP POLICY IF EXISTS "Allow read access to all authenticated users for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow upload access to admins for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete access to admins for presentations storage" ON storage.objects;

-- Make presentations bucket public
UPDATE storage.buckets
SET public = true
WHERE id = 'presentations';

-- Create new storage policies with public access for reading
CREATE POLICY "Allow public read access for presentations storage"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'presentations');

CREATE POLICY "Allow upload access to admins for presentations storage"
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

CREATE POLICY "Allow delete access to admins for presentations storage"
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