# Test User Credentials

## How to Login

Use these credentials in your Flutter app's login page:

### Customer Users
- **Email:** `customer1@test.com`  
  **Password:** `password123`  
  **Name:** John Customer

- **Email:** `customer2@test.com`  
  **Password:** `password123`  
  **Name:** Sarah Customer

### Owner Users
- **Email:** `owner1@test.com`  
  **Password:** `password123`  
  **Name:** Mike Owner

- **Email:** `owner2@test.com`  
  **Password:** `password123`  
  **Name:** Lisa Owner

### Admin User
- **Email:** `admin@test.com`  
  **Password:** `password123`  
  **Name:** Admin User

## Seeding Users

To create these test users, run:

```bash
cd backend
npm run seed:users
```

Or manually:

```bash
node scripts/seed-users-direct.js
```

Make sure your `.env` file has:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

## Testing Different Roles

- **Customer:** Can browse venues, make bookings, view their bookings
- **Owner:** Can see owner dashboard, manage bookings, scan QR codes
- **Admin:** Full access (if admin features are implemented)

## Notes

- All users have email confirmation enabled (auto-confirmed)
- Passwords are: `password123` for all test users
- Users are created in both Supabase Auth and the `users` table

