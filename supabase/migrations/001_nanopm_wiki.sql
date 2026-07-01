-- nanopm Phase 5: cloud wiki sync
-- Apply via: supabase db push  OR  paste into Supabase SQL editor
-- Requires: Supabase project with pgvector extension available

create extension if not exists vector;

-- One row per project (identified by git repo slug)
create table if not exists nanopm_projects (
  slug       text primary key,
  name       text,
  created_at timestamptz default now()
);

-- One row per wiki page, upserted on every nanopm-ingest-agent apply
create table if not exists nanopm_wiki_pages (
  id           uuid primary key default gen_random_uuid(),
  project_slug text not null,
  path         text not null,   -- e.g. "entities/opportunities/cold-start.md"
  slug         text,
  type         text,
  provenance   text,
  priority     text,
  title        text,
  theme        text,
  summary      text,
  body         text,
  content      text not null,   -- full raw markdown (source of truth)
  last_updated text,
  synced_at    timestamptz default now(),
  unique (project_slug, path)
);

-- Mirrors wiki/log.md — queryable, multi-user
create table if not exists nanopm_wiki_log (
  id           uuid primary key default gen_random_uuid(),
  project_slug text not null,
  op           text,
  title        text,
  day          text,
  created_at   timestamptz default now()
);

-- RLS: enabled but permissive for now (anon key, project scoping enforced by app).
-- Tighten with JWT claims in Phase 5.5.
alter table nanopm_wiki_pages enable row level security;
alter table nanopm_wiki_log   enable row level security;
alter table nanopm_projects   enable row level security;

create policy "allow all" on nanopm_wiki_pages for all using (true) with check (true);
create policy "allow all" on nanopm_wiki_log   for all using (true) with check (true);
create policy "allow all" on nanopm_projects   for all using (true) with check (true);

-- Postgres FTS index for search (complements SQLite FTS5 on local)
create index if not exists wiki_pages_fts_idx
  on nanopm_wiki_pages
  using gin (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(theme,'') || ' ' || coalesce(summary,'') || ' ' || coalesce(body,'')));
