-- Add chat module type to check constraint
ALTER TABLE user_module_access
  DROP CONSTRAINT IF EXISTS user_module_access_module_type_check,
  ADD CONSTRAINT user_module_access_module_type_check 
  CHECK (module_type IN ('training', 'events', 'chat'));

-- Grant chat access to all existing users
INSERT INTO user_module_access (user_id, module_type)
SELECT DISTINCT p.id, 'chat'
FROM profiles p
WHERE NOT EXISTS (
  SELECT 1 
  FROM user_module_access uma 
  WHERE uma.user_id = p.id 
  AND uma.module_type = 'chat'
);

-- Create policy for chat access
CREATE POLICY "chat_module_access"
  ON user_module_access
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';