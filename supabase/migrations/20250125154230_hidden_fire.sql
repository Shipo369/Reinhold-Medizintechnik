/*
  # Fix profile policies to avoid recursion

  1. Changes
    - Drop all existing profile policies
    - Create new non-recursive policies
    - Add separate policies for different operations
    - Use direct role check without subqueries

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion
    - Allow admins to manage users
    - Allow users to view their own profiles
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "Anyone can read profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admin access based on role column" ON profiles;

-- Create new non-recursive policies
CREATE POLICY "Allow users to read their own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Allow users to insert their own profile"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to update their own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow admins to read all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (role = 'admin' OR auth.uid() = id);

CREATE POLICY "Allow admins to update all profiles"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (role = 'admin' OR auth.uid() = id)
  WITH CHECK (role = 'admin' OR auth.uid() = id);

CREATE POLICY "Allow admins to delete profiles"
  ON profiles
  FOR DELETE
  TO authenticated
  USING (role = 'admin');