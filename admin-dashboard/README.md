# Indoor Games Admin Dashboard

Next.js admin dashboard for managing the Indoor Games Booking System.

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **UI Library**: Mantine UI
- **Icons**: Tabler Icons
- **HTTP Client**: Axios
- **Date Handling**: Day.js

## Features

- **Dashboard**: Overview statistics and metrics
- **Venue Management**: Approve/reject venues, view details
- **Booking Management**: View all bookings with filters
- **Payout Management**: Manage owner payouts

## Setup

1. **Install dependencies**:
```bash
npm install
```

2. **Create `.env.local` file**:
```env
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
```

3. **Run development server**:
```bash
npm run dev
```

4. **Access the dashboard**:
   - URL: http://localhost:3001
   - Login with admin phone number and OTP

## Pages

- `/login` - Admin authentication
- `/dashboard` - Overview statistics
- `/dashboard/venues` - Venue management
- `/dashboard/bookings` - Booking management
- `/dashboard/payouts` - Payout management

## Authentication

The admin portal uses the same OTP authentication as the main API. Admin users must have `role: 'admin'` in the database.

## Development

- Run dev server: `npm run dev`
- Build for production: `npm run build`
- Start production server: `npm start`




