-- Script to delete seeded venues (venues with placeholder images and no tenant_id)
-- These are test/seed data that should not be visible to customers

-- First, let's identify the seeded venues
-- Seeded venues typically have:
-- 1. tenant_id IS NULL (not created through the owner management system)
-- 2. photos containing 'picsum.photos' (placeholder image service)
-- 3. owner_id that might not correspond to a valid owner in the tenant system

-- Delete bookings that reference grounds from seeded venues first
DELETE FROM bookings 
WHERE ground_id IN (
  SELECT g.id FROM grounds g
  INNER JOIN venues v ON g.venue_id = v.id
  WHERE v.tenant_id IS NULL 
  OR (v.photos IS NOT NULL AND array_to_string(v.photos, ',') LIKE '%picsum.photos%')
);

-- Delete grounds associated with seeded venues (after bookings are deleted)
DELETE FROM grounds 
WHERE venue_id IN (
  SELECT id FROM venues 
  WHERE tenant_id IS NULL 
  OR (photos IS NOT NULL AND array_to_string(photos, ',') LIKE '%picsum.photos%')
);

-- Delete operating hours associated with seeded venues
DELETE FROM operating_hours 
WHERE venue_id IN (
  SELECT id FROM venues 
  WHERE tenant_id IS NULL 
  OR (photos IS NOT NULL AND array_to_string(photos, ',') LIKE '%picsum.photos%')
);

-- Delete any remaining bookings associated with seeded venues
DELETE FROM bookings 
WHERE venue_id IN (
  SELECT id FROM venues 
  WHERE tenant_id IS NULL 
  OR (photos IS NOT NULL AND array_to_string(photos, ',') LIKE '%picsum.photos%')
);

-- Finally, delete the seeded venues themselves
DELETE FROM venues 
WHERE tenant_id IS NULL 
OR (photos IS NOT NULL AND array_to_string(photos, ',') LIKE '%picsum.photos%');

-- Verify deletion: This should return 0 rows
SELECT COUNT(*) as remaining_seeded_venues
FROM venues 
WHERE tenant_id IS NULL 
OR (photos IS NOT NULL AND array_to_string(photos, ',') LIKE '%picsum.photos%');

