-- First delete all files from storage buckets
DELETE FROM storage.objects WHERE bucket_id = 'chat-files';
DELETE FROM storage.objects WHERE bucket_id = 'group-avatars';

-- Then delete the buckets
DELETE FROM storage.buckets WHERE id = 'chat-files';
DELETE FROM storage.buckets WHERE id = 'group-avatars';

-- Drop all chat-related tables
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

-- Remove chat module access type
DELETE FROM user_module_access WHERE module_type = 'chat';
ALTER TABLE user_module_access
  DROP CONSTRAINT IF EXISTS user_module_access_module_type_check,
  ADD CONSTRAINT user_module_access_module_type_check 
  CHECK (module_type IN ('training', 'events'));

-- Drop chat-related policies
DO $$ 
BEGIN
  -- Drop policies if they exist
  DROP POLICY IF EXISTS "chat_conversations_access_v6" ON chat_conversations;
  DROP POLICY IF EXISTS "chat_participants_access_v6" ON chat_participants;
  DROP POLICY IF EXISTS "chat_messages_access_v6" ON chat_messages;
  DROP POLICY IF EXISTS "chat_files_select" ON storage.objects;
  DROP POLICY IF EXISTS "chat_files_insert" ON storage.objects;
  DROP POLICY IF EXISTS "chat_files_delete" ON storage.objects;
  DROP POLICY IF EXISTS "group_avatars_select" ON storage.objects;
  DROP POLICY IF EXISTS "group_avatars_insert" ON storage.objects;
  DROP POLICY IF EXISTS "group_avatars_delete" ON storage.objects;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';