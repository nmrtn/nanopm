# Supabase Telemetry Setup

This directory contains the Supabase edge function and database migration for nanopm's global telemetry system.

## Quick Start (Already Have a Supabase Project)

If you've already created a Supabase project in the cloud dashboard:

1. **Install Supabase CLI:**
   ```bash
   brew install supabase/tap/supabase
   ```

2. **Login:**
   ```bash
   supabase login
   ```

3. **Link your project:**
   ```bash
   cd /Users/nmrtn/Code/nanopm
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   
   Find your project ref in the Supabase dashboard URL:
   `https://supabase.com/dashboard/project/YOUR_PROJECT_REF`

4. **Run the migration:**
   ```bash
   supabase db push
   ```

5. **Deploy the edge function:**
   ```bash
   supabase functions deploy nanopm-telemetry --use-api
   ```
   
   (The `--use-api` flag deploys without Docker)

6. **Configure the endpoint:**
   
   Edit `supabase/config.sh` and replace `YOUR_ANON_KEY_HERE` with your actual anon key:
   ```bash
   NANOPM_SUPABASE_ANON_KEY="eyJhbGc...your_actual_key"
   ```
   
   Get your anon key from: **Supabase Dashboard → Settings → API → Project API keys → anon public**
   
   **Note:** The anon key is SAFE to commit to the repo. RLS policies prevent direct database access — all writes go through the edge function which validates and sanitizes data.

7. **Test it:**
   ```bash
   curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/nanopm-telemetry \
     -H "Content-Type: application/json" \
     -H "apikey: YOUR_ANON_KEY" \
     -d '[{"skill":"pm-audit","duration_s":42,"outcome":"success","session":"test-123","ts":"2026-04-07T09:00:00Z"}]'
   ```
   
   Should return: `{"ok":true,"inserted":1}`

---

## How It Works (Anonymous Global Analytics)

**The anon key is public and safe:**
- Supabase anon keys are designed to be public (like Firebase API keys)
- RLS policies prevent direct database access
- All writes go through the edge function, which validates and sanitizes data
- Users can only INSERT telemetry events, never read or modify existing data

**For all users (when telemetry is enabled):**
- Telemetry writes to local `~/.nanopm/analytics/skill-usage.jsonl`
- `nanopm-telemetry-sync` reads `supabase/config.sh` (distributed with nanopm)
- Batches events and syncs to your Supabase project in the background
- Rate-limited (5min), non-blocking, silently fails if offline

**For you (maintainer):**
- You see aggregate anonymous data from all opted-in installations
- Query via Supabase Dashboard → Table Editor → `telemetry_events`
- No PII collected — only skill usage patterns

**Privacy tiers:**
- **off** — no remote sync (local analytics still work)
- **anonymous** — skill usage only, no installation tracking
- **community** — includes installation_id for unique user counts

---

## What gets collected

- Skill name (e.g., `pm-audit`, `pm-strategy`)
- Duration in seconds
- Outcome (`success`, `error`, `abort`)
- Anonymous session ID (timestamp + random, no user identification)
- Timestamp (UTC)

**No personal data, no code, no project names, no IP addresses.**

## Setup (one-time)

### 1. Create Supabase project

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login
supabase login

# Create a new project (or use existing)
# Note your project ref (e.g., abcdefghijklmnop)
```

### 2. Link this repo to your project

```bash
cd /path/to/nanopm
supabase link --project-ref YOUR_PROJECT_REF
```

### 3. Run the migration

```bash
supabase db push
```

This creates the `telemetry_events` table with RLS policies.

### 4. Deploy the edge function

```bash
supabase functions deploy nanopm-telemetry
```

### 5. Get your function URL

```bash
supabase functions list
```

Copy the URL (format: `https://YOUR_PROJECT.supabase.co/functions/v1/nanopm-telemetry`)

### 6. Update the telemetry helper

Edit `lib/nanopm-telemetry.sh` and replace:

```bash
_NANOPM_TELEMETRY_URL="https://YOUR_PROJECT.supabase.co/functions/v1/nanopm-telemetry"
```

With your actual function URL.

### 7. Test it

```bash
# Send a test event
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/nanopm-telemetry \
  -H "Content-Type: application/json" \
  -d '{"skill":"pm-audit","duration_s":42,"outcome":"success","session":"test-123","ts":"2026-04-07T09:00:00Z"}'

# Should return: {"ok":true}
```

### 8. Query your data

```sql
-- Total events
select count(*) from telemetry_events;

-- Per-skill breakdown
select skill, count(*) as runs
from telemetry_events
group by skill
order by runs desc;

-- Average duration per skill
select skill, avg(duration_s) as avg_duration_s
from telemetry_events
group by skill
order by avg_duration_s desc;

-- Success rate
select 
  skill,
  count(*) filter (where outcome = 'success') * 100.0 / count(*) as success_rate
from telemetry_events
group by skill;
```

## Privacy

- Telemetry is **opt-in by default** during setup
- Users can disable it anytime: `nanopm_config_set telemetry_disabled 1`
- Local analytics (`~/.nanopm/analytics/skill-usage.jsonl`) always work, even with remote telemetry disabled
- No PII is collected — session IDs are ephemeral and non-identifying

## Cost

Supabase free tier includes:
- 500MB database (telemetry events are ~100 bytes each = ~5M events)
- 2M edge function invocations/month

For a small open-source project, this should be free indefinitely.
