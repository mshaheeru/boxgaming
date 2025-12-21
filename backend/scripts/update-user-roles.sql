-- SQL Script to Update User Roles
-- Run this in Supabase SQL Editor after creating users via app/API

-- Update customer roles
UPDATE users 
SET role = 'customer' 
WHERE phone IN ('customer1@test.com', 'customer2@test.com');

-- Update owner roles  
UPDATE users 
SET role = 'owner' 
WHERE phone IN ('owner1@test.com', 'owner2@test.com');

-- Update admin role
UPDATE users 
SET role = 'admin' 
WHERE phone = 'admin@test.com';

-- Verify the updates
SELECT 
  phone as email,
  name,
  role,
  created_at
FROM users 
WHERE phone LIKE '%@test.com' OR phone = 'admin@test.com'
ORDER BY role, name;

