/*
  # Fix event_participants policies

  1. Changes
    - Fix infinite recursion in RLS policies
    - Simplify policy conditions
    - Add proper indexes for performance
    - Ensure proper cascade behavior

  2. Security
    - Maintain proper access control
    - Fix policy recursion issues
    - Ensure data integrity
*/

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can view their own registrations" ON event_participants;
DROP POLICY IF EXISTS "Admins can view all registrations" ON event_participants;
DROP POLICY IF EXISTS "Users can register for events" ON event_participants;
DROP POLICY IF EXISTS "Users can update their own registrations" ON event_participants;

-- Recreate policies with proper conditions
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
    user_id = auth.uid()
  );

CREATE POLICY "Users can update their own registrations"
  ON event_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Add policy for deletion
CREATE POLICY "Users can delete their own registrations"
  ON event_participants
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Ensure proper indexes exist
CREATE INDEX IF NOT EXISTS idx_event_participants_composite 
  ON event_participants(event_id, user_id);

CREATE INDEX IF NOT EXISTS idx_event_participants_status 
  ON event_participants(status);