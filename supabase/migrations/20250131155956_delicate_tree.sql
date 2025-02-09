-- Add file_type column to device_presentations
ALTER TABLE device_presentations
  ADD COLUMN file_type TEXT NOT NULL DEFAULT 'application/pdf'
  CHECK (file_type IN ('application/pdf'));

-- Update existing records to PDF type
UPDATE device_presentations
SET file_type = 'application/pdf'
WHERE file_type IS NULL;

-- Add index for file type
CREATE INDEX idx_device_presentations_file_type 
  ON device_presentations(file_type);

-- Update storage policy to restrict file types
DROP POLICY IF EXISTS "Allow upload access to admins for presentations storage" ON storage.objects;
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
    -- Only allow PDF files
    (LOWER(RIGHT(name, 4)) = '.pdf')
  );