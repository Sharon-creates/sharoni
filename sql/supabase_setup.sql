-- 1. Create Profiles Table (for optional user info)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text,
  age text,
  height text,
  weight text,
  sex text,
  blood_type text,
  genotype text,
  medical_conditions text,
  allergies text,
  current_medications text,
  emergency_contact_name text,
  emergency_contact_phone text,
  emergency_contact_relationship text,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Ensure cascading delete if table already existed
alter table public.profiles 
  drop constraint if exists profiles_id_fkey,
  add constraint profiles_id_fkey foreign key (id) references auth.users(id) on delete cascade;

-- Add missing columns to profiles if they don't exist
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='weight') then
    alter table public.profiles add column weight text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='sex') then
    alter table public.profiles add column sex text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='genotype') then
    alter table public.profiles add column genotype text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='medical_conditions') then
    alter table public.profiles add column medical_conditions text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='allergies') then
    alter table public.profiles add column allergies text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='current_medications') then
    alter table public.profiles add column current_medications text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='emergency_contact_name') then
    alter table public.profiles add column emergency_contact_name text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='emergency_contact_phone') then
    alter table public.profiles add column emergency_contact_phone text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='emergency_contact_relationship') then
    alter table public.profiles add column emergency_contact_relationship text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='preferred_alert_channel') then
    alter table public.profiles add column preferred_alert_channel text default 'WhatsApp';
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='timezone') then
    alter table public.profiles add column timezone text default 'UTC';
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='facebook_id') then
    alter table public.profiles add column facebook_id text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='profiles' and column_name='instagram_id') then
    alter table public.profiles add column instagram_id text;
  end if;
end $$;


-- 2. Create Medications Table
create table if not exists public.medications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  dosage_per_intake text not null,
  scheduled_times text[] not null, -- Array of "HH:mm" strings
  total_quantity int,
  remaining_quantity int,
  duration_days int,
  start_date timestamp with time zone default now() not null,
  end_date timestamp with time zone,
  is_enabled boolean default true,
  is_archived boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Ensure cascading delete if table already existed
alter table public.medications 
  drop constraint if exists medications_user_id_fkey,
  add constraint medications_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade;

-- Add missing columns to medications (uses IF NOT EXISTS — safe to re-run)
alter table public.medications add column if not exists remaining_quantity int;
alter table public.medications add column if not exists duration_days int;
alter table public.medications add column if not exists end_date timestamp with time zone;
alter table public.medications add column if not exists is_enabled boolean default true;
alter table public.medications add column if not exists is_archived boolean default false;


-- 2.1 Create Medication Logs Table
create table if not exists public.medication_logs (
  id uuid default gen_random_uuid() primary key,
  medication_id uuid references public.medications on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  status text not null check (status in ('taken', 'missed', 'skipped', 'ignored', 'pending')),
  scheduled_for timestamp with time zone not null,
  logged_at timestamp with time zone default now() not null
);

-- Ensure cascading delete if table already existed
alter table public.medication_logs 
  drop constraint if exists medication_logs_user_id_fkey,
  add constraint medication_logs_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade;

-- 3. Create Symptom History Table
create table if not exists public.symptoms (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  description text not null,
  analysis_result text,
  possible_causes text,
  first_aid text,
  follow_up_logic text,
  follow_up_questions text[],
  follow_up_answers text[],
  tags text[],
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Ensure cascading delete if table already existed
alter table public.symptoms 
  drop constraint if exists symptoms_user_id_fkey,
  add constraint symptoms_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade;

-- Add missing columns to symptoms if they don't exist
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name='symptoms' and column_name='possible_causes') then
    alter table public.symptoms add column possible_causes text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='symptoms' and column_name='first_aid') then
    alter table public.symptoms add column first_aid text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='symptoms' and column_name='follow_up_logic') then
    alter table public.symptoms add column follow_up_logic text;
  end if;
  if not exists (select 1 from information_schema.columns where table_name='symptoms' and column_name='follow_up_questions') then
    alter table public.symptoms add column follow_up_questions text[];
  end if;
  if not exists (select 1 from information_schema.columns where table_name='symptoms' and column_name='follow_up_answers') then
    alter table public.symptoms add column follow_up_answers text[];
  end if;
  if not exists (select 1 from information_schema.columns where table_name='symptoms' and column_name='tags') then
    alter table public.symptoms add column tags text[];
  end if;
end $$;






-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.medications enable row level security;
alter table public.medication_logs enable row level security;
alter table public.symptoms enable row level security;

-- Set up RLS Policies

-- Profiles: Users can only see/update their own profile
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- Medications: Users can only see/manage their own medications
drop policy if exists "Users can view own medications" on public.medications;
create policy "Users can view own medications" on public.medications
  for select using (auth.uid() = user_id);

drop policy if exists "Users can manage own medications" on public.medications;
create policy "Users can manage own medications" on public.medications
  for all using (auth.uid() = user_id);

-- Medication Logs: Users can only manage their own logs
drop policy if exists "Users can view own logs" on public.medication_logs;
create policy "Users can view own logs" on public.medication_logs
  for select using (auth.uid() = user_id);

drop policy if exists "Users can manage own logs" on public.medication_logs;
create policy "Users can manage own logs" on public.medication_logs
  for all using (auth.uid() = user_id);

-- Symptoms: Users can only see/manage their own symptoms
drop policy if exists "Users can view own symptoms" on public.symptoms;
create policy "Users can view own symptoms" on public.symptoms
  for select using (auth.uid() = user_id);

drop policy if exists "Users can manage own symptoms" on public.symptoms;
create policy "Users can manage own symptoms" on public.symptoms
  for all using (auth.uid() = user_id);

-- 4. Function to allow users to delete their own account
-- Note: This requires the service_role or a superuser to create, 
-- but it allows a user to trigger their own deletion from auth.users
create or replace function public.delete_user()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;


-- 5. Create Drug Dictionary Table
create table if not exists public.drug_dictionary (
  id uuid default gen_random_uuid() primary key,
  drug_name text not null unique,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.drug_dictionary enable row level security;

-- Allow anonymous read access
drop policy if exists "Allow public read access to drug dictionary" on public.drug_dictionary;
create policy "Allow public read access to drug dictionary" on public.drug_dictionary
  for select using (true);

-- Pre-populate some drugs
insert into public.drug_dictionary (drug_name) values
  ('Paracetamol'),
  ('Panadol'),
  ('Aspirin'),
  ('Ibuprofen'),
  ('Amoxicillin'),
  ('Metformin'),
  ('Atorvastatin'),
  ('Lisinopril'),
  ('Albuterol'),
  ('Omeprazole'),
  ('Penicillin'),
  ('Insulin')
on conflict (drug_name) do nothing;


