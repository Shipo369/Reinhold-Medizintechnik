-- First handle the module access constraint
DO $$
BEGIN
  -- Temporarily disable the constraint
  ALTER TABLE user_module_access
    DROP CONSTRAINT IF EXISTS user_module_access_module_type_check;

  -- Delete chat-related module access entries
  DELETE FROM user_module_access 
  WHERE module_type IN ('chat', 'medichat');

  -- Re-add the constraint with allowed values
  ALTER TABLE user_module_access
    ADD CONSTRAINT user_module_access_module_type_check 
    CHECK (module_type IN ('training', 'events'));
END $$;

-- Now proceed with cleanup
DO $$ 
BEGIN
  -- Delete all objects from chat-related buckets
  DELETE FROM storage.objects 
  WHERE bucket_id IN ('chat-files', 'group-avatars');
  
  -- Remove the buckets
  DELETE FROM storage.buckets 
  WHERE id IN ('chat-files', 'group-avatars');
END $$;

-- Drop all chat-related tables in correct order
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_participants CASCADE;
DROP TABLE IF EXISTS chat_group_admins CASCADE;
DROP TABLE IF EXISTS chat_conversations CASCADE;
DROP TABLE IF EXISTS online_users CASCADE;

-- Drop chat-related functions
DROP FUNCTION IF EXISTS update_last_seen CASCADE;
DROP FUNCTION IF EXISTS get_unread_count CASCADE;
DROP FUNCTION IF EXISTS start_conversation CASCADE;
DROP FUNCTION IF EXISTS mark_conversation_read CASCADE;
DROP FUNCTION IF EXISTS get_user_conversations CASCADE;
DROP FUNCTION IF EXISTS get_user_conversations_v2 CASCADE;
DROP FUNCTION IF EXISTS mark_conversation_read_v2 CASCADE;
DROP FUNCTION IF EXISTS create_group_chat CASCADE;
DROP FUNCTION IF EXISTS get_group_details CASCADE;
DROP FUNCTION IF EXISTS add_group_members CASCADE;
DROP FUNCTION IF EXISTS remove_group_member CASCADE;
DROP FUNCTION IF EXISTS make_group_admin CASCADE;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';