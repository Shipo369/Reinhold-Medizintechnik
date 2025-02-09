/*
  # Create certificates table and storage

  1. New Tables
    - `certificates`
      - `id` (uuid, primary key)
      - `device_model_id` (uuid, references device_models)
      - `title` (text)
      - `description` (text)
      - `file_path` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Storage
    - Create certificates bucket
    - Add storage policies for secure access

  3. Security
    - Enable RLS on certificates table
    - Add policies for viewing and managing certificates
*/

-- Create certificates table
CREATE TABLE certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  file_path TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

-- Create storage bucket for certificates
INSERT INTO storage.buckets (id, name, public)
VALUES ('certificates', 'certificates', false)
ON CONFLICT DO NOTHING;

-- Policies for certificates table
CREATE POLICY "Allow read access to all authenticated users for certificates"
  ON certificates
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow all access to admins for certificates"
  ON certificates
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Storage policies for certificates
CREATE POLICY "Allow read access to all authenticated users for certificates storage"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'certificates');

CREATE POLICY "Allow upload access to admins for certificates storage"
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

CREATE POLICY "Allow delete access to admins for certificates storage"
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

-- Add indexes for better performance
CREATE INDEX idx_certificates_device_model_id 
  ON certificates(device_model_id);

-- Update trigger for timestamps
CREATE TRIGGER update_certificates_updated_at
  BEFORE UPDATE ON certificates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();