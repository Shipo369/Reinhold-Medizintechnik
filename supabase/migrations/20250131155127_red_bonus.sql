/*
  # Create presentations table and storage

  1. New Tables
    - `device_presentations`
      - `id` (uuid, primary key)
      - `device_type_id` (uuid, foreign key)
      - `file_path` (text)
      - `file_name` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Storage
    - Create presentations bucket
    - Add storage policies for authenticated users

  3. Security
    - Enable RLS on presentations table
    - Add policies for viewing and managing presentations
*/

-- Create presentations table
CREATE TABLE device_presentations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_type_id UUID REFERENCES device_types(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE device_presentations ENABLE ROW LEVEL SECURITY;

-- Create storage bucket for presentations
INSERT INTO storage.buckets (id, name, public)
VALUES ('presentations', 'presentations', false)
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX idx_device_presentations_device_type_id 
  ON device_presentations(device_type_id);

-- Update trigger for timestamps
CREATE TRIGGER update_device_presentations_updated_at
  BEFORE UPDATE ON device_presentations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Policies for device_presentations table
CREATE POLICY "Allow read access to all authenticated users for presentations"
  ON device_presentations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow all access to admins for presentations"
  ON device_presentations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Storage policies for presentations
CREATE POLICY "Allow read access to all authenticated users for presentations storage"
  ON storage.objects
  FOR SELECT
  TO authenticated
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
    )
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