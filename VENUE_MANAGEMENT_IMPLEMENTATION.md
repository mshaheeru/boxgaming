# Venue Management Feature Implementation

## Overview
This document describes the implementation of the Venue Management feature for Owners, allowing them to create, view, update, and manage activation status of venues within their tenant scope.

## Database Changes

### Migration Script
**File:** `backend/scripts/add-venue-is-active.sql`

- Added `is_active` BOOLEAN field to `venues` table (defaults to `false`)
- Updated existing active venues to have `is_active = true`
- Created indexes for performance: `idx_venues_is_active` and `idx_venues_tenant_is_active`

**To apply:** Run this SQL script in your Supabase SQL editor.

## Backend Changes

### 1. VenuesService (`backend/src/venues/venues.service.ts`)
- **create()**: New venues default to `is_active: false`
- **findAll()**: Filters by `is_active: true` for customers (no tenantId), shows all venues for owners (with tenantId)
- **findOne()**: Added tenant and role checks to enforce customer-only access to active venues
- **activate()**: New method to activate a venue (owner-only, tenant-scoped)
- **deactivate()**: New method to deactivate a venue (owner-only, tenant-scoped)

### 2. VenuesController (`backend/src/venues/venues.controller.ts`)
- **PUT /venues/:id/activate**: Activate venue endpoint (owner/admin only)
- **PUT /venues/:id/deactivate**: Deactivate venue endpoint (owner/admin only)
- Updated `findOne()` to pass tenant and role information

### 3. API Endpoints
- `GET /venues/my-venues` - Get owner's venues (already existed, now includes `is_active`)
- `PUT /venues/:id/activate` - Activate venue
- `PUT /venues/:id/deactivate` - Deactivate venue

## Frontend Changes (Flutter)

### 1. Data Models
- **VenueModel**: Added `isActive` field with JSON mapping `is_active`
- **VenueEntity**: Added `isActive` boolean field

### 2. Venue Management Feature
Created complete feature structure following clean architecture:

**Data Layer:**
- `venue_management_remote_datasource.dart` - API calls for venue management
- `venue_management_repository_impl.dart` - Repository implementation
- `create_venue_dto.dart` - DTO for creating venues
- `update_venue_dto.dart` - DTO for updating venues

**Domain Layer:**
- `venue_management_repository.dart` - Repository interface
- Use cases:
  - `get_my_venues_usecase.dart`
  - `create_venue_usecase.dart`
  - `update_venue_usecase.dart`
  - `activate_venue_usecase.dart`
  - `deactivate_venue_usecase.dart`

**Presentation Layer:**
- `venue_management_bloc.dart` - BLoC for state management
- `venue_management_event.dart` - Events
- `venue_management_state.dart` - States
- `venue_management_page.dart` - UI page with:
  - List of venues with Active/Inactive status
  - Create venue dialog
  - Edit venue dialog
  - Activate/Deactivate toggle buttons

### 3. Owner Dashboard Updates
- Converted to tabbed interface with two tabs:
  - **Dashboard Tab**: Existing bookings and stats
  - **Venue Management Tab**: New venue management interface

### 4. Dependency Injection
- Added all venue management dependencies to `injection_container.dart`

### 5. API Constants
- Added endpoints:
  - `myVenues` - `/venues/my-venues`
  - `activateVenue(id)` - `/venues/$id/activate`
  - `deactivateVenue(id)` - `/venues/$id/deactivate`

## Security & Access Control

### Tenant Isolation
- All venue operations are strictly scoped to the owner's `tenant_id`
- Backend validates `tenant_id` on all create, update, activate, and deactivate operations
- Cross-tenant access is prevented at the service layer

### Role-Based Access
- **Owners**: Full CRUD + activate/deactivate on their tenant's venues
- **Customers**: Read-only access to active venues only (`is_active = true`)
- **Admins**: Full access (can activate/deactivate any venue)

### Backend Enforcement
- `JwtAuthGuard` + `RolesGuard` protect all owner endpoints
- Tenant validation in service layer prevents unauthorized access
- Customer queries automatically filter by `is_active = true`

## User Experience

### Owner Experience
1. Navigate to Owner Dashboard
2. Switch to "Venue Management" tab
3. View all venues (active and inactive) for their tenant
4. Create new venues (default to inactive)
5. Edit venue details
6. Toggle venue activation status
7. See clear Active/Inactive status indicators

### Customer Experience
1. Browse venues list (only active venues visible)
2. View venue details (only if active)
3. No create, edit, or activation controls visible

## Testing Checklist

### Backend
- [ ] Run database migration script
- [ ] Test creating venue (should default to inactive)
- [ ] Test activating venue (owner only, tenant-scoped)
- [ ] Test deactivating venue (owner only, tenant-scoped)
- [ ] Test customer can only see active venues
- [ ] Test owner can see all venues in their tenant
- [ ] Test cross-tenant access prevention

### Frontend
- [ ] Rebuild Flutter app (to regenerate JSON serialization)
- [ ] Test venue management tab appears for owners
- [ ] Test creating venue
- [ ] Test editing venue
- [ ] Test activating venue
- [ ] Test deactivating venue
- [ ] Test customer view only shows active venues
- [ ] Test tenant isolation (owners only see their tenant's venues)

## Notes

1. **JSON Serialization**: After adding `isActive` to `VenueModel`, you may need to regenerate the JSON serialization code:
   ```bash
   cd boxgaming
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Database Migration**: The migration script should be run in Supabase SQL editor before testing.

3. **Default Behavior**: New venues are created as inactive by default, requiring owners to manually activate them.

4. **Soft Delete**: Deletion functionality was not added as requested. The existing delete endpoint remains unchanged.

## Files Modified/Created

### Backend
- `backend/scripts/add-venue-is-active.sql` (NEW)
- `backend/src/venues/venues.service.ts` (MODIFIED)
- `backend/src/venues/venues.controller.ts` (MODIFIED)

### Frontend
- `boxgaming/lib/features/venues/data/models/venue_model.dart` (MODIFIED)
- `boxgaming/lib/features/venues/domain/entities/venue_entity.dart` (MODIFIED)
- `boxgaming/lib/features/venues/dto/create_venue_dto.dart` (NEW)
- `boxgaming/lib/features/venues/dto/update_venue_dto.dart` (NEW)
- `boxgaming/lib/features/owner/data/datasources/venue_management_remote_datasource.dart` (NEW)
- `boxgaming/lib/features/owner/data/repositories/venue_management_repository_impl.dart` (NEW)
- `boxgaming/lib/features/owner/domain/repositories/venue_management_repository.dart` (NEW)
- `boxgaming/lib/features/owner/domain/usecases/*.dart` (5 NEW files)
- `boxgaming/lib/features/owner/presentation/bloc/venue_management_*.dart` (3 NEW files)
- `boxgaming/lib/features/owner/presentation/pages/venue_management_page.dart` (NEW)
- `boxgaming/lib/features/owner/presentation/pages/owner_dashboard_page.dart` (MODIFIED)
- `boxgaming/lib/core/constants/api_constants.dart` (MODIFIED)
- `boxgaming/lib/core/di/injection_container.dart` (MODIFIED)

