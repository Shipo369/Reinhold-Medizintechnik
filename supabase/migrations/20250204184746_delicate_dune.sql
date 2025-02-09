-- Add new profile fields
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS mobile TEXT,
  ADD COLUMN IF NOT EXISTS street TEXT,
  ADD COLUMN IF NOT EXISTS house_number TEXT,
  ADD COLUMN IF NOT EXISTS postal_code TEXT,
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS birth_date DATE;

-- Create indexes for better search performance
CREATE INDEX IF NOT EXISTS idx_profiles_name 
  ON profiles(first_name, last_name);
CREATE INDEX IF NOT EXISTS idx_profiles_city 
  ON profiles(city);
CREATE INDEX IF NOT EXISTS idx_profiles_postal_code 
  ON profiles(postal_code);