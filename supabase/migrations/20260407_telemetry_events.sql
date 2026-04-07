-- Telemetry events table
-- Stores skill usage data from nanopm installations

create table if not exists public.telemetry_events (
  id bigserial primary key,
  skill text not null,
  duration_s integer,
  outcome text not null check (outcome in ('success', 'error', 'abort', 'unknown')),
  session_id text not null,
  timestamp timestamptz not null,
  nanopm_version text,
  os text,
  arch text,
  sessions integer default 1,
  installation_id text,
  created_at timestamptz not null default now()
);

-- Index for analytics queries
create index if not exists telemetry_events_skill_idx on public.telemetry_events (skill);
create index if not exists telemetry_events_timestamp_idx on public.telemetry_events (timestamp);
create index if not exists telemetry_events_created_at_idx on public.telemetry_events (created_at);
create index if not exists telemetry_events_installation_id_idx on public.telemetry_events (installation_id) where installation_id is not null;

-- RLS: allow anonymous inserts (telemetry is public), no reads
alter table public.telemetry_events enable row level security;

create policy "Allow anonymous inserts"
  on public.telemetry_events
  for insert
  to anon
  with check (true);

-- No read policy — only service role can query (for your analytics dashboard)
