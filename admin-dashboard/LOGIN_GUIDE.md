# Admin Login Guide

## Login Process

The admin portal uses **phone-based OTP authentication**. Here's how to login:

### Step 1: Enter Phone Number
1. Go to http://localhost:3001/login
2. Enter your phone number in E.164 format (e.g., `+923001234567`)
3. Click "Send OTP"

### Step 2: Verify OTP
1. Check your phone for the OTP code (6 digits)
2. **In development mode**: The OTP is also logged to the backend console
3. Enter the OTP code
4. Click "Verify OTP"

### Step 3: Access Dashboard
- If your account has `role: 'admin'`, you'll be redirected to the dashboard
- If not, you'll see an "Access denied" error

## Setting Up Admin User

Before you can login, you need to create an admin user in the database. Here are the options:

### Option 1: Using Prisma Studio (Recommended)

1. **Open Prisma Studio**:
```bash
docker-compose -f docker-compose.dev.yml exec backend npx prisma studio
```

2. **Access Prisma Studio**: Open http://localhost:5555 in your browser

3. **Create Admin User**:
   - Click on "User" model
   - Click "Add record"
   - Fill in:
     - `phone`: Your phone number (e.g., `+923001234567`)
     - `name`: Your name (optional)
     - `role`: Select `admin`
   - Click "Save 1 change"

### Option 2: Using Database Directly

1. **Connect to PostgreSQL**:
```bash
docker-compose -f docker-compose.dev.yml exec postgres psql -U indooruser -d indoor_games
```

2. **Insert Admin User**:
```sql
INSERT INTO users (id, phone, name, role, created_at)
VALUES (
  gen_random_uuid(),
  '+923001234567',  -- Replace with your phone number
  'Admin User',     -- Replace with your name
  'admin',
  NOW()
);
```

### Option 3: Using Backend API (If you have a customer account)

1. **First, create a regular user** via the API:
```bash
# Send OTP
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+923001234567"}'

# Verify OTP (check backend logs for OTP)
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+923001234567", "otp": "123456"}'
```

2. **Then update the user role to admin** using Prisma Studio or SQL

## Getting OTP in Development

In development mode, the OTP is **logged to the backend console** for testing:

1. **View backend logs**:
```bash
docker-compose -f docker-compose.dev.yml logs -f backend
```

2. **Look for the OTP**:
```
OTP for +923001234567: 123456
```

## Troubleshooting

### "Access denied. Admin access required."
- Your user account doesn't have `role: 'admin'`
- Solution: Update the user role to `admin` using one of the methods above

### "Invalid or expired OTP"
- OTP expires after 5 minutes
- Solution: Request a new OTP

### "Failed to send OTP"
- Check backend logs for errors
- In development, OTP is logged to console (SMS provider not configured)

### Can't see OTP in logs
- Make sure backend container is running
- Check logs: `docker-compose -f docker-compose.dev.yml logs backend`

## Production Setup

For production, you'll need to:
1. Configure an SMS provider (Twilio/Unifonic) in `.env`
2. Update `backend/src/auth/auth.service.ts` to send actual SMS instead of logging




