-- Drop existing avatar policies
DROP POLICY IF EXISTS "avatars_select" ON storage.objects;
DROP POLICY IF EXISTS "avatars_insert" ON storage.objects;
DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
DROP POLICY IF EXISTS "avatars_delete" ON storage.objects;

-- Make avatars bucket public and update configuration
UPDATE storage.buckets
SET public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY[
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp'
    ]
WHERE id = 'avatars';

-- Create simpler, more permissive policies for avatars
CREATE POLICY "avatars_select_policy"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert_policy"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "avatars_delete_policy"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'avatars');

-- Update profiles policies to allow avatar updates
DROP POLICY IF EXISTS "profiles_update_avatar" ON profiles;

CREATE POLICY "profiles_avatar_update"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Create function to handle avatar updates
CREATE OR REPLACE FUNCTION handle_avatar_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only allow users to update their own avatar
  IF NEW.id != auth.uid() THEN
    RAISE EXCEPTION 'You can only update your own avatar';
  END IF;

  -- Keep original values for protected fields
  NEW.email := OLD.email;
  NEW.role := OLD.role;
  NEW.status := OLD.status;
  
  RETURN NEW;
END;
$$;

-- Create trigger for avatar updates
DROP TRIGGER IF EXISTS on_avatar_update ON profiles;
CREATE TRIGGER on_avatar_update
  BEFORE UPDATE OF avatar_url ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION handle_avatar_update();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';