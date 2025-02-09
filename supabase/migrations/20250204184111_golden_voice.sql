-- Drop existing table if it exists
DROP TABLE IF EXISTS user_device_access;

-- Create user device access table with correct schema
CREATE TABLE user_device_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, device_model_id)
);

-- Enable RLS
ALTER TABLE user_device_access ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_user_device_access_user_id ON user_device_access(user_id);
CREATE INDEX idx_user_device_access_device_model_id ON user_device_access(device_model_id);

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

-- Create trigger for updated_at
CREATE TRIGGER update_user_device_access_updated_at
  BEFORE UPDATE ON user_device_access
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();