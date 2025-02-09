/*
  # Initial Schema Setup for Medical Training Portal

  1. Authentication and User Management
    - Custom user profiles table
    - Role-based access control
    
  2. Security
    - Row Level Security policies
    - Audit logging table
    
  3. Tables
    - profiles: Extended user profile information
    - audit_logs: System-wide audit logging
*/

-- Create custom profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create audit logs table
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  table_name TEXT,
  record_id TEXT,
  old_data JSONB,
  new_data JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Policies for profiles table
CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON profiles
  FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policies for audit_logs table
CREATE POLICY "Admins can view audit logs"
  ON audit_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Function to handle audit logging
CREATE OR REPLACE FUNCTION handle_audit_log()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (
    user_id,
    action,
    table_name,
    record_id,
    old_data,
    new_data,
    ip_address
  )
  VALUES (
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    CASE
      WHEN TG_OP = 'DELETE' THEN OLD.id::TEXT
      ELSE NEW.id::TEXT
    END,
    CASE
      WHEN TG_OP = 'UPDATE' OR TG_OP = 'DELETE'
      THEN to_jsonb(OLD)
      ELSE NULL
    END,
    CASE
      WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE'
      THEN to_jsonb(NEW)
      ELSE NULL
    END,
    current_setting('request.headers', true)::json->>'x-forwarded-for'
  );
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;