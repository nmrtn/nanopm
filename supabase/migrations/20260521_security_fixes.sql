-- Security fixes (v0.5.2)

-- 1. Drop permissive anon insert policy.
--    The edge function uses SUPABASE_SERVICE_ROLE_KEY which bypasses RLS entirely,
--    so no insert policy is needed for legitimate writes. Anon direct-REST inserts
--    were bypassing all edge function validation (skill allowlist, duration cap, etc.).
DROP POLICY IF EXISTS "Allow anonymous inserts" ON public.telemetry_events;

-- 2. Add skill check constraint — mirrors the edge function's VALID_SKILLS allowlist.
--    Any insert (including future direct ones) must use a known skill name.
--    Update this list when new skills are added.
ALTER TABLE public.telemetry_events
  ADD CONSTRAINT valid_skill CHECK (
    skill = ANY(ARRAY[
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
      'pm-interview',
      'pm-standup',
      'pm-weekly-update',
      'pm-data'
    ])
  );

-- 3. Add missing columns referenced by the edge function but absent from the original schema.
ALTER TABLE public.telemetry_events
  ADD COLUMN IF NOT EXISTS arch text,
  ADD COLUMN IF NOT EXISTS error_class text,
  ADD COLUMN IF NOT EXISTS error_message text,
  ADD COLUMN IF NOT EXISTS installation_id text;

-- 4. Fix orphaned index: installation_id_idx was created in the original migration
--    but installation_id column didn't exist yet. Re-create it now that the column exists.
DROP INDEX IF EXISTS telemetry_events_installation_id_idx;
CREATE INDEX IF NOT EXISTS telemetry_events_installation_id_idx
  ON public.telemetry_events (installation_id)
  WHERE installation_id IS NOT NULL;
