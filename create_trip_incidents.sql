-- Run this command in your Supabase SQL Editor to create the required table

CREATE TABLE trip_incidents (
    id UUID PRIMARY KEY,
    trip_id UUID NOT NULL,
    driver_id UUID,
    incident_type TEXT NOT NULL,
    description TEXT NOT NULL,
    location TEXT NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Set up Row Level Security (RLS) to allow inserts and selects if you have RLS enabled
ALTER TABLE trip_incidents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON "public"."trip_incidents"
AS PERMISSIVE FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable insert access for all users" ON "public"."trip_incidents"
AS PERMISSIVE FOR INSERT
TO public
WITH CHECK (true);
