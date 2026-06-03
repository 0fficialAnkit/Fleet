-- ================================================================
-- Migration: Create voice_trip_logs table
-- Run this in the Supabase SQL Editor before building the app.
-- ================================================================

CREATE TABLE IF NOT EXISTS voice_trip_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id             UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    driver_id           UUID REFERENCES users(id) ON DELETE SET NULL,
    transcription       TEXT NOT NULL,
    extracted_location  TEXT,
    extracted_mileage   NUMERIC(10, 2),
    extracted_eta       TEXT,
    extracted_status    TEXT,   -- 'en_route' | 'delayed' | 'arrived' | 'picked_up' | 'breakdown' | 'other'
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast per-trip queries (used by driver + fleet manager views)
CREATE INDEX IF NOT EXISTS idx_voice_trip_logs_trip_id
    ON voice_trip_logs (trip_id, created_at DESC);

-- Index for the fleet manager "recent updates" feed (cross-trip)
CREATE INDEX IF NOT EXISTS idx_voice_trip_logs_created_at
    ON voice_trip_logs (created_at DESC);

-- Enable Row Level Security
ALTER TABLE voice_trip_logs ENABLE ROW LEVEL SECURITY;

-- Policy: authenticated users can insert and read their own trip's logs
CREATE POLICY "Drivers can insert their own voice logs"
    ON voice_trip_logs FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Authenticated users can read voice logs"
    ON voice_trip_logs FOR SELECT
    TO authenticated
    USING (true);
