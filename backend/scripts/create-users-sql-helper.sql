-- SQL Helper Script for User Creation
-- Note: You CANNOT directly insert into auth.users via SQL
-- Supabase Auth manages this table. You must use:
-- 1. The Supabase Admin API (via backend)
-- 2. The signup endpoint (via app/API)
-- 3. Supabase Dashboard UI

-- However, you CAN update the users table after auth users are created:

-- After creating users via app/API, update their roles:
UPDATE users 
SET role = 'customer' 
WHERE phone = 'customer1@test.com' OR phone = 'customer2@test.com';

UPDATE users 
SET role = 'owner' 
WHERE phone = 'owner1@test.com' OR phone = 'owner2@test.com';

UPDATE users 
SET role = 'admin' 
WHERE phone = 'admin@test.com';

-- Verify users and their roles:
SELECT 
  u.phone as email,
  u.name,
  u.role,
  au.email_confirmed_at,
  au.created_at as auth_created_at
FROM users u
LEFT JOIN auth.users au ON au.id = u.id
WHERE u.phone LIKE '%@test.com' OR u.phone = 'admin@test.com'
ORDER BY u.role, u.name;

