-- Drop existing policies
DROP POLICY IF EXISTS "chat_module_access" ON user_module_access;
DROP POLICY IF EXISTS "chat_module_access_policy" ON user_module_access;

-- Create new permissive policy for chat module access
CREATE POLICY "universal_chat_access"
  ON user_module_access
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

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

-- Create trigger to automatically grant chat access to new users
CREATE OR REPLACE FUNCTION auto_grant_chat_access()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_module_access (user_id, module_type)
  VALUES (NEW.id, 'chat');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that runs after new profile creation
DROP TRIGGER IF EXISTS grant_chat_access_trigger ON profiles;
CREATE TRIGGER grant_chat_access_trigger
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION auto_grant_chat_access();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';