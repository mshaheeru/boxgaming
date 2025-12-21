# Indoor Games Booking System

A comprehensive booking platform for indoor sports venues in Pakistan, enabling customers to book courts/grounds and venue owners to manage their facilities.

## Project Structure

```
indoorgaming/
├── backend/              # NestJS API
├── mobile-customer/      # React Native Customer App
├── mobile-owner/         # React Native Owner App
├── admin-dashboard/      # Next.js Admin Portal
└── shared/              # Shared types/utilities
```

## Features

### Customer App
- Phone OTP authentication
- Browse venues by location and sport type
- View available time slots
- Book and pay for slots
- QR code for venue check-in
- Booking management and cancellation
- Reviews and ratings

### Owner App
- Simple dashboard for today's bookings
- QR code scanner for check-in
- Mark bookings as started/completed
- Block time slots
- View revenue and payouts
- Venue and ground management

### Admin Dashboard
- Approve/reject venue applications
- Manage venues and users
- View all bookings
- Revenue tracking
- Payout management

## Tech Stack

### Backend
- NestJS (Node.js/TypeScript)
- PostgreSQL with Prisma ORM
- Redis for caching and locking
- JWT authentication
- PayFast payment gateway

### Mobile Apps
- React Native
- React Navigation
- React Query
- Firebase Cloud Messaging

### Admin Dashboard
- Next.js 14
- TypeScript
- Tailwind CSS
- shadcn/ui

## Getting Started

### Quick Start with Docker (Recommended)

The easiest way to get started is using Docker:

**Windows:**
```bash
start-dev.bat
```

**Linux/Mac:**
```bash
chmod +x start-dev.sh
./start-dev.sh
```

**Manual Docker Setup:**
```bash
# Start all services
docker-compose -f docker-compose.dev.yml up -d

# Run migrations
docker-compose -f docker-compose.dev.yml exec backend npx prisma migrate dev

# View logs
docker-compose -f docker-compose.dev.yml logs -f backend
```

**Access the API:**
- API: http://localhost:3000/api/v1
- Swagger Docs: http://localhost:3000/api/docs
- Health Check: http://localhost:3000/api/v1/health

### Local Development Setup

See [SETUP.md](./SETUP.md) for detailed setup instructions.

1. Install dependencies: `cd backend && npm install`
2. Setup environment variables (copy `.env.example` to `.env`)
3. Start PostgreSQL and Redis
4. Run database migrations: `npm run prisma:migrate`
5. Start server: `npm run start:dev`

### Mobile Apps

Coming soon - React Native apps will be added in Phase 2.

### Admin Dashboard

Coming soon - Next.js admin dashboard will be added in Phase 2.

## Development Status

### Completed ✅
- Backend API foundation
- Database schema and migrations
- Authentication (OTP)
- Venue and ground management
- Slot generation algorithm
- Booking system with Redis locking
- Payment integration (PayFast placeholder)
- QR code generation
- Cancellation and refunds
- Reviews and ratings
- Payout system

### In Progress 🚧
- Admin dashboard
- Customer mobile app
- Owner mobile app

### Planned 📋
- Push notifications (FCM)
- Automated payouts
- Testing suite
- Production deployment

## API Documentation

When the backend is running, visit:
- Swagger UI: `http://localhost:3000/api/docs`
- API Base: `http://localhost:3000/api/v1`

## License

Private - All rights reserved

