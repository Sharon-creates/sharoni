// Supabase Edge Function: check-missed-doses
// This function is scheduled via pg_cron to run every minute.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

function getLocalParts(date: Date, timeZone: string) {
  try {
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone,
      year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', second: '2-digit',
      hour12: false
    });
    const parts = formatter.formatToParts(date);
    const partMap = Object.fromEntries(parts.map(p => [p.type, p.value]));
    return {
      year: parseInt(partMap.year, 10),
      month: parseInt(partMap.month, 10),
      day: parseInt(partMap.day, 10),
      hour: parseInt(partMap.hour, 10),
      minute: parseInt(partMap.minute, 10)
    };
  } catch {
    // fallback to UTC if timezone is invalid
    return {
      year: date.getUTCFullYear(),
      month: date.getUTCMonth() + 1,
      day: date.getUTCDate(),
      hour: date.getUTCHours(),
      minute: date.getUTCMinutes()
    };
  }
}

// Convert local year/month/day/hour/minute/timezone back to UTC Date
function getUTCFromLocal(year: number, month: number, day: number, hour: number, minute: number, timezone: string): Date {
  try {
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', second: '2-digit',
      hour12: false
    });
    const utcGuess = new Date(Date.UTC(year, month - 1, day, hour, minute));
    const parts = formatter.formatToParts(utcGuess);
    const partMap = Object.fromEntries(parts.map(p => [p.type, p.value]));
    
    const formattedLocal = Date.UTC(
      parseInt(partMap.year, 10),
      parseInt(partMap.month, 10) - 1,
      parseInt(partMap.day, 10),
      parseInt(partMap.hour, 10),
      parseInt(partMap.minute, 10)
    );
    const targetLocal = Date.UTC(year, month - 1, day, hour, minute);
    const diff = targetLocal - formattedLocal;
    return new Date(utcGuess.getTime() + diff);
  } catch {
    return new Date(Date.UTC(year, month - 1, day, hour, minute));
  }
}

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { data: medications, error: medError } = await supabase
    .from('medications')
    .select('*, profiles(username, emergency_contact_phone, timezone, escalation_enabled)')
    .eq('is_enabled', true)

  if (medError) return new Response(JSON.stringify({ error: medError.message }), { status: 500 })

  const alertsTriggered = [];

  for (const med of medications) {
    const profile = med.profiles;
    if (!profile) continue;

    const timezone = profile.timezone || 'UTC';
    const localNowParts = getLocalParts(new Date(), timezone);
    const scheduledTimes = med.scheduled_times || [];

    // Get all medication logs for this medication
    const { data: logs, error: logsError } = await supabase
      .from('medication_logs')
      .select('*')
      .eq('medication_id', med.id);

    if (logsError) {
      console.error(`Error fetching logs for medication ${med.id}:`, logsError.message);
      continue;
    }

    for (const timeStr of scheduledTimes) {
      const [hourStr, minuteStr] = timeStr.split(':');
      const schedHour = parseInt(hourStr, 10);
      const schedMin = parseInt(minuteStr, 10);

      // local values in milliseconds
      const localNowMs = Date.UTC(localNowParts.year, localNowParts.month - 1, localNowParts.day, localNowParts.hour, localNowParts.minute);
      const localSchedMs = Date.UTC(localNowParts.year, localNowParts.month - 1, localNowParts.day, schedHour, schedMin);

      // Check if scheduled time has passed
      if (localNowMs > localSchedMs) {
        const diffMinutes = (localNowMs - localSchedMs) / (60 * 1000);
        const confirmationWindow = 15; // 15-minute confirmation window

        if (diffMinutes >= confirmationWindow) {
          // Look for any existing log for this medication and this hour/minute on the same local date
          const hasLog = logs.some(l => {
            const logParts = getLocalParts(new Date(l.scheduled_for), timezone);
            return logParts.year === localNowParts.year &&
                   logParts.month === localNowParts.month &&
                   logParts.day === localNowParts.day &&
                   logParts.hour === schedHour &&
                   logParts.minute === schedMin;
          });

          if (!hasLog) {
            // Mark as missed by inserting a new medication log
            const scheduledForUTC = getUTCFromLocal(
              localNowParts.year,
              localNowParts.month - 1 + 1, // month is 1-indexed in getUTCFromLocal parameters
              localNowParts.day,
              schedHour,
              schedMin,
              timezone
            );

            const { error: insertError } = await supabase
              .from('medication_logs')
              .insert({
                medication_id: med.id,
                user_id: med.user_id,
                status: 'missed',
                scheduled_for: scheduledForUTC.toISOString(),
                logged_at: new Date().toISOString()
              });

            if (insertError) {
              console.error(`Failed to insert missed log: ${insertError.message}`);
              continue;
            }

            // Escalation Alert logic
            if (profile.escalation_enabled !== false && profile.emergency_contact_phone) {
              const recipient = profile.emergency_contact_phone;
              const patientName = profile.username || 'Patient';
              
              console.log(`[ESCALATION ALERT] ${patientName} missed confirmation window for ${med.name}. Notifying emergency contact ${recipient}.`);
              
              alertsTriggered.push({
                medication: med.name,
                patientName,
                recipient,
                status: 'missed'
              });
              
              // Future: Twilio / Push Notification / Webhook call could be made here
            }
          }
        }
      }
    }
  }

  return new Response(JSON.stringify({ 
    status: 'Check complete', 
    alerts_triggered: alertsTriggered 
  }), { status: 200 })
})
