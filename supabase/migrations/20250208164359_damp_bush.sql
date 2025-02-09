-- Handle module access types carefully
DO $$
BEGIN
  -- First create a temporary table to store existing access records
  CREATE TEMP TABLE temp_access AS
  SELECT user_id, module_type
  FROM user_module_access
  WHERE module_type IN ('training', 'events');

  -- Then truncate the original table
  TRUNCATE user_module_access;

  -- Drop and recreate the constraint
  ALTER TABLE user_module_access
    DROP CONSTRAINT IF EXISTS user_module_access_module_type_check;
    
  ALTER TABLE user_module_access
    ADD CONSTRAINT user_module_access_module_type_check 
    CHECK (module_type IN ('training', 'events'));

  -- Restore the valid records
  INSERT INTO user_module_access (user_id, module_type)
  SELECT user_id, module_type FROM temp_access;

  -- Drop temporary table
  DROP TABLE temp_access;
END $$;

-- Remove storage objects and buckets
DO $$ 
BEGIN
  -- Delete all objects from chat-related buckets
  DELETE FROM storage.objects 
  WHERE bucket_id IN (
    'chat-files', 
    'group-avatars',
    'medichat-avatars'
  );
  
  -- Remove the buckets
  DELETE FROM storage.buckets 
  WHERE id IN (
    'chat-files', 
    'group-avatars',
    'medichat-avatars'
  );
END $$;

-- Drop all chat-related functions
DO $$ 
BEGIN
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
  DROP FUNCTION IF EXISTS check_pinned_message_limit CASCADE;
  DROP FUNCTION IF EXISTS update_medichat_last_seen CASCADE;
  DROP FUNCTION IF EXISTS check_medichat_group_size CASCADE;
  DROP FUNCTION IF EXISTS get_medichat_unread_count CASCADE;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- Drop all chat-related tables in correct order
DROP TABLE IF EXISTS medichat_pinned_messages CASCADE;
DROP TABLE IF EXISTS medichat_messages CASCADE;
DROP TABLE IF EXISTS medichat_participants CASCADE;
DROP TABLE IF EXISTS medichat_group_admins CASCADE;
DROP TABLE IF EXISTS medichat_conversations CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_participants CASCADE;
DROP TABLE IF EXISTS chat_group_admins CASCADE;
DROP TABLE IF EXISTS chat_conversations CASCADE;
DROP TABLE IF EXISTS online_users CASCADE;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';