# Create Test Users - Step by Step

## ⚠️ Important: You Cannot Create Auth Users via SQL

Supabase Auth manages the `auth.users` table, so you **must** create users through:
- Your Flutter app (Sign Up)
- Backend API signup endpoint
- Supabase Dashboard UI

## ✅ Recommended: Use Flutter App + SQL

### Step 1: Create Users via Flutter App

1. **Open your Flutter app**
2. **Go to Sign Up tab**
3. **Sign up with each user:**

   ```
   customer1@test.com / password123 / John Customer
   customer2@test.com / password123 / Sarah Customer
   owner1@test.com / password123 / Mike Owner
   owner2@test.com / password123 / Lisa Owner
   admin@test.com / password123 / Admin User
   ```

### Step 2: Update Roles via SQL

After all users are created, run this SQL in **Supabase SQL Editor**:

```sql
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

-- Verify
SELECT phone, name, role FROM users 
WHERE phone LIKE '%@test.com' OR phone = 'admin@test.com'
ORDER BY role, name;
```

## 🔍 Verify Users Were Created

Run this SQL to check:

```sql
-- Check auth users
SELECT email, created_at, email_confirmed_at 
FROM auth.users 
WHERE email LIKE '%@test.com' OR email = 'admin@test.com'
ORDER BY created_at;

-- Check users table with roles
SELECT phone, name, role 
FROM users 
WHERE phone LIKE '%@test.com' OR phone = 'admin@test.com'
ORDER BY role;
```

## 📋 Final Test Credentials

After completing the steps above:

- `customer1@test.com` / `password123` (Customer)
- `customer2@test.com` / `password123` (Customer)
- `owner1@test.com` / `password123` (Owner)
- `owner2@test.com` / `password123` (Owner)
- `admin@test.com` / `password123` (Admin)

## 🚀 Quick One-Liner SQL (After App Signup)

Copy and paste this entire block into Supabase SQL Editor:

```sql
UPDATE users SET role = 'customer' WHERE phone IN ('customer1@test.com', 'customer2@test.com');
UPDATE users SET role = 'owner' WHERE phone IN ('owner1@test.com', 'owner2@test.com');
UPDATE users SET role = 'admin' WHERE phone = 'admin@test.com';
SELECT phone, name, role FROM users WHERE phone LIKE '%@test.com' OR phone = 'admin@test.com' ORDER BY role;
```

