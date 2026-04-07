// nanopm telemetry ingestion endpoint
// Validates and stores skill usage events
// Deploy: supabase functions deploy nanopm-telemetry

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Event schema
interface TelemetryEvent {
  skill: string
  duration_s: number
  outcome: 'success' | 'error' | 'abort' | 'unknown'
  session: string
  ts: string
}

// Allowlist of valid skill names
const VALID_SKILLS = [
  'pm-scan',
  'pm-discovery',
  'pm-audit',
  'pm-objectives',
  'pm-strategy',
  'pm-roadmap',
  'pm-prd',
  'pm-breakdown',
  'pm-retro',
  'pm-run',
  'pm-upgrade',
  'pm-user-feedback',
  'pm-competitors-intel',
]

// Validate event
function validateEvent(data: any): TelemetryEvent | null {
  // Required fields
  if (!data.skill || !data.duration_s || !data.outcome || !data.session || !data.ts) {
    return null
  }

  // Skill allowlist
  if (!VALID_SKILLS.includes(data.skill)) {
    return null
  }

  // Outcome allowlist
  if (!['success', 'error', 'abort', 'unknown'].includes(data.outcome)) {
    return null
  }

  // Duration sanity check (0-3600s = 1 hour max)
  const duration = parseInt(data.duration_s, 10)
  if (isNaN(duration) || duration < 0 || duration > 3600) {
    return null
  }

  // Session ID length check (prevent abuse)
  if (data.session.length > 100) {
    return null
  }

  // Timestamp format check (ISO 8601)
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(data.ts)) {
    return null
  }

  return {
    skill: data.skill,
    duration_s: duration,
    outcome: data.outcome,
    session: data.session,
    ts: data.ts,
  }
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only accept POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    // Parse body (expect array of events)
    const body = await req.json()
    
    if (!Array.isArray(body)) {
      return new Response(JSON.stringify({ error: 'Expected array of events' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate and map events
    const validEvents: any[] = []
    for (const item of body) {
      const event = validateEvent(item)
      if (event) {
        validEvents.push({
          skill: event.skill,
          duration_s: event.duration_s,
          outcome: event.outcome,
          session_id: event.session,
          timestamp: event.ts,
          nanopm_version: item.nanopm_version || 'unknown',
          os: item.os || 'unknown',
          arch: item.arch || 'unknown',
          sessions: item.sessions || 1,
          installation_id: item.installation_id || null,
          created_at: new Date().toISOString(),
        })
      }
    }

    if (validEvents.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid events', inserted: 0 }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Store in Supabase
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { error, count } = await supabase
      .from('telemetry_events')
      .insert(validEvents)

    if (error) {
      console.error('Database insert error:', error)
      return new Response(JSON.stringify({ error: 'Storage failed', inserted: 0 }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Success
    return new Response(JSON.stringify({ ok: true, inserted: count || validEvents.length }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Request error:', err)
    return new Response(JSON.stringify({ error: 'Internal error', inserted: 0 }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
