# Connector: Dovetail

Fetches user research insights, feedback themes, and interview tags from Dovetail.

## Tier 1 (MCP)

No official Dovetail MCP server exists as of v0.1.0.
Check https://dovetail.com/docs for updates.

---

## Tier 2 (API)

**Detection:** `[ -n "$DOVETAIL_API_KEY" ]`

**Base URL:** `https://dovetail.com/api/v1`

**Useful endpoints:**
```bash
# List projects
GET /projects
Authorization: Bearer $DOVETAIL_API_KEY

# List insights for a project
GET /projects/{project_id}/insights

# List highlights (tagged quotes from interviews)
GET /projects/{project_id}/highlights

# List tags (themes)
GET /projects/{project_id}/tags
```

**What to extract:**
- Top insight titles and their highlight count → feeds /pm-audit (feedback surprises)
- Most-used tags → reveals user pain point themes
- Recent highlights → verbatim user quotes for /pm-prd user stories

**Setup for users:**
```bash
export DOVETAIL_API_KEY="..."
```
Get API key: Dovetail → Settings → API → Create token

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

**URL discovery (first run):**
```bash
$B goto https://dovetail.com
$B snapshot
# Claude finds first project URL from dashboard
# Stores: nanopm_config_set "dovetail_url" "https://dovetail.com/{workspace}"
```

**Subsequent runs:**
```bash
DOVETAIL_URL=$(nanopm_config_get "dovetail_url")
$B goto "${DOVETAIL_URL}/insights"
$B snapshot  # read insight list
```

**Cookie auth:** Sign in to Dovetail in your browser. nanopm reuses the existing session via the browse binary.

**What to parse from snapshot:**
- Insight titles and highlight counts visible on the insights page
- Tag names visible on the tags/themes page

---

## Tier 4 (Manual fallback)

**CONTEXT.md questions this connector answers:**
- Q6: "What feedback have you received that surprised you?"
- Q8: "Who are your 3 most important users/customers right now?"

If no tier is available, ask the user to paste 2-3 key feedback themes or
surprising user quotes directly into CONTEXT.md.
