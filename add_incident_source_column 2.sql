-- ================================================================
-- Migration: Add 'source' column to trip_incidents
-- Distinguishes voice-reported incidents from manual form reports.
-- Run this in the Supabase SQL Editor.
-- ================================================================

ALTER TABLE trip_incidents
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual'
    CHECK (source IN ('manual', 'voice'));

-- Index for dashboard query (recent voice incidents across all trips)
CREATE INDEX IF NOT EXISTS idx_trip_incidents_source_created
    ON trip_incidents (source, created_at DESC);
