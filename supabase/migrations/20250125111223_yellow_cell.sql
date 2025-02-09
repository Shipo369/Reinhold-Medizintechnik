/*
  # Create documents table and storage

  1. New Tables
    - `documents`
      - `id` (uuid, primary key)
      - `name` (text, not null)
      - `description` (text)
      - `file_path` (text, not null)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Storage
    - Create new storage bucket for documents
    
  3. Security
    - Enable RLS on documents table
    - Add policies for authenticated users to read documents
    - Add policies for admins to manage documents
    - Add storage policies for document access
*/

-- Create documents table
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  file_path TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create storage bucket
INSERT INTO storage.buckets (id, name)
VALUES ('documents', 'documents')
ON CONFLICT DO NOTHING;

-- Policies for documents table
CREATE POLICY "Allow read access to all authenticated users for documents"
  ON documents
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow all access to admins for documents"
  ON documents
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Storage policies
CREATE POLICY "Allow read access to all authenticated users"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'documents');

CREATE POLICY "Allow upload access to admins"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'documents' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Allow delete access to admins"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'documents' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Update trigger for updated_at
CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();