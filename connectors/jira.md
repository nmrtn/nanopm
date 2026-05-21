# Connector: Jira

Fetches active sprint tickets, recently closed issues, and blockers from Jira (Atlassian).
Used by `/pm-standup` for daily status context and `/pm-retro` to surface completed vs planned work.

## Tier 1 (MCP)

Atlassian does not yet have a stable official MCP server, but a remote MCP is in preview.

**Detection:** `grep "mcp__atlassian__" ~/.claude/CLAUDE.md 2>/dev/null`

If available, the expected tools would be:
```
mcp__atlassian__jira_get_issue         — fetch a single issue by key
mcp__atlassian__jira_search            — JQL search (returns list of issues)
mcp__atlassian__jira_get_sprint_issues — all issues in the active sprint
```

**Common queries for `/pm-standup` (if MCP is available):**
```
mcp__atlassian__jira_search(
  jql: "sprint in openSprints() AND assignee = currentUser()",
  maxResults: 20
)

mcp__atlassian__jira_search(
  jql: "status changed to Done AFTER -7d ORDER BY updated DESC",
  maxResults: 10
)
```

**Setup for users:**
Add the Atlassian Remote MCP server to your agent's MCP configuration once it reaches general availability.
See: https://www.atlassian.com/blog/announcements/remote-mcp-server

---

## Tier 2 (API)

**Detection:** `[ -n "$JIRA_DOMAIN" ] && [ -n "$JIRA_API_TOKEN" ]`

**Base URL:** `https://$JIRA_DOMAIN.atlassian.net/rest/api/3`

**Authentication:** HTTP Basic Auth — email + API token, base64-encoded.

```bash
JIRA_AUTH=$(echo -n "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" | base64)
```

**Active sprint — issues assigned to current user:**
```bash
curl -s "https://$JIRA_DOMAIN.atlassian.net/rest/api/3/search" \
  -H "Authorization: Basic $JIRA_AUTH" \
  -H "Content-Type: application/json" \
  -G \
  --data-urlencode 'jql=sprint in openSprints() AND assignee = currentUser()' \
  -d "maxResults=20" \
  -d "fields=summary,status,priority,created,updated,assignee"
```

**Recently closed — last 7 days:**
```bash
curl -s "https://$JIRA_DOMAIN.atlassian.net/rest/api/3/search" \
  -H "Authorization: Basic $JIRA_AUTH" \
  -H "Content-Type: application/json" \
  -G \
  --data-urlencode 'jql=status changed to Done AFTER -7d ORDER BY updated DESC' \
  -d "maxResults=10" \
  -d "fields=summary,status,resolutiondate,assignee"
```

**Active blockers across the team:**
```bash
curl -s "https://$JIRA_DOMAIN.atlassian.net/rest/api/3/search" \
  -H "Authorization: Basic $JIRA_AUTH" \
  -H "Content-Type: application/json" \
  -G \
  --data-urlencode 'jql=priority = Blocker AND status != Done ORDER BY created ASC' \
  -d "maxResults=10" \
  -d "fields=summary,status,assignee,created,updated"
```

**What to extract:**
- Active sprint issues → title, status, assignee, days since last update
- Recently closed → title, resolution date (feeds `/pm-retro` "what shipped" list)
- Blockers → title, owner, age in days

**Heuristics for `/pm-standup`:**
- If an issue has been `In Progress` for more than 5 days without an update, flag it as a potential blocker: compute `(today - updated)` in days from the `updated` field.
- If the active sprint has more than 30% of issues still `To Do` with fewer than 3 days left, surface a sprint health warning.
- Prioritize surfacing `Blocker` and `Critical` priority issues at the top of the standup output regardless of assignee.

**Required env vars:**
- `JIRA_DOMAIN` — subdomain only, e.g. `mycompany` for `mycompany.atlassian.net`
- `JIRA_USER_EMAIL` — the email address associated with the API token
- `JIRA_API_TOKEN` — generate at https://id.atlassian.com/manage-profile/security/api-tokens

---

## Tier 3 (Browser)

**Detection:** `$B` available

**URL:** `https://$JIRA_DOMAIN.atlassian.net`

Navigate to the active sprint board and take a screenshot to read visible ticket titles and statuses.

```bash
$B goto "https://${JIRA_DOMAIN}.atlassian.net"
$B screenshot
# Follow navigation to the active sprint board from the sidebar
```

Cookie auth: sign in to Jira in your browser. The browse binary reuses the existing session.

Useful for confirming sprint state at a glance, but unreliable for structured extraction of ticket fields. Prefer Tier 2 when credentials are available.

---

## Tier 4 (Manual fallback)

**For `/pm-standup`:**
> "Any blockers or tickets to highlight today? (or skip)"

If the user skips, generate the standup from git log and CONTEXT.md alone, and note that Jira is not connected.

**For `/pm-retro`:**
Skip silently and note in the retro output: "Jira not connected — completed issues sourced from git log only."
Suggest the user add `JIRA_API_TOKEN` to their environment to enable full ticket comparison.
