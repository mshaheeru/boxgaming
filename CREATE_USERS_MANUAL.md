# How to Create Test Users Manually

Since the seed script may not be working, here's how to create users manually:

## Option 1: Use Your Flutter App (Easiest)

1. **Start your backend server:**
   ```bash
   cd backend
   npm run start:dev
   ```

2. **Open your Flutter app** and go to the Sign Up tab

3. **Sign up with these credentials:**
   - Email: `customer1@test.com`
   - Password: `password123`
   - Name: `John Customer`

4. **After signup, update the role in Supabase:**
   - Go to Supabase Dashboard → Table Editor → `users` table
   - Find the user by email
   - Update the `role` column to `customer`, `owner`, or `admin`

## Option 2: Use Supabase Dashboard

1. **Go to Supabase Dashboard** → Authentication → Users

2. **Click "Add User"** → "Create new user"

3. **Fill in:**
   - Email: `customer1@test.com`
   - Password: `password123`
   - Auto Confirm User: ✅ (check this)

4. **Click "Create User"**

5. **Go to Table Editor** → `users` table

6. **Add/Update the user record:**
   - `id`: Copy from auth.users
   - `phone`: `customer1@test.com`
   - `name`: `John Customer`
   - `role`: `customer` (or `owner`/`admin`)

## Option 3: Use Backend API (If Server is Running)

```bash
# Make sure backend is running on port 3001
curl -X POST http://localhost:3001/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"customer1@test.com","password":"password123","name":"John Customer"}'
```

Then update the role in Supabase Dashboard → Table Editor → `users` table.

## Test User Credentials

After creating users, use these to login:

**Customers:**
- `customer1@test.com` / `password123`
- `customer2@test.com` / `password123`

**Owners:**
- `owner1@test.com` / `password123`
- `owner2@test.com` / `password123`

**Admin:**
- `admin@test.com` / `password123`

## Quick Script Fix

If you want to fix the seed script, make sure:

1. **Create `.env` file in `backend/` directory:**
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

2. **Install dotenv (if not installed):**
   ```bash
   cd backend
   npm install dotenv
   ```

3. **Run the script:**
   ```bash
   node scripts/create-users-simple.js
   ```

The script should create users in both Supabase Auth and your `users` table.

