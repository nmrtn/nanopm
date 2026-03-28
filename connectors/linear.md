# Connector: Linear

Fetches issues, cycles, and roadmap initiatives from Linear.
Also supports **write operations** for `/pm-breakdown` ticket creation.

## Tier 1 (MCP)

**Detection:** `grep "mcp__linear__" CLAUDE.md`

**Read tools:**
```
mcp__linear__list_issues        — recent issues (filter: last 30 days or current cycle)
mcp__linear__list_projects      — active projects / initiatives
mcp__linear__get_viewer         — current user (team context)
```

**Write tools (used by /pm-breakdown):**
```
mcp__linear__create_issue       — create a new issue
mcp__linear__list_teams         — list teams (needed to resolve teamId before creating)
```

**Creating an issue (MCP):**
```
mcp__linear__list_teams()                    → pick teamId, store with nanopm_config_set
mcp__linear__create_issue(
  title:       "Implement X",
  description: "Engineering task description.\n\nAcceptance: ...\nTies to: PRD §N",
  teamId:      "{stored team id}",
  estimate:    3                             # story points — omit if not Scrum
)
```

**What to extract:**
- Issues completed in the last 30 days → feeds CONTEXT.md Q4 (what shipped)
- Issues in current cycle/sprint → feeds CONTEXT.md Q5 (current goals)
- Backlog items by priority → feeds /pm-roadmap

**Setup for users:**
Add to your project `CLAUDE.md` or global `~/.claude/CLAUDE.md`:
```
# Linear MCP
Use mcp__linear__* tools for Linear access.
```
Install Linear MCP server: https://linear.app/docs/mcp

---

## Tier 2 (API)

**Detection:** `[ -n "$LINEAR_API_KEY" ]`

**Endpoint:** `https://api.linear.app/graphql`

**Read — recent issues:**
```graphql
query {
  issues(filter: { completedAt: { gt: "-P30D" } }, first: 50) {
    nodes { id title state { name } completedAt }
  }
}
```

**Read — list teams (needed before first write):**
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ teams { nodes { id name } } }"}'
```

**Write — create issue (used by /pm-breakdown):**
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation CreateIssue($input: IssueCreateInput!) { issueCreate(input: $input) { issue { id identifier url } } }",
    "variables": {
      "input": {
        "title":       "Implement X",
        "description": "Engineering task.\n\nAcceptance: ...\nTies to: PRD §N",
        "teamId":      "{stored linear_team_id}"
      }
    }
  }'
```

Extract from response: `.data.issueCreate.issue.url` for the created ticket URL.

**Note on API key scope:** Personal API keys have full read/write access. If issues are being created but not appearing, check that the key belongs to a member of the target team.

**Headers:** `Authorization: $LINEAR_API_KEY`

**Setup for users:**
```bash
export LINEAR_API_KEY="lin_api_..."  # in .env or shell profile
```
Get API key: Linear Settings → API → Personal API keys

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

**URL discovery (first run):**
```bash
# Navigate to root, find workspace URL
$B goto https://linear.app
$B snapshot
# Claude reads snapshot, finds "Go to workspace" or first team link
# Stores: nanopm_config_set "linear_url" "https://linear.app/{team}"
```

**Subsequent runs:**
```bash
LINEAR_URL=$(nanopm_config_get "linear_url")
$B goto "${LINEAR_URL}/issues?orderBy=completedAt"
$B snapshot  # Claude reads issue list from ARIA tree
```

**Cookie auth:** Sign in to Linear in your browser. nanopm reuses the existing session via the browse binary.

**What to parse from snapshot:**
- Issue titles and status labels visible in the list view
- Cycle/sprint name shown in sidebar

**Limitations:** Browser tier reads whatever is visible on screen. Pagination may
be needed for large issue lists — navigate to next page and snapshot again.

---

## Tier 4 (Manual fallback)

**CONTEXT.md questions this connector answers:**
- Q4: "What did you ship in the last 30 days?"
- Q5: "What are your top 1-2 goals for this quarter?"

If no tier is available, the skill asks the user to fill in those answers manually.
