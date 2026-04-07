# Connector: Granola

Fetches meeting notes and transcripts from Granola.
Used by `/pm-standup` for recent meeting context and by `/pm-interview` to pull user interview transcripts automatically.

## Tier 1 (MCP)

**Detection:** `grep "mcp__claude_ai_Granola__" ~/.claude/CLAUDE.md 2>/dev/null || grep "Granola" ~/.claude/CLAUDE.md 2>/dev/null`

**Read tools:**
```
mcp__claude_ai_Granola__list_meetings          — list recent meetings with metadata
mcp__claude_ai_Granola__get_meetings           — get meetings with optional filters
mcp__claude_ai_Granola__get_meeting_transcript — full transcript for a specific meeting
mcp__claude_ai_Granola__query_granola_meetings — search meetings by keyword or topic
mcp__claude_ai_Granola__list_meeting_folders   — list folder structure (if organized)
```

**Fetching recent meetings (for /pm-standup):**
```
mcp__claude_ai_Granola__list_meetings(
  limit: 5
)
```
Extract: meeting title, date, duration, participants — gives context on what was discussed recently.

**Fetching a specific transcript (for /pm-interview):**
```
mcp__claude_ai_Granola__query_granola_meetings(
  query: "{topic or person name}"
)
→ get meeting_id from results
mcp__claude_ai_Granola__get_meeting_transcript(
  meeting_id: "{id}"
)
```

**What to extract for `/pm-standup`:**
- Meetings from the last 24-48h: title, participants, key decisions if available in notes
- Flag if a meeting has no notes yet (may need follow-up)

**What to extract for `/pm-interview`:**
- Full transcript text — feed directly into Phase 5 signal extraction
- Participant names — identifies the interviewee profile
- Meeting date — timestamps the interview session in FEEDBACK.md
- Any action items or follow-ups noted in Granola

**Heuristics:**
- Meeting title contains "user", "customer", "interview", "discovery", "research", "call" → likely a user interview → suggest using `/pm-interview` to extract signal
- Meeting title contains "standup", "sync", "weekly", "planning" → internal meeting → show in standup summary only
- Transcript length >3000 words → rich data source, worth full signal extraction

**Setup for users:**
Add the Granola MCP server to your Claude Code configuration.
Granola uses your local app session — no separate API key needed.

---

## Tier 2 (API)

Granola does not currently expose a public REST API.
Tier 1 (MCP) is the only programmatic access path.

---

## Tier 3 (Browser)

Not applicable — Granola is a desktop app, not a web app with scrapable URLs.

---

## Tier 4 (Manual fallback)

If Granola MCP is not available:

**For `/pm-standup`:** skip the Granola section silently — no question asked.

**For `/pm-interview`:** in Phase 5, ask the user to paste their raw notes manually:
> "Granola not connected. Paste your interview notes below — transcript, bullet points, anything."

This is the default Tier 4 behavior already in `/pm-interview` Phase 5.
