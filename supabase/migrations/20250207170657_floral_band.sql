-- Drop existing policy if it exists
DROP POLICY IF EXISTS "chat_module_access" ON user_module_access;

-- Create policy for chat access
CREATE POLICY "chat_module_access_policy"
  ON user_module_access
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Update module type check constraint to include chat
ALTER TABLE user_module_access
  DROP CONSTRAINT IF EXISTS user_module_access_module_type_check;

ALTER TABLE user_module_access
  ADD CONSTRAINT user_module_access_module_type_check 
  CHECK (module_type IN ('training', 'events', 'chat'));

-- Grant chat access to all existing users
INSERT INTO user_module_access (user_id, module_type)
SELECT DISTINCT p.id, 'chat'::text
FROM profiles p
WHERE NOT EXISTS (
  SELECT 1 
  FROM user_module_access uma 
  WHERE uma.user_id = p.id 
  AND uma.module_type = 'chat'
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';