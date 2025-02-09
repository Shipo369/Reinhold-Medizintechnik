-- Drop existing policies
DO $$ 
BEGIN
  -- Drop device_presentations policies
  DROP POLICY IF EXISTS "Allow read access to all authenticated users for presentations" ON device_presentations;
  DROP POLICY IF EXISTS "Allow all access to admins for presentations" ON device_presentations;
  
  -- Drop module_documents policies
  DROP POLICY IF EXISTS "Allow read access to all authenticated users for module_documents" ON module_documents;
  DROP POLICY IF EXISTS "Allow all access to admins for module_documents" ON module_documents;
END $$;

-- Create new policies for device_presentations
CREATE POLICY "presentations_read"
  ON device_presentations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "presentations_admin"
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

-- Create new policies for module_documents
CREATE POLICY "documents_read"
  ON module_documents
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "documents_admin"
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

-- Ensure RLS is enabled
ALTER TABLE device_presentations ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_documents ENABLE ROW LEVEL SECURITY;

-- Create function to check if user is authenticated
CREATE OR REPLACE FUNCTION auth.is_authenticated()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (auth.role() = 'authenticated');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is admin
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';