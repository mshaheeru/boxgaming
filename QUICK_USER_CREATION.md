# Quick User Creation Guide

## The Problem
The seed scripts aren't creating users in Supabase Auth. Here's the **easiest way** to create test users:

## ✅ EASIEST METHOD: Use Your Flutter App

1. **Make sure your backend is running:**
   ```bash
   cd backend
   npm run start:dev
   ```

2. **Open your Flutter app** and go to the **Sign Up** tab

3. **Sign up with these credentials one by one:**

   **Customer 1:**
   - Email: `customer1@test.com`
   - Password: `password123`
   - Name: `John Customer`

   **Customer 2:**
   - Email: `customer2@test.com`
   - Password: `password123`
   - Name: `Sarah Customer`

   **Owner 1:**
   - Email: `owner1@test.com`
   - Password: `password123`
   - Name: `Mike Owner`

   **Owner 2:**
   - Email: `owner2@test.com`
   - Password: `password123`
   - Name: `Lisa Owner`

   **Admin:**
   - Email: `admin@test.com`
   - Password: `password123`
   - Name: `Admin User`

4. **After each signup, update the role in Supabase:**
   - Go to **Supabase Dashboard** → **Table Editor** → **users** table
   - Find the user by email (in the `phone` column, since we use email as phone)
   - Update the `role` column:
     - For customers: `customer`
     - For owners: `owner`
     - For admin: `admin`

## 🔧 Alternative: Fix the Seed Script

If you want to use the script, make sure:

1. **Create `.env` file in `backend/` directory** (if it doesn't exist):
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
   ```

2. **Get your Supabase credentials:**
   - Go to Supabase Dashboard → Settings → API
   - Copy the **Project URL** → `SUPABASE_URL`
   - Copy the **service_role** key (NOT anon key) → `SUPABASE_SERVICE_ROLE_KEY`

3. **Run the script:**
   ```bash
   cd backend
   npm run seed:users
   ```

4. **Check Supabase Dashboard** → Authentication → Users to verify users were created

## 📋 Test User Credentials (After Creation)

**Customers:**
- `customer1@test.com` / `password123`
- `customer2@test.com` / `password123`

**Owners:**
- `owner1@test.com` / `password123`
- `owner2@test.com` / `password123`

**Admin:**
- `admin@test.com` / `password123`

## ⚠️ Important Notes

- All users are created with **email confirmation enabled** (auto-confirmed)
- After signup via app, you **must update the role** in Supabase `users` table
- The `phone` field in `users` table stores the email address
- Users are created in both Supabase Auth and your `users` table

## 🐛 Troubleshooting

If users aren't appearing in Supabase Auth:

1. Check that your backend `.env` has correct Supabase credentials
2. Verify the backend server can connect to Supabase
3. Check Supabase Dashboard → Authentication → Users manually
4. Try creating one user via the Flutter app first to test the flow

