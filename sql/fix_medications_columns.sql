-- ============================================
-- COMPREHENSIVE FIX: Run this in Supabase SQL Editor
-- Adds ALL missing columns to the medications table.
-- Uses IF NOT EXISTS so it is safe to re-run.
-- ============================================

-- Core columns
alter table public.medications add column if not exists name text;
alter table public.medications add column if not exists dosage_per_intake text;
alter table public.medications add column if not exists scheduled_times text[];
alter table public.medications add column if not exists total_quantity int;
alter table public.medications add column if not exists remaining_quantity int;
alter table public.medications add column if not exists duration_days int;
alter table public.medications add column if not exists start_date timestamp with time zone default now();
alter table public.medications add column if not exists end_date timestamp with time zone;
alter table public.medications add column if not exists is_enabled boolean default true;
alter table public.medications add column if not exists is_archived boolean default false;
alter table public.medications add column if not exists created_at timestamp with time zone default now();

-- Also ensure profiles has all needed columns
alter table public.profiles add column if not exists preferred_alert_channel text default 'WhatsApp';
alter table public.profiles add column if not exists timezone text default 'UTC';
alter table public.profiles add column if not exists facebook_id text;
alter table public.profiles add column if not exists instagram_id text;
alter table public.profiles add column if not exists whatsapp_number text;
alter table public.profiles add column if not exists escalation_enabled boolean default true;
alter table public.profiles add column if not exists measurement_unit text default 'metric';
alter table public.profiles add column if not exists notif_sound boolean default true;
alter table public.profiles add column if not exists notif_vibrate boolean default true;
alter table public.profiles add column if not exists critical_alerts boolean default false;
alter table public.profiles add column if not exists daily_digest_enabled boolean default false;

-- Force PostgREST to reload its schema cache immediately
notify pgrst, 'reload schema';
