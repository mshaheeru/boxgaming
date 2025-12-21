# User Seeding Guide

## Quick Start - Test User Credentials

### Customer Users
- **Email:** `customer1@test.com`  
  **Password:** `password123`

- **Email:** `customer2@test.com`  
  **Password:** `password123`

### Owner Users  
- **Email:** `owner1@test.com`  
  **Password:** `password123`

- **Email:** `owner2@test.com`  
  **Password:** `password123`

### Admin User
- **Email:** `admin@test.com`  
  **Password:** `password123`

---

## How to Seed Users

### Option 1: Using the Seed Script (Recommended)

1. Make sure your backend `.env` file has:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

2. Run the seed script:
   ```bash
   cd backend
   npm run seed:users
   ```

3. The script will:
   - Create users in Supabase Auth
   - Create corresponding entries in the `users` table
   - Auto-confirm emails (no email verification needed)
   - Set appropriate roles (customer, owner, admin)

### Option 2: Manual Signup via App

1. Open your Flutter app
2. Go to the Sign Up tab
3. Use the credentials above to sign up
4. After signup, manually update the role in Supabase:
   - Go to Supabase Dashboard → Authentication → Users
   - Find the user
   - Update the role in the `users` table

### Option 3: Using Supabase Dashboard

1. Go to Supabase Dashboard → Authentication → Users
2. Click "Add User" → "Create new user"
3. Enter email and password
4. Set email as confirmed
5. Go to Table Editor → `users` table
6. Add/update the user record with the correct role

---

## Testing Different Roles

### Customer Role
- Can browse venues
- Can make bookings
- Can view their own bookings
- Can cancel bookings (with refund policy)

### Owner Role
- Sees Owner Dashboard on login
- Can view today's bookings
- Can mark bookings as started/completed
- Can scan QR codes
- Can view revenue stats

### Admin Role
- Full system access (if admin features are implemented)
- Can manage all users
- Can manage all venues

---

## Notes

- All test users have the same password: `password123`
- Emails are auto-confirmed (no verification needed)
- Users are created with both Supabase Auth and in the `users` table
- The owner user (`owner@box.com`) already exists from venue seeding

---

## Troubleshooting

If the seed script doesn't work:

1. Check that your `.env` file has the correct Supabase credentials
2. Make sure the backend server is not required (script uses Supabase directly)
3. Try running directly: `node backend/scripts/seed-users-direct.js`
4. Check Supabase Dashboard to see if users were created in Auth
5. Verify users table has corresponding entries

---

## Current Users in Database

You can check existing users by running:
```sql
SELECT phone, name, role FROM users ORDER BY role, name;
```

