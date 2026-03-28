# Connector: Notion

Fetches product docs, roadmaps, and specs from Notion workspaces.

## Tier 1 (MCP)

**Detection:** `grep "mcp__notion__" CLAUDE.md`

**Tools to call:**
```
mcp__notion__search             — search for roadmap, spec, strategy pages
mcp__notion__get_page           — read a specific page by ID
mcp__notion__query_database     — query a database (e.g., feature backlog)
```

**What to extract:**
- Pages titled "Roadmap", "Product Strategy", "Q* Goals" → feeds /pm-objectives, /pm-strategy
- Feature backlog database → feeds /pm-roadmap
- User research or feedback pages → feeds /pm-audit

**Suggested search queries:**
```
mcp__notion__search("roadmap")
mcp__notion__search("product strategy")
mcp__notion__search("OKR")
mcp__notion__search("user research")
```

**Setup for users:**
Install Notion MCP server and add to CLAUDE.md:
```
# Notion MCP
Use mcp__notion__* tools for Notion access.
```

---

## Tier 2 (API)

**Detection:** `[ -n "$NOTION_API_KEY" ]`

**Endpoint:** `https://api.notion.com/v1/search`

**Request:**
```bash
curl -X POST https://api.notion.com/v1/search \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"query": "roadmap", "filter": {"property": "object", "value": "page"}}'
```

**Get page content:**
```bash
curl https://api.notion.com/v1/blocks/${PAGE_ID}/children \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"
```

**Setup for users:**
```bash
export NOTION_API_KEY="secret_..."
```
Create integration: notion.so/my-integrations → share relevant pages with integration

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

**URL discovery (first run):**
```bash
$B goto https://www.notion.so
$B snapshot
# Claude finds workspace name and URL from sidebar
# Stores: nanopm_config_set "notion_url" "https://www.notion.so/{workspace}"
```

**Subsequent runs:**
```bash
NOTION_URL=$(nanopm_config_get "notion_url")
$B goto "$NOTION_URL"
$B snapshot  # read sidebar page list
# Navigate to relevant pages (roadmap, strategy, etc.)
```

**Cookie auth:** Sign in to Notion in your browser. nanopm reuses the existing session via the browse binary.

**Limitations:** Notion's browser UI is heavy. Snapshot may be slow. Search is
more reliable than navigation for finding specific pages.

---

## Tier 4 (Manual fallback)

**CONTEXT.md questions this connector answers:**
- Q5: "What are your top 1-2 goals for this quarter?"
- Q7: "What have you explicitly decided NOT to build, and why?"
