/*
  # Secure Registration System

  1. New Tables
    - `verification_codes`
      - `id` (uuid, primary key)
      - `email` (text)
      - `code` (text)
      - `expires_at` (timestamptz)
      - `verified_at` (timestamptz)
      - `created_at` (timestamptz)

  2. Changes
    - Add verification fields to profiles table
    - Add email verification status
    - Add admin notification system

  3. Security
    - Enable RLS
    - Add policies for verification codes
*/

-- Create verification_codes table
CREATE TABLE verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add verification status to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verification_attempts INTEGER DEFAULT 0;

-- Create admin_notifications table
CREATE TABLE admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

-- Policies for verification_codes
CREATE POLICY "Users can insert their own verification code"
  ON verification_codes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    NOT EXISTS (
      SELECT 1 FROM verification_codes
      WHERE email = auth.email()
      AND verified_at IS NULL
      AND expires_at > now()
    )
  );

CREATE POLICY "Users can view their own verification codes"
  ON verification_codes
  FOR SELECT
  TO authenticated
  USING (email = auth.email());

CREATE POLICY "Users can update their own verification codes"
  ON verification_codes
  FOR UPDATE
  TO authenticated
  USING (email = auth.email());

-- Policies for admin_notifications
CREATE POLICY "Admins can view notifications"
  ON admin_notifications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can update notifications"
  ON admin_notifications
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Function to generate verification code
CREATE OR REPLACE FUNCTION generate_verification_code(p_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_code TEXT;
BEGIN
  -- Generate a 6-digit code
  v_code := floor(random() * 900000 + 100000)::TEXT;
  
  -- Insert the code
  INSERT INTO verification_codes (email, code, expires_at)
  VALUES (p_email, v_code, now() + interval '24 hours');
  
  RETURN v_code;
END;
$$;

-- Function to verify code
CREATE OR REPLACE FUNCTION verify_code(p_email TEXT, p_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_valid BOOLEAN;
BEGIN
  UPDATE verification_codes
  SET verified_at = CASE 
    WHEN code = p_code AND expires_at > now() THEN now()
    ELSE verified_at
  END
  WHERE email = p_email
  AND verified_at IS NULL
  AND expires_at > now()
  RETURNING (code = p_code) INTO v_valid;
  
  IF v_valid THEN
    UPDATE profiles
    SET email_verified = true,
        email_verified_at = now()
    WHERE email = p_email;
  END IF;
  
  RETURN COALESCE(v_valid, false);
END;
$$;

-- Function to notify admins
CREATE OR REPLACE FUNCTION notify_admins_of_registration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.email_verified AND NEW.status = 'pending' THEN
    INSERT INTO admin_notifications (
      type,
      user_id,
      message
    )
    VALUES (
      'new_registration',
      NEW.id,
      'Neue verifizierte Registrierung von ' || NEW.email || ' wartet auf Freigabe.'
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for admin notifications
CREATE TRIGGER notify_admins_after_verification
  AFTER UPDATE ON profiles
  FOR EACH ROW
  WHEN (OLD.email_verified IS DISTINCT FROM NEW.email_verified)
  EXECUTE FUNCTION notify_admins_of_registration();

-- Create indexes
CREATE INDEX idx_verification_codes_email ON verification_codes(email);
CREATE INDEX idx_verification_codes_expires_at ON verification_codes(expires_at);
CREATE INDEX idx_admin_notifications_read ON admin_notifications(read);