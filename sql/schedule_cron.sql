-- Enable pg_cron extension if not already enabled
create extension if not exists pg_cron;

-- Enable pg_net extension if not already enabled (used for http requests)
create extension if not exists pg_net;

-- Unschedules the job if it already exists to avoid duplicate scheduling
do $$
begin
  if exists (select 1 from cron.job where jobname = 'check-missed-doses-every-minute') then
    perform cron.unschedule('check-missed-doses-every-minute');
  end if;
end $$;


-- Schedule the edge function to run every minute
-- Note: Replace <project-ref> and <service-role-key> with actual Supabase project reference and service key.
-- Or reference them via Vault if configured.
select cron.schedule(
  'check-missed-doses-every-minute',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://<project-ref>.supabase.co/functions/v1/check_missed_doses',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <service-role-key>'
    ),
    body := '{}'
  );
  $$
);
