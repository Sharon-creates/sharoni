-- ============================================
-- RUN THIS IN SUPABASE SQL EDITOR
-- Updates the status check constraint on medication_logs table
-- ============================================

-- 1. Drop existing constraint
ALTER TABLE public.medication_logs DROP CONSTRAINT IF EXISTS medication_logs_status_check;

-- 2. Add updated constraint to support 'ignored' and 'pending'
ALTER TABLE public.medication_logs ADD CONSTRAINT medication_logs_status_check 
    CHECK (status IN ('taken', 'missed', 'skipped', 'ignored', 'pending'));
