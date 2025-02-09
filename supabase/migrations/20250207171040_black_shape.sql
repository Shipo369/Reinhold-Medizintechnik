-- Drop existing policy if it exists
DROP POLICY IF EXISTS "universal_chat_access" ON user_module_access;

-- Update module type check constraint
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

-- Create new policy with unique name
CREATE POLICY "chat_module_access_v2"
  ON user_module_access
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';