-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.spatial_ref_sys (
  srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
  auth_name character varying,
  auth_srid integer,
  srtext character varying,
  proj4text character varying,
  CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);
CREATE TABLE public.roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  role_name character varying NOT NULL UNIQUE,
  CONSTRAINT roles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  full_name character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  password_hash character varying,
  phone character varying UNIQUE,
  role_id uuid NOT NULL,
  status USER-DEFINED DEFAULT 'active'::user_status_enum,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  license_number character varying UNIQUE,
  created_by_manager_id uuid,
  is_on_duty boolean DEFAULT true,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_created_by_manager_id_fkey FOREIGN KEY (created_by_manager_id) REFERENCES public.users(id),
  CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.vehicles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  make character varying NOT NULL,
  model character varying NOT NULL,
  year integer CHECK (year >= 1900 AND year <= 2100),
  vin character varying UNIQUE,
  license_plate character varying NOT NULL UNIQUE,
  assigned_driver_id uuid,
  status USER-DEFINED DEFAULT 'available'::vehicle_status_enum,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  tank_capacity numeric,
  mileage numeric,
  vehicle_type text,
  admin_id uuid,
  purchase_date date,
  CONSTRAINT vehicles_pkey PRIMARY KEY (id),
  CONSTRAINT vehicles_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id),
  CONSTRAINT vehicles_assigned_driver_id_fkey FOREIGN KEY (assigned_driver_id) REFERENCES public.users(id)
);
CREATE TABLE public.routes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  route_name character varying NOT NULL,
  start_location character varying NOT NULL,
  end_location character varying NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by_manager_id uuid,
  CONSTRAINT routes_pkey PRIMARY KEY (id),
  CONSTRAINT routes_created_by_manager_id_fkey FOREIGN KEY (created_by_manager_id) REFERENCES public.users(id)
);
CREATE TABLE public.trips (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  driver_id uuid,
  route_id uuid,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone,
  distance numeric,
  status USER-DEFINED DEFAULT 'scheduled'::trip_status_enum,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  order_type character varying,
  CONSTRAINT trips_pkey PRIMARY KEY (id),
  CONSTRAINT trips_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id),
  CONSTRAINT trips_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.routes(id),
  CONSTRAINT trips_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id)
);
CREATE TABLE public.vehicle_inspections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  driver_id uuid,
  trip_id uuid,
  inspection_type USER-DEFINED NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vehicle_inspections_pkey PRIMARY KEY (id),
  CONSTRAINT vehicle_inspections_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id),
  CONSTRAINT vehicle_inspections_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id),
  CONSTRAINT vehicle_inspections_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id)
);
CREATE TABLE public.defect_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL,
  description text NOT NULL,
  severity USER-DEFINED DEFAULT 'medium'::severity_level,
  status USER-DEFINED DEFAULT 'open'::resolution_status,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  reported_by uuid,
  CONSTRAINT defect_reports_pkey PRIMARY KEY (id),
  CONSTRAINT defect_reports_inspection_id_fkey FOREIGN KEY (inspection_id) REFERENCES public.vehicle_inspections(id),
  CONSTRAINT defect_reports_reported_by_fkey FOREIGN KEY (reported_by) REFERENCES public.users(id)
);
CREATE TABLE public.fuel_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  driver_id uuid,
  liters_used numeric NOT NULL CHECK (liters_used > 0::numeric),
  fuel_cost numeric NOT NULL CHECK (fuel_cost > 0::numeric),
  recorded_at timestamp with time zone DEFAULT now(),
  bill_url text,
  CONSTRAINT fuel_logs_pkey PRIMARY KEY (id),
  CONSTRAINT fuel_logs_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id),
  CONSTRAINT fuel_logs_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id)
);
CREATE TABLE public.trip_geofences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  zone_type text NOT NULL DEFAULT 'pickup'::text,
  created_at timestamp with time zone DEFAULT now(),
  trip_id uuid,
  vehicle_id uuid,
  driver_id uuid,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  radius_meters double precision NOT NULL DEFAULT 250,
  is_active boolean DEFAULT true,
  CONSTRAINT trip_geofences_pkey PRIMARY KEY (id),
  CONSTRAINT trip_geofences_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id),
  CONSTRAINT trip_geofences_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id)
);
CREATE TABLE public.trip_geofence_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  geofence_id uuid NOT NULL,
  vehicle_id uuid,
  event_type text NOT NULL,
  occurred_at timestamp with time zone DEFAULT now(),
  driver_id uuid,
  latitude double precision,
  longitude double precision,
  CONSTRAINT trip_geofence_events_pkey PRIMARY KEY (id),
  CONSTRAINT trip_geofence_events_geofence_id_fkey FOREIGN KEY (geofence_id) REFERENCES public.trip_geofences(id),
  CONSTRAINT trip_geofence_events_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id)
);
CREATE TABLE public.inspection_photos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL,
  image_url character varying NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT inspection_photos_pkey PRIMARY KEY (id),
  CONSTRAINT inspection_photos_inspection_id_fkey FOREIGN KEY (inspection_id) REFERENCES public.vehicle_inspections(id)
);
CREATE TABLE public.inventory (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  part_name character varying NOT NULL,
  stock_quantity integer NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  reorder_level integer DEFAULT 10,
  unit_cost numeric,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  admin_id uuid,
  CONSTRAINT inventory_pkey PRIMARY KEY (id),
  CONSTRAINT inventory_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id)
);
CREATE TABLE public.work_orders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  created_by uuid,
  assigned_to uuid,
  priority USER-DEFINED DEFAULT 'medium'::priority_level,
  status USER-DEFINED DEFAULT 'pending'::lifecycle_status,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  completed_at timestamp with time zone,
  CONSTRAINT work_orders_pkey PRIMARY KEY (id),
  CONSTRAINT work_orders_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id),
  CONSTRAINT work_orders_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id),
  CONSTRAINT work_orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.maintenance_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  work_order_id uuid,
  description text,
  scheduled_date date NOT NULL,
  status USER-DEFINED DEFAULT 'pending'::lifecycle_status,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  vehicle_id uuid,
  scheduled_by uuid,
  assigned_to uuid,
  task_type character varying,
  target_mileage numeric,
  service_interval_months integer,
  schedule_type character varying,
  completed_at timestamp with time zone,
  CONSTRAINT maintenance_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT maintenance_tasks_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id),
  CONSTRAINT maintenance_tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id),
  CONSTRAINT maintenance_tasks_scheduled_by_fkey FOREIGN KEY (scheduled_by) REFERENCES public.users(id),
  CONSTRAINT maintenance_tasks_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES public.work_orders(id)
);
CREATE TABLE public.maintenance_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  work_order_id uuid,
  service_details text NOT NULL,
  cost numeric,
  completed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT maintenance_history_pkey PRIMARY KEY (id),
  CONSTRAINT maintenance_history_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id),
  CONSTRAINT maintenance_history_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES public.work_orders(id)
);
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sender_id uuid,
  receiver_id uuid,
  message text NOT NULL,
  sent_at timestamp with time zone DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id),
  CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title character varying NOT NULL,
  message text NOT NULL,
  type character varying NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  reference_id uuid,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  generated_by uuid,
  report_type character varying NOT NULL,
  file_url character varying NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reports_pkey PRIMARY KEY (id),
  CONSTRAINT reports_generated_by_fkey FOREIGN KEY (generated_by) REFERENCES public.users(id)
);
CREATE TABLE public.vehicle_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  document_type character varying NOT NULL,
  file_url character varying NOT NULL,
  expiry_date date,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vehicle_documents_pkey PRIMARY KEY (id),
  CONSTRAINT vehicle_documents_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id)
);
CREATE TABLE public.vehicle_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  speed numeric,
  recorded_at timestamp with time zone DEFAULT now(),
  latitude numeric,
  longitude numeric,
  CONSTRAINT vehicle_locations_pkey PRIMARY KEY (id),
  CONSTRAINT vehicle_locations_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id)
);
CREATE TABLE public.work_order_parts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  work_order_id uuid NOT NULL,
  inventory_item_id uuid,
  quantity_used integer NOT NULL CHECK (quantity_used > 0),
  hours_spent numeric,
  CONSTRAINT work_order_parts_pkey PRIMARY KEY (id),
  CONSTRAINT work_order_parts_work_order_id_fkey FOREIGN KEY (work_order_id) REFERENCES public.work_orders(id),
  CONSTRAINT work_order_parts_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory(id)
);
CREATE TABLE public.issue_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  reported_by uuid NOT NULL,
  category character varying NOT NULL,
  severity character varying NOT NULL,
  description text,
  status character varying NOT NULL DEFAULT 'open'::character varying,
  assigned_to uuid,
  created_at timestamp with time zone DEFAULT now(),
  issue_photo text,
  CONSTRAINT issue_reports_pkey PRIMARY KEY (id),
  CONSTRAINT issue_reports_reported_by_fkey FOREIGN KEY (reported_by) REFERENCES public.users(id),
  CONSTRAINT issue_reports_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id),
  CONSTRAINT issue_reports_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id)
);
CREATE TABLE public.trip_updates (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  trip_id uuid NOT NULL,
  update_type character varying NOT NULL,
  message text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT trip_updates_pkey PRIMARY KEY (id),
  CONSTRAINT trip_updates_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id)
);
CREATE TABLE public.trip_incidents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  trip_id uuid NOT NULL,
  driver_id uuid,
  incident_type text NOT NULL,
  description text NOT NULL,
  location text NOT NULL,
  photo_url text,
  created_at timestamp with time zone DEFAULT now(),
  source text DEFAULT 'manual'::text CHECK (source = ANY (ARRAY['manual'::text, 'voice'::text])),
  CONSTRAINT trip_incidents_pkey PRIMARY KEY (id),
  CONSTRAINT trip_incidents_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id),
  CONSTRAINT trip_incidents_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id)
);
CREATE TABLE public.voice_trip_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  trip_id uuid NOT NULL,
  driver_id uuid,
  transcription text NOT NULL,
  extracted_location text,
  extracted_mileage numeric,
  extracted_eta text,
  extracted_status text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT voice_trip_logs_pkey PRIMARY KEY (id),
  CONSTRAINT voice_trip_logs_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id),
  CONSTRAINT voice_trip_logs_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id)
);
CREATE TABLE public.route_breach_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  trip_id uuid,
  vehicle_id uuid,
  driver_id uuid,
  latitude double precision,
  longitude double precision,
  distance_from_center double precision,
  fence_radius double precision,
  occurred_at timestamp with time zone DEFAULT now(),
  CONSTRAINT route_breach_events_pkey PRIMARY KEY (id),
  CONSTRAINT route_breach_events_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id)
);