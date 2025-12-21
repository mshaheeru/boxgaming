# Creating Users with SQL (Limitation Explained)

## ⚠️ Important: You Cannot Directly Insert into `auth.users`

Supabase Auth manages the `auth.users` table, so you **cannot** directly insert into it via SQL. You must use:

1. **Supabase Admin API** (recommended)
2. **Backend API signup endpoint** (easiest)
3. **Supabase Dashboard UI**

## ✅ Solution: Use Backend API + SQL for Roles

### Step 1: Create Users via Backend API

**Option A: Use the HTTP script (if backend is running):**
```bash
cd backend
node scripts/create-users-http.js
```

**Option B: Use your Flutter app:**
- Sign up with each email/password
- This creates users in Supabase Auth automatically

### Step 2: Update Roles via SQL

After users are created, run this SQL in Supabase SQL Editor:

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
WHERE phone LIKE '%@test.com' OR phone = 'admin@test.com';
```

## 🔧 Alternative: Create Users via Supabase Dashboard

1. Go to **Supabase Dashboard** → **Authentication** → **Users**
2. Click **"Add User"** → **"Create new user"**
3. Enter:
   - Email: `customer1@test.com`
   - Password: `password123`
   - ✅ Check "Auto Confirm User"
4. Click **"Create User"**
5. Go to **Table Editor** → **users** table
6. Add record with:
   - `id`: Copy from auth.users
   - `phone`: `customer1@test.com`
   - `name`: `John Customer`
   - `role`: `customer`

## 📋 Test User Credentials

After creation, use these to login:

- `customer1@test.com` / `password123`
- `customer2@test.com` / `password123`
- `owner1@test.com` / `password123`
- `owner2@test.com` / `password123`
- `admin@test.com` / `password123`

## 🚀 Quick SQL to Check Users

```sql
-- Check auth users
SELECT email, created_at, email_confirmed_at 
FROM auth.users 
WHERE email LIKE '%@test.com' OR email = 'admin@test.com';

-- Check users table with roles
SELECT phone, name, role 
FROM users 
WHERE phone LIKE '%@test.com' OR phone = 'admin@test.com';
```

