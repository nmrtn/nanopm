-- Raw source archive sync: feedback, interviews, competitor intel, events log.
-- One row per file under .nanopm/raw/, upserted on every sync.

create table if not exists nanopm_raw_sources (
  id            uuid primary key default gen_random_uuid(),
  project_slug  text not null,
  type          text not null,      -- first path component: feedback | interviews | competitors | …
  raw_id        text,               -- 12-hex sha256 content id; null for non-content-addressed files
  path          text not null,      -- relative to .nanopm/raw/, e.g. 'feedback/2ff04b9bcb81.md'
  content       text,               -- full UTF-8 file content
  content_hash  text,               -- sha256(content) for sync-state tracking
  file_size     int,
  last_updated  timestamptz default now(),
  synced_at     timestamptz default now(),
  unique (project_slug, path)
);

alter table nanopm_raw_sources enable row level security;

create policy "allow all" on nanopm_raw_sources
  for all using (true) with check (true);
