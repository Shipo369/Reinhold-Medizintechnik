/*
  # Calendar System Tables

  1. New Tables
    - `events`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `start_time` (timestamptz)
      - `end_time` (timestamptz)
      - `location` (text)
      - `max_participants` (integer)
      - `device_model_id` (uuid, optional reference to device_models)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `event_participants`
      - `id` (uuid, primary key)
      - `event_id` (uuid, reference to events)
      - `user_id` (uuid, reference to auth.users)
      - `status` (text: registered, waitlist, cancelled)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for viewing and managing events
    - Add policies for event participation
*/

-- Events table
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  location TEXT NOT NULL,
  max_participants INTEGER NOT NULL DEFAULT 10,
  device_model_id UUID REFERENCES device_models(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- Event participants table
CREATE TABLE event_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('registered', 'waitlist', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(event_id, user_id)
);

-- Enable RLS
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;

-- Policies for events
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

-- Policies for event_participants
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
      SELECT 1 FROM event_participants
      WHERE event_participants.event_id = event_participants.event_id
      AND event_participants.user_id = auth.uid()
      AND event_participants.status != 'cancelled'
    )
  );

CREATE POLICY "Users can update their own registrations"
  ON event_participants
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Update triggers
CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_participants_updated_at
  BEFORE UPDATE ON event_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to check participant limits and manage waitlist
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

-- Trigger for registration management
CREATE TRIGGER manage_event_registration_trigger
  BEFORE INSERT OR UPDATE ON event_participants
  FOR EACH ROW
  EXECUTE FUNCTION manage_event_registration();