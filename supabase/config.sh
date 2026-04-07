#!/usr/bin/env bash
# Supabase project config for nanopm telemetry
# These are PUBLIC keys — safe to commit (like Firebase public config).
# RLS denies all access to the anon key. All reads and writes go through
# edge functions (which use SUPABASE_SERVICE_ROLE_KEY server-side).

NANOPM_SUPABASE_URL="https://kvjidbknhaxsnikimakv.supabase.co"
NANOPM_SUPABASE_ANON_KEY="sb_publishable_GlqSD3ixgftMoECE5YBjIQ_-t5WgA6_"

# TODO: Replace YOUR_ANON_KEY_HERE with your actual anon key from:
# Supabase Dashboard → Settings → API → Project API keys → anon public
