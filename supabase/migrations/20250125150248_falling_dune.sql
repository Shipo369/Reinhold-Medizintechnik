/*
  # Fix event participants relationship

  1. Changes
    - Add foreign key relationship between event_participants and profiles
    - Add index for better query performance
    - Update RLS policies to ensure proper access control

  2. Security
    - Maintain existing RLS policies
    - Ensure proper access control for participant data
*/

-- Add user_id foreign key reference to profiles
ALTER TABLE event_participants
  DROP CONSTRAINT IF EXISTS event_participants_user_id_fkey,
  ADD CONSTRAINT event_participants_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES profiles(id)
  ON DELETE CASCADE;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_event_participants_user_id_profile
  ON event_participants(user_id);

-- Ensure RLS policies are up to date
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;

-- Recreate policies with proper access control
DO $$ 
BEGIN
  -- Drop existing policies
  DROP POLICY IF EXISTS "Users can view their own registrations" ON event_participants;
  DROP POLICY IF EXISTS "Admins can view all registrations" ON event_participants;
  DROP POLICY IF EXISTS "Users can register for events" ON event_participants;
  DROP POLICY IF EXISTS "Users can update their own registrations" ON event_participants;

  -- Recreate policies
  CREATE POLICY "Users can view their own registrations"
    ON event_participants
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

  CREATE POLICY "Admins can view all registrations"
    ON event_participants
    FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
      )
    );

  CREATE POLICY "Users can register for events"
    ON event_participants
    FOR INSERT
    TO authenticated
    WITH CHECK (
      user_id = auth.uid() AND
      NOT EXISTS (
        SELECT 1 FROM event_participants ep
        WHERE ep.event_id = event_participants.event_id
        AND ep.user_id = auth.uid()
        AND ep.status != 'cancelled'
      )
    );

  CREATE POLICY "Users can update their own registrations"
    ON event_participants
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
END $$;