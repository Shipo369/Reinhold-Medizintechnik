/*
  # Create profile for existing user

  1. Changes
    - Insert profile for existing user with admin role
*/

INSERT INTO profiles (id, email, role)
SELECT 
  '8ac9a2e7-b335-4e08-95ab-1721fae83b97',
  'juan_jano@hotmail.de',
  'admin'
WHERE NOT EXISTS (
  SELECT 1 FROM profiles 
  WHERE id = '8ac9a2e7-b335-4e08-95ab-1721fae83b97'
);