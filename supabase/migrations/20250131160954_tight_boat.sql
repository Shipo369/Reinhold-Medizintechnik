-- Drop existing presentations table if it exists
DROP TABLE IF EXISTS device_presentations;

-- Create new device_presentations table
CREATE TABLE device_presentations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_type_id UUID REFERENCES device_types(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE device_presentations ENABLE ROW LEVEL SECURITY;

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