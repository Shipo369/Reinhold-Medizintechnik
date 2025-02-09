-- Add last_seen_at column to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_last_seen 
  ON profiles(last_seen_at);

-- Create function to update last seen timestamp
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE profiles
  SET last_seen_at = NOW()
  WHERE id = auth.uid();
  RETURN NEW;
END;
$$;

-- Create trigger to update last seen on chat activity
DROP TRIGGER IF EXISTS update_last_seen_trigger ON chat_messages;
CREATE TRIGGER update_last_seen_trigger
  AFTER INSERT ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_user_last_seen();

-- Update RLS policies
CREATE POLICY "profiles_last_seen_update"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';