/*
  # Fix device management tables

  1. New Tables
    - `device_types`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `description` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `device_models`
      - `id` (uuid, primary key)
      - `type_id` (uuid, references device_types)
      - `name` (text)
      - `description` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to read
    - Add policies for admins to manage
*/

-- Drop existing tables if they exist
DROP TABLE IF EXISTS device_models;
DROP TABLE IF EXISTS device_types;

-- Create device_types table
CREATE TABLE device_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create device_models table
CREATE TABLE device_models (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_id UUID REFERENCES device_types(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(type_id, name)
);

-- Enable RLS
ALTER TABLE device_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- Policies for device_types
CREATE POLICY "Allow read access to all authenticated users for device_types"
  ON device_types
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow all access to admins for device_types"
  ON device_types
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for device_models
CREATE POLICY "Allow read access to all authenticated users for device_models"
  ON device_models
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow all access to admins for device_models"
  ON device_models
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Update triggers for timestamps
CREATE TRIGGER update_device_types_updated_at
  BEFORE UPDATE ON device_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_device_models_updated_at
  BEFORE UPDATE ON device_models
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert some initial device types
INSERT INTO device_types (name, description) VALUES
  ('Laborgeräte', 'Geräte für Laboranalysen und -untersuchungen'),
  ('Diagnostikgeräte', 'Geräte für medizinische Diagnostik'),
  ('Monitoringgeräte', 'Geräte zur Patientenüberwachung')
ON CONFLICT (name) DO NOTHING;

-- Insert some initial device models
DO $$
DECLARE
  lab_type_id UUID;
BEGIN
  SELECT id INTO lab_type_id FROM device_types WHERE name = 'Laborgeräte';
  
  IF lab_type_id IS NOT NULL THEN
    INSERT INTO device_models (type_id, name, description) VALUES
      (lab_type_id, 'Analysegerät XS-2000', 'Kompaktes Analysegerät für kleine bis mittlere Labore'),
      (lab_type_id, 'Analysegerät XS-3000', 'Hochdurchsatz-Analysegerät für große Labore')
    ON CONFLICT (type_id, name) DO NOTHING;
  END IF;
END $$;