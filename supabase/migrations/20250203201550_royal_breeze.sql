-- Add missing indexes and policies for user_device_access

-- Create indexes for better performance if they don't exist
CREATE INDEX IF NOT EXISTS idx_user_device_access_user_id ON user_device_access(user_id);
CREATE INDEX IF NOT EXISTS idx_user_device_access_device_type_id ON user_device_access(device_type_id);

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own device access" ON user_device_access;
DROP POLICY IF EXISTS "Admins can manage all device access" ON user_device_access;

-- Create policies
CREATE POLICY "Users can view their own device access"
  ON user_device_access
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all device access"
  ON user_device_access
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
      AND profiles.status = 'approved'
    )
  );

-- Create trigger for updated_at if it doesn't exist
DROP TRIGGER IF EXISTS update_user_device_access_updated_at ON user_device_access;
CREATE TRIGGER update_user_device_access_updated_at
  BEFORE UPDATE ON user_device_access
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();