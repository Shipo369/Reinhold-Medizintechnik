/*
  # Add user management functionality

  1. Changes
    - Add status field to profiles table
    - Add approval workflow fields
    - Update RLS policies

  2. Security
    - Only admins can approve users
    - Users can only access the system when approved
*/

-- Add status and approval fields to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);

-- Update RLS policies for profiles
CREATE POLICY "Pending users can view their own basic profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() AND
    (status = 'pending' OR status = 'approved')
  );

CREATE POLICY "Approved users can view their full profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() AND
    status = 'approved'
  );

-- Function to check if user is approved
CREATE OR REPLACE FUNCTION is_user_approved()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND status = 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;