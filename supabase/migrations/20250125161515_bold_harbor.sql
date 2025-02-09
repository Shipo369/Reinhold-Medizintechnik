/*
  # Email Templates System

  1. New Tables
    - `email_templates` for storing email templates
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `subject` (text)
      - `content` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on email_templates table
    - Add policies for admin access
*/

-- Create email templates table
CREATE TABLE IF NOT EXISTS email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;

-- Create policy for admin access
CREATE POLICY "Allow admin access to email templates"
  ON email_templates
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create simple function to get formatted email
CREATE OR REPLACE FUNCTION get_verification_email(p_code TEXT)
RETURNS TABLE (
  subject TEXT,
  content TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    subject,
    replace(content, '{{code}}', p_code)
  FROM email_templates 
  WHERE name = 'verification_code'
  LIMIT 1;
$$;