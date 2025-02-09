/*
  # Calendar System Updates

  This migration ensures the calendar system tables exist and have the correct structure.
  It will safely check for existing tables before creating them.

  1. Tables
    - events
    - event_participants

  2. Security
    - RLS policies for both tables
    - Registration management trigger
*/

-- Function to check participant limits and manage waitlist (recreate to ensure latest version)
CREATE OR REPLACE FUNCTION manage_event_registration()
RETURNS TRIGGER AS $$
DECLARE
  current_registered INTEGER;
  event_max_participants INTEGER;
BEGIN
  -- Get the maximum participants for this event
  SELECT max_participants INTO event_max_participants
  FROM events
  WHERE id = NEW.event_id;

  -- Count current registered participants
  SELECT COUNT(*) INTO current_registered
  FROM event_participants
  WHERE event_id = NEW.event_id
  AND status = 'registered';

  -- If trying to register and event is full, put on waitlist
  IF NEW.status = 'registered' AND current_registered >= event_max_participants THEN
    NEW.status := 'waitlist';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS manage_event_registration_trigger ON event_participants;

-- Recreate trigger for registration management
CREATE TRIGGER manage_event_registration_trigger
  BEFORE INSERT OR UPDATE ON event_participants
  FOR EACH ROW
  EXECUTE FUNCTION manage_event_registration();

-- Recreate policies to ensure they are up to date
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Everyone can view events" ON events;
  DROP POLICY IF EXISTS "Admins can manage events" ON events;
  DROP POLICY IF EXISTS "Users can view their own registrations" ON event_participants;
  DROP POLICY IF EXISTS "Admins can view all registrations" ON event_participants;
  DROP POLICY IF EXISTS "Users can register for events" ON event_participants;
  DROP POLICY IF EXISTS "Users can update their own registrations" ON event_participants;

  -- Recreate policies for events
  CREATE POLICY "Everyone can view events"
    ON events
    FOR SELECT
    TO authenticated
    USING (true);

  CREATE POLICY "Admins can manage events"
    ON events
    FOR ALL
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
      )
    );

  -- Recreate policies for event_participants
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