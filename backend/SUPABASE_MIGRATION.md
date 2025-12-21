# Supabase Migration Guide

This document outlines the migration from PostgreSQL/Prisma to Supabase.

## Completed Changes

✅ Removed PostgreSQL service from Docker Compose files
✅ Removed Prisma dependencies from package.json
✅ Added @supabase/supabase-js dependency
✅ Created SupabaseService and SupabaseModule
✅ Updated all modules to use SupabaseModule instead of PrismaModule
✅ Removed Prisma schema and migrations
✅ Updated health check to use Supabase
✅ Updated Dockerfiles to remove Prisma references
✅ Updated README.md with Supabase setup instructions

## Next Steps - Service Migration

All services currently inject `PrismaService` and need to be updated to use `SupabaseService` instead. The following services need migration:

### Services to Update:

1. **AuthService** (`src/auth/auth.service.ts`)
   - Replace Prisma queries with Supabase auth API
   - Use `supabaseService.getAuth()` for authentication operations
   - Use `supabaseService.getAdminClient()` for user lookups

2. **UsersService** (`src/users/users.service.ts`)
   - Replace `prisma.user.findUnique()` with Supabase queries
   - Replace `prisma.user.update()` with Supabase updates
   - Example: `supabase.from('users').select().eq('id', id).single()`

3. **VenuesService** (`src/venues/venues.service.ts`)
   - Replace all Prisma venue queries with Supabase queries
   - Update create, read, update operations

4. **GroundsService** (`src/grounds/grounds.service.ts`)
   - Replace Prisma ground queries with Supabase queries

5. **BookingsService** (`src/bookings/bookings.service.ts`)
   - Replace Prisma booking queries with Supabase queries
   - Update booking creation, retrieval, and status updates

6. **SlotService** (`src/bookings/slot.service.ts`)
   - Replace Prisma queries for slot availability

7. **CancellationService** (`src/bookings/cancellation.service.ts`)
   - Replace Prisma queries for cancellations

8. **PaymentsService** (`src/payments/payments.service.ts`)
   - Replace Prisma payment queries with Supabase queries

9. **PayoutsService** (`src/payouts/payouts.service.ts`)
   - Replace Prisma payout queries with Supabase queries

10. **ReviewsService** (`src/reviews/reviews.service.ts`)
    - Replace Prisma review queries with Supabase queries

11. **NotificationsService** (`src/notifications/notifications.service.ts`)
    - Replace Prisma queries for fetching booking/user data

## Supabase Query Examples

### Reading Data
```typescript
// Prisma
const user = await this.prisma.user.findUnique({ where: { id } });

// Supabase
const { data: user, error } = await this.supabaseService
  .getAdminClient()
  .from('users')
  .select()
  .eq('id', id)
  .single();
```

### Creating Data
```typescript
// Prisma
const venue = await this.prisma.venue.create({ data: venueData });

// Supabase
const { data: venue, error } = await this.supabaseService
  .getAdminClient()
  .from('venues')
  .insert(venueData)
  .select()
  .single();
```

### Updating Data
```typescript
// Prisma
const user = await this.prisma.user.update({
  where: { id },
  data: updateData,
});

// Supabase
const { data: user, error } = await this.supabaseService
  .getAdminClient()
  .from('users')
  .update(updateData)
  .eq('id', id)
  .select()
  .single();
```

### Complex Queries
```typescript
// Prisma with relations
const booking = await this.prisma.booking.findUnique({
  where: { id },
  include: { customer: true, ground: true, venue: true },
});

// Supabase with joins
const { data: booking, error } = await this.supabaseService
  .getAdminClient()
  .from('bookings')
  .select(`
    *,
    customer:users!customer_id(*),
    ground:grounds(*),
    venue:venues(*)
  `)
  .eq('id', id)
  .single();
```

## Database Setup in Supabase

You need to create the following tables in your Supabase project:

1. **users** - User accounts (customers, owners, admins)
2. **venues** - Sports venues
3. **grounds** - Individual courts/fields within venues
4. **operating_hours** - Operating hours for venues/grounds
5. **bookings** - Booking records
6. **blocked_slots** - Blocked time slots
7. **payments** - Payment transactions
8. **payouts** - Owner payouts
9. **reviews** - Customer reviews

Refer to the previous Prisma schema (in git history) for the exact table structure and relationships.

## Row Level Security (RLS)

Configure Row Level Security policies in Supabase to:
- Allow users to read their own bookings
- Allow venue owners to manage their venues and grounds
- Allow admins to access all data
- Restrict public access appropriately

## Environment Variables

Make sure to set these in your `.env` file:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

## Authentication

Supabase handles authentication, so you may want to:
- Use Supabase Auth for user management
- Integrate phone OTP through Supabase Auth
- Use Supabase JWT tokens instead of custom JWT implementation

## Storage

Use Supabase Storage for:
- Venue photos
- QR codes
- Other file uploads

Example:
```typescript
const { data, error } = await this.supabaseService
  .getStorage()
  .from('venue-photos')
  .upload(fileName, fileBuffer);
```

