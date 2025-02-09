/*
  # Device Management Schema

  1. New Tables
    - `device_types`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `description` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `device_models`
      - `id` (uuid, primary key)
      - `type_id` (uuid, foreign key to device_types)
      - `name` (text)
      - `description` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for admin CRUD operations
*/

-- Device Types Table
CREATE TABLE device_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Device Models Table
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
CREATE POLICY "Allow read access to all users for device_types"
  ON device_types
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow all access to admins for device_types"
  ON device_types
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for device_models
CREATE POLICY "Allow read access to all users for device_models"
  ON device_models
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow all access to admins for device_models"
  ON device_models
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Update function for timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_device_types_updated_at
  BEFORE UPDATE ON device_types
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_device_models_updated_at
  BEFORE UPDATE ON device_models
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();