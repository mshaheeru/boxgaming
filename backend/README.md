# Indoor Games Booking System - Backend API

NestJS backend API for the Indoor Games Booking System.

## Tech Stack

- **Framework**: NestJS (Node.js)
- **Database**: Supabase (PostgreSQL with PostgREST API)
- **Cache**: Redis (ioredis)
- **Authentication**: Supabase Auth with JWT and phone OTP
- **Storage**: Supabase Storage
- **Payment Gateway**: PayFast (placeholder implementation)
- **Documentation**: Swagger/OpenAPI

## Setup

### Prerequisites

- Node.js 18+ 
- Supabase project (create at https://supabase.com)
- Redis 6+ (optional, for caching)

### Installation

1. Install dependencies:
```bash
npm install
```

2. Setup environment variables:
```bash
# Create .env file with the following variables:
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
JWT_SECRET=your_jwt_secret
REDIS_HOST=localhost (optional)
REDIS_PORT=6379 (optional)
```

3. Setup Supabase:
   - Create a new project at https://supabase.com
   - Set up your database tables using the Supabase SQL editor or dashboard
   - Configure authentication providers as needed
   - Set up storage buckets if needed

4. Start Redis server (if running locally, optional)

5. Start the development server:
```bash
npm run start:dev
```

The API will be available at `http://localhost:3000/api/v1`

Swagger documentation: `http://localhost:3000/api/docs`

## Environment Variables

Required environment variables:

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key (for client operations)
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (for admin operations)
- `REDIS_HOST` - Redis host (default: localhost, optional)
- `REDIS_PORT` - Redis port (default: 6379, optional)
- `JWT_SECRET` - Secret key for JWT tokens
- `JWT_EXPIRES_IN` - JWT token expiration (default: 24h)
- `PAYFAST_MERCHANT_ID` - PayFast merchant ID
- `PAYFAST_MERCHANT_KEY` - PayFast merchant key
- `PAYFAST_PASSPHRASE` - PayFast passphrase
- `PAYFAST_SANDBOX` - Use PayFast sandbox (true/false)

## API Endpoints

### Authentication
- `POST /auth/send-otp` - Send OTP to phone number
- `POST /auth/verify-otp` - Verify OTP and get JWT token

### Venues
- `GET /venues` - List venues (with filters)
- `GET /venues/:id` - Get venue details
- `POST /venues` - Create venue (owner only)
- `PUT /venues/:id` - Update venue (owner only)

### Grounds
- `GET /venues/:venueId/grounds` - List grounds for a venue
- `GET /venues/:venueId/grounds/:id` - Get ground details
- `POST /venues/:venueId/grounds` - Create ground (owner only)
- `PUT /venues/:venueId/grounds/:id` - Update ground (owner only)

### Bookings
- `GET /bookings/grounds/:groundId/slots` - Get available slots
- `POST /bookings` - Create booking
- `GET /bookings/my-bookings` - Get user's bookings
- `GET /bookings/:id` - Get booking details
- `POST /bookings/:id/cancel` - Cancel booking
- `POST /bookings/:id/start` - Mark booking as started (owner)
- `POST /bookings/:id/complete` - Mark booking as completed (owner)

### Payments
- `POST /payments/initiate/:bookingId` - Initiate payment
- `POST /payments/webhooks/payment` - Payment webhook

### Reviews
- `POST /reviews` - Create review
- `GET /reviews/venues/:venueId` - Get venue reviews

### Payouts
- `GET /payouts/my-payouts` - Get owner payouts
- `PUT /payouts/:id/mark-paid` - Mark payout as paid (admin)

## Database Schema

The database schema should be set up in your Supabase project. Key tables:

- `users` - Customers, owners, and admins
- `venues` - Sports venues
- `grounds` - Individual courts/fields within venues
- `bookings` - Booking records
- `payments` - Payment transactions
- `payouts` - Owner payouts
- `reviews` - Customer reviews

You can create these tables using the Supabase SQL editor or dashboard. The schema structure should match the Prisma schema that was previously used (see git history if needed).

## Development

### Running Tests
```bash
npm test
```

### Database Migrations
Database migrations are handled through Supabase:
- Use the Supabase SQL editor to run migrations
- Or use Supabase CLI: `supabase db push`
- Or manage through the Supabase dashboard

### Code Formatting
```bash
npm run format
```

## Production Deployment

1. Set `NODE_ENV=production`
2. Configure Supabase production project
3. Set up Redis (if using)
4. Configure proper CORS origins
5. Setup SSL certificates
6. Start with: `npm run start:prod`

## Notes

- OTP is currently logged to console (for development). Replace with SMS provider integration.
- PayFast integration is a placeholder. Implement according to PayFast documentation.
- Firebase Cloud Messaging is not fully implemented. Add FCM token storage and sending logic.
- Payout calculation should be run as a cron job (weekly on Mondays).

