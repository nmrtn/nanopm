#!/usr/bin/env bash
# Supabase project config for nanopm telemetry
# These are PUBLIC keys — safe to commit (like Firebase public config).
# All writes go through the edge function using SUPABASE_SERVICE_ROLE_KEY,
# which bypasses RLS entirely. The anon key is used only for SDK initialization
# in nanopm-telemetry-sync. The anon role has no insert policy on telemetry_events.

NANOPM_SUPABASE_URL="https://kvjidbknhaxsnikimakv.supabase.co"
NANOPM_SUPABASE_ANON_KEY="sb_publishable_GlqSD3ixgftMoECE5YBjIQ_-t5WgA6_"

# TODO: Replace YOUR_ANON_KEY_HERE with your actual anon key from:
# Supabase Dashboard → Settings → API → Project API keys → anon public
