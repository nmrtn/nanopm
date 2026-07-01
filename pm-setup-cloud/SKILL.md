---
name: pm-setup-cloud
version: 0.1.0
description: "Configure Supabase cloud sync for nanopm. One-time setup per machine: enter your project URL + anon key, run the migration, push your local wiki to the cloud. After setup, wiki pages sync automatically on every skill run."
allowed-tools: Bash, Read, AskUserQuestion
---

<!-- portability-v2 -->
> **Multi-host portability rules.** When invoking `AskUserQuestion`:
> 1. The `header` field MUST be a short noun phrase (≤ 12 characters). Mistral Vibe
>    rejects longer headers with `string_too_long`. Pick from: `Start`, `Target`,
>    `Scope`, `Audience`, `Methodology`, `Feature`, `Question`.
> 2. The `options` list MUST have at least 2 items. Vibe rejects empty/single-option
>    calls. For free-text input, always provide ≥ 2 framing options (e.g. `Yes, here's the input` /
>    `Skip`) — never call `ask_user_question` with `options: []`.


## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
SUPABASE_URL=$(nanopm_config_get supabase_url 2>/dev/null || echo "")
SUPABASE_KEY=$(nanopm_config_get supabase_key 2>/dev/null || echo "")
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_KEY" ]; then
  echo "SUPABASE_STATUS: already configured ($SUPABASE_URL)"
else
  echo "SUPABASE_STATUS: not configured"
fi
```


## Phase 1: Check existing config

Read the output above.

- If `SUPABASE_STATUS: already configured` → ask the user whether to reconfigure or run a re-sync, then jump to Phase 4 if they want re-sync.
- If `SUPABASE_STATUS: not configured` → proceed to Phase 2.


## Phase 2: Get the Supabase project details

Ask the user if they already have a Supabase project for nanopm:
- **No** → tell them: "Create a free project at https://supabase.com. In your project, go to Settings → API to find your URL and anon key. Come back when you have them ready."
- **Yes** → proceed.

**Never ask the user to paste their URL or key into the chat.** Credentials must not appear in the conversation. Instead, tell the user to create or edit `~/.nanopm/.env` in their own terminal or editor. Show them the exact format:

```
# ~/.nanopm/.env — never commit this file
NANOPM_SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
NANOPM_SUPABASE_KEY=YOUR-ANON-KEY
```

They can create it with:
```
! cat > ~/.nanopm/.env << 'EOF'
NANOPM_SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
NANOPM_SUPABASE_KEY=YOUR-ANON-KEY
EOF
```

(They fill in the real values themselves — never paste them into chat.)

Ask them to confirm when done.


## Phase 3: Verify config and run migration

Once the user confirms, verify the credentials are present (without printing them):

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null
nanopm_supabase_configured && echo "CREDENTIALS: present" || echo "CREDENTIALS: missing — please check ~/.nanopm/.env"
```

Run the database migration. Try the Supabase MCP first (preferred — no CLI needed), then fall back to instructions:

```bash
# Check if supabase CLI is available
command -v supabase >/dev/null 2>&1 && echo "SUPABASE_CLI: available" || echo "SUPABASE_CLI: not found"
# Check if migration file exists
[ -f "supabase/migrations/001_nanopm_wiki.sql" ] && echo "MIGRATION_FILE: present" || echo "MIGRATION_FILE: not found"
```

**If Supabase MCP is available** (`mcp__supabase__apply_migration`): read `supabase/migrations/001_nanopm_wiki.sql` and apply it via the MCP tool.

**If Supabase CLI is available**: run `supabase db push` (requires `supabase login` first).

**Otherwise**: tell the user to copy the contents of `supabase/migrations/001_nanopm_wiki.sql` into their Supabase SQL editor at `https://supabase.com/dashboard/project/<ref>/sql` and run it.

Wait for confirmation that the migration ran before continuing.


## Phase 4: Initial sync

Push all local wiki pages to Supabase:

```bash
~/.nanopm/bin/nanopm-ingest-agent --project . sync
```

If it prints `sync: pushed N page(s)` → success.

If it errors → show the error to the user and suggest checking the URL/key.


## Phase 5: Confirm and explain next steps

Print a summary:

```
CLOUD_CONFIGURED ✓
  URL:     <url>
  Pages:   <N> pushed
  Auto-sync: push happens after every wiki write; pull happens at the start
             of each skill run (throttled to once per 10 minutes).

To share with a teammate:
  1. Send them the Supabase URL + anon key out-of-band (Slack DM, 1Password, etc.)
  2. They create ~/.nanopm/.env with the same values (never in chat)
  3. They run /pm-setup-cloud — it verifies credentials and does the initial pull
  4. From then on, sync is automatic
```
