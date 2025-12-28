-- Migration: Add is_active field to venues table
-- This field allows owners to control venue visibility independently from admin status

-- Add is_active column with default false (new venues are inactive by default)
ALTER TABLE venues 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT false;

-- Update existing venues: set is_active = true where status = 'active'
-- This ensures existing active venues remain visible
UPDATE venues 
SET is_active = true 
WHERE status = 'active' AND is_active IS NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_venues_is_active ON venues(is_active);
CREATE INDEX IF NOT EXISTS idx_venues_tenant_is_active ON venues(tenant_id, is_active);

