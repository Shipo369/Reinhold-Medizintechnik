-- Drop existing table if it exists
DROP TABLE IF EXISTS device_presentations;

-- Create device_presentations table with correct structure
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

-- Drop existing policies
DROP POLICY IF EXISTS "presentations_read" ON device_presentations;
DROP POLICY IF EXISTS "presentations_admin" ON device_presentations;

-- Create new policies with better names and explicit permissions
CREATE POLICY "allow_read_presentations"
  ON device_presentations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_admin_all_presentations"
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

-- Create helper function to check presentation access
CREATE OR REPLACE FUNCTION check_presentation_access(presentation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    -- User is authenticated
    auth.role() = 'authenticated'
    AND
    -- Either user is admin or presentation exists
    (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
      )
      OR
      EXISTS (
        SELECT 1 FROM device_presentations
        WHERE id = presentation_id
      )
    )
  );
END;
$$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON device_presentations TO authenticated;
GRANT EXECUTE ON FUNCTION check_presentation_access TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';