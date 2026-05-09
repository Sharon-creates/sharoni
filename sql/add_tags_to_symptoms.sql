-- SQL to add tags column to public.symptoms table
ALTER TABLE public.symptoms 
ADD COLUMN tags text[] DEFAULT '{}';

-- Update RLS policies if necessary (usually not needed for just a new column if using SELECT *)
-- Verify the column was added
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'symptoms';
