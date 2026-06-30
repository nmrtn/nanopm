# Connector: Intercom

Fetches recent support conversations, contact data, and conversation tags from Intercom.
Used by `/pm-add-feedback` and `/pm-challenge-me` to surface recurring support themes and user pain points.

## Tier 1 (MCP)

No official Intercom MCP server exists.
Use Tier 2 (API) instead.

---

## Tier 2 (API)

**Detection:** `[ -n "$INTERCOM_API_TOKEN" ]`

**Base URL:** `https://api.intercom.io`

**Authentication:** `Authorization: Bearer $INTERCOM_API_TOKEN`

**List recent conversations:**
```bash
curl -s "https://api.intercom.io/conversations?sort=created_at&order=desc&per_page=25" \
  -H "Authorization: Bearer $INTERCOM_API_TOKEN" \
  -H "Accept: application/json"
```

**Search conversations by tag:**
```bash
curl -s -X POST "https://api.intercom.io/conversations/search" \
  -H "Authorization: Bearer $INTERCOM_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "field": "tag.name",
      "operator": "=",
      "value": "billing"
    }
  }'
```

**List contacts (recent users):**
```bash
curl -s "https://api.intercom.io/contacts?per_page=10" \
  -H "Authorization: Bearer $INTERCOM_API_TOKEN" \
  -H "Accept: application/json"
```

**What to extract:**
- Conversation subjects and tag names → reveals support themes and recurring complaints
- Latest message excerpts (`.conversation_parts.conversation_parts[0].body`) → verbatim user language
- Tag frequency across conversations → surface the highest-volume pain point areas for `/pm-challenge-me`
- Contact metadata (plan, company) → segments complaints by user type for `/pm-add-feedback`

**Required env vars:** `INTERCOM_API_TOKEN`
Get it: Intercom → Settings → Developers → Your Apps → [app] → Access Token

**Note:** The v2 API requires `Authorization: Bearer`. Older integrations may use `Authorization: token` — check your token type in the Intercom developer console.

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

**URL:** `https://app.intercom.com/a/inbox`

```bash
$B goto https://app.intercom.com/a/inbox
$B snapshot
# Read conversation list: subject lines, assignees, and tag labels visible in the inbox
# Navigate to Tags view for a frequency overview:
$B goto https://app.intercom.com/a/apps/_/reports/conversations
$B snapshot
```

**Cookie auth:** Sign in to Intercom in your browser. nanopm reuses the existing session via the browse binary.

**What to parse from snapshot:**
- Conversation subject lines and tag chips visible in the inbox list view
- Top conversation counts per tag on the reports page

**Limitations:** Intercom's inbox is paginated and dynamically rendered. Snapshot captures only what is visible on screen. For bulk theme extraction, Tier 2 (API) is significantly more reliable.

---

## Tier 4 (Manual fallback)

**For `/pm-challenge-me`:** Ask the user:
> "Paste your top 3–5 recurring support themes from Intercom (or wherever you track support). Ticket categories, tag names, or short descriptions are all fine."

**For `/pm-add-feedback`:** Skip silently — support context is supplementary to the feedback being captured. The skill proceeds without it.
