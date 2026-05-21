# Connector: Slack

Fetches recent messages, decisions, and customer mentions from key channels in Slack.
Used by `/pm-standup` (last 24h) and `/pm-weekly-update` (last 7 days) to surface context the PM may have missed.

## Tier 1 (MCP)

**Detection:** `grep "mcp__slack__" ~/.claude/CLAUDE.md 2>/dev/null`

**Tools to call:**
```
mcp__slack__list_channels        — enumerate channels; find #product, #engineering, #customer-feedback
mcp__slack__get_channel_history  — fetch recent messages for a channel by ID
mcp__slack__search_messages      — keyword search across all channels
```

**Suggested fetch pattern:**
```
# Resolve channel IDs once, store with nanopm_config_set
mcp__slack__list_channels()  →  find id for #product, #engineering, #customer-feedback

# /pm-standup: last 24h
mcp__slack__get_channel_history(channel: "{product_channel_id}", limit: 50, oldest: "{24h_ago_unix}")
mcp__slack__get_channel_history(channel: "{feedback_channel_id}", limit: 50, oldest: "{24h_ago_unix}")

# /pm-weekly-update: last 7 days
mcp__slack__get_channel_history(channel: "{product_channel_id}", limit: 200, oldest: "{7d_ago_unix}")
mcp__slack__search_messages(query: "decided OR decision OR shipping in:#product after:7daysago")
```

**What to extract:**
- Messages containing "decided", "agreed", "shipping", "blocking", or "incident" → decisions and blockers
- Messages mentioning customer names or "user said" → customer signal
- Thread replies with high reaction counts → high-signal discussions worth including in the standup or update

**Setup for users:**
Add to your agent's MCP configuration:
```
# Slack MCP
Use mcp__slack__* tools for Slack access.
```
Install Slack MCP server and connect your workspace. The skill caches resolved channel IDs in `~/.nanopm/config` after the first run.

---

## Tier 2 (API)

**Detection:** `[ -n "$SLACK_API_TOKEN" ]`

**Base URL:** `https://slack.com/api`

**Authentication:** `Authorization: Bearer $SLACK_API_TOKEN`

**Fetch channel history (last 24h):**
```bash
OLDEST=$(date -v-1d +%s)   # macOS; use date -d '1 day ago' +%s on Linux
curl -s -X POST "https://slack.com/api/conversations.history" \
  -H "Authorization: Bearer $SLACK_API_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "channel=${PRODUCT_CHANNEL_ID}" \
  -d "limit=50" \
  -d "oldest=${OLDEST}"
```

**Search messages across channels:**
```bash
curl -s "https://slack.com/api/search.messages" \
  -H "Authorization: Bearer $SLACK_API_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "query=in:#product after:yesterday" \
  -d "count=20" \
  -d "sort=score"
```

**Resolve channel ID by name (run once):**
```bash
curl -s "https://slack.com/api/conversations.list" \
  -H "Authorization: Bearer $SLACK_API_TOKEN" \
  -d "limit=200" \
  | python3 -c "import sys,json; [print(c['id'],c['name']) for c in json.load(sys.stdin)['channels']]"
```

**What to extract:**
- `.messages[].text` — message body; filter for keywords (decided, shipped, blocked, customer)
- `.messages[].reactions` — high-reaction messages signal importance
- `.matches[].permalink` — deep-link to the original message for the update email

**Required env vars:** `SLACK_API_TOKEN`
Get it: api.slack.com/apps → [your app] → OAuth & Permissions → Bot User OAuth Token

**Required OAuth scopes:** `channels:history`, `search:read`, `channels:read`
Without `search:read`, fall back to `conversations.history` on known channel IDs only.

---

## Tier 3 (Browser)

Not practical. Slack's web app is auth-gated, heavily dynamic, and fragile under snapshot-based parsing. Tier 1 (MCP) or Tier 2 (API) are strongly preferred.

---

## Tier 4 (Manual fallback)

**For `/pm-standup`:** Skip Slack silently and include this note in the output:
> "(Slack not connected — check your channels manually)"

**For `/pm-weekly-update`:** Ask the user:
> "Paste any key decisions or discussions from Slack this week (optional). Bullet points are fine — channel context, who said what, or just the decision itself."

If the user skips, the skill proceeds without it and notes that Slack context was not available.
