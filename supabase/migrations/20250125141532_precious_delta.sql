/*
  # Fix module_documents table schema

  1. Changes
    - Drop and recreate module_documents table with correct columns
    - Add proper constraints and indexes
    - Enable RLS policies
*/

-- Drop existing table if it exists
DROP TABLE IF EXISTS module_documents;

-- Create module_documents table with correct schema
CREATE TABLE module_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE module_documents ENABLE ROW LEVEL SECURITY;

-- Add index for better query performance
CREATE INDEX idx_module_documents_device_model_id ON module_documents(device_model_id);

-- Policies for module_documents
CREATE POLICY "Users can view module documents"
  ON module_documents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage module documents"
  ON module_documents
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Update trigger for timestamps
CREATE TRIGGER update_module_documents_updated_at
  BEFORE UPDATE ON module_documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();