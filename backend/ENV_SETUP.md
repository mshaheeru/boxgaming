# Environment Variables Setup Guide

## Required Variables

### 1. Supabase Configuration (REQUIRED)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```
**Where to find:**
- Go to your Supabase project dashboard
- Settings → API
- Copy the Project URL, anon/public key, and service_role key

### 2. JWT Authentication (REQUIRED)
```env
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
JWT_EXPIRES_IN=24h
```
**Important:** 
- Use a strong, random string for `JWT_SECRET` (minimum 32 characters)
- Never commit this to version control
- Use different secrets for development and production

### 3. Server Configuration (REQUIRED)
```env
PORT=3001
HOST=0.0.0.0
API_PREFIX=api/v1
NODE_ENV=development
NETWORK_URL=http://192.168.0.65:3001
```

**Note:** 
- `HOST=0.0.0.0` makes the server accessible from other devices on your network
- `NETWORK_URL` is optional - used for logging the network-accessible URL

### 4. CORS Configuration (REQUIRED)
```env
CORS_ORIGIN=http://localhost:3000,http://localhost:3001,http://localhost:3002
```
**Important:**
- Add all URLs that will access your API
- Separate multiple URLs with commas (no spaces)
- Include your frontend URLs, mobile app URLs, admin dashboard URLs
- For production, use your actual domain URLs

### 5. Application URLs (REQUIRED)
```env
APP_URL=http://localhost:3000
API_URL=http://localhost:3000
```
**Note:** 
- `APP_URL` is used for payment redirects
- `API_URL` is used for webhook callbacks
- Update these to your production URLs when deploying

## Optional Variables

### Redis Configuration (OPTIONAL)
Only needed if you want to use Redis for caching and OTP storage.
```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```
**Note:** If you don't set these, the app will try to connect to Redis on localhost:6379. If Redis is not available, some features (like OTP caching) may not work optimally.

### OTP Configuration (OPTIONAL)
```env
OTP_EXPIRES_IN=300  # 5 minutes in seconds
OTP_LENGTH=6        # Length of OTP code
```

### PayFast Payment Gateway (OPTIONAL)
Only needed if you're using PayFast for payments.
```env
PAYFAST_MERCHANT_ID=
PAYFAST_MERCHANT_KEY=
PAYFAST_PASSPHRASE=
PAYFAST_SANDBOX=true
PAYFAST_WEBHOOK_SECRET=
```

## Minimum Required Setup

For a basic setup, you need at minimum:

```env
# Supabase (REQUIRED)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# JWT (REQUIRED)
JWT_SECRET=your-secret-key-min-32-chars

# CORS (REQUIRED - adjust to your needs)
CORS_ORIGIN=http://localhost:3000,http://localhost:3001

# URLs (REQUIRED)
APP_URL=http://localhost:3000
API_URL=http://localhost:3000
```

## Production Checklist

When deploying to production:

- [ ] Change `NODE_ENV=production`
- [ ] Use a strong, unique `JWT_SECRET` (generate with: `openssl rand -base64 32`)
- [ ] Update `CORS_ORIGIN` with your production frontend URLs
- [ ] Update `APP_URL` and `API_URL` with your production domain
- [ ] Set up Redis if you want caching/OTP storage
- [ ] Configure PayFast production credentials if using payments
- [ ] Never commit `.env` file to version control
- [ ] Use environment variable management in your hosting platform

## Quick Start

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Fill in the required variables (especially Supabase and JWT_SECRET)

3. Start the server:
   ```bash
   npm run start:dev
   ```

## Troubleshooting

**Error: "Missing Supabase configuration"**
- Make sure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set

**CORS errors in browser**
- Add your frontend URL to `CORS_ORIGIN`
- Make sure URLs are comma-separated without spaces

**JWT authentication not working**
- Check that `JWT_SECRET` is set and is at least 32 characters
- Make sure the same secret is used for signing and verifying tokens

**Redis connection errors**
- If you're not using Redis, you can ignore these errors
- To use Redis, make sure Redis server is running and credentials are correct

