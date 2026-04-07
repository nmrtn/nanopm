# Connector: Google Calendar

Fetches today's events and upcoming meetings from Google Calendar.
Used by `/pm-standup` to surface the day's schedule and flag meetings that may need prep.

## Tier 1 (MCP)

**Detection:** `grep "mcp__claude_ai_Google_Calendar__" ~/.claude/CLAUDE.md 2>/dev/null || grep "Google_Calendar" ~/.claude/CLAUDE.md 2>/dev/null`

**Read tools:**
```
mcp__claude_ai_Google_Calendar__gcal_list_events   — list events for a date range
mcp__claude_ai_Google_Calendar__gcal_list_calendars — list available calendars
mcp__claude_ai_Google_Calendar__gcal_get_event      — get full event details
```

**Fetching today's events:**
```
mcp__claude_ai_Google_Calendar__gcal_list_events(
  calendar_id: "primary",
  time_min:    "{today}T00:00:00Z",
  time_max:    "{today}T23:59:59Z",
  max_results: 20
)
```

**What to extract:**
- Event title, start time, end time, duration
- Attendees (if present) — signals collaborative vs solo meetings
- Meeting description / agenda (if present)
- Location or video link (signals external vs internal)

**Heuristics for `/pm-standup`:**
- Flag meetings >1h as "heavy" — likely needs prep
- Flag meetings with external attendees — may need context from Granola or notes
- Cross-reference event title with recent git commits: if event topic matches a feature area with no recent commits, flag as "no recent progress on this"

**Setup for users:**
Add the Google Calendar MCP server to your Claude Code configuration.
Once connected, events are fetched automatically — no API key needed.

---

## Tier 2 (API)

**Detection:** `[ -n "$GOOGLE_CALENDAR_API_KEY" ]` or OAuth credentials in environment.

Not recommended for this use case — MCP is simpler and more reliable for personal calendars.
If needed: use Google Calendar API v3 `events.list` endpoint with OAuth 2.0.

---

## Tier 3 (Browser)

Not applicable — Google Calendar browser scraping is fragile and unnecessary when MCP is available.

---

## Tier 4 (Manual fallback)

If no tier is available, `/pm-standup` skips the meetings section and notes:
```
MEETINGS  (Google Calendar not connected — add MCP to see today's schedule)
```

No question is asked — standup never blocks on missing calendar data.
