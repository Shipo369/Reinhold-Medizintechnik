-- Create user module access table
CREATE TABLE user_module_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  module_type TEXT NOT NULL CHECK (module_type IN ('training', 'events')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, module_type)
);

-- Enable RLS
ALTER TABLE user_module_access ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_user_module_access_user_id ON user_module_access(user_id);
CREATE INDEX idx_user_module_access_module_type ON user_module_access(module_type);

-- Create policies
CREATE POLICY "Users can view their own module access"
  ON user_module_access
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all module access"
  ON user_module_access
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
CREATE TRIGGER update_user_module_access_updated_at
  BEFORE UPDATE ON user_module_access
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();