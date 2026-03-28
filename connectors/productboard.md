# Connector: Productboard

Fetches feature requests, user feedback notes, and insight trends from Productboard.

## Tier 1 (MCP)

No official Productboard MCP server exists as of v0.2.0.
Check https://developer.productboard.com for updates.

---

## Tier 2 (API)

**Detection:** `[ -n "$PRODUCTBOARD_TOKEN" ]`

**Base URL:** `https://api.productboard.com`

**Useful endpoints:**
```bash
# List features (with request counts and user segments)
curl -H "Authorization: Bearer $PRODUCTBOARD_TOKEN" \
     -H "X-Version: 1" \
  "https://api.productboard.com/features?status=new,under-consideration"

# List notes (raw user feedback / verbatim quotes)
curl -H "Authorization: Bearer $PRODUCTBOARD_TOKEN" \
     -H "X-Version: 1" \
  "https://api.productboard.com/notes?limit=100"

# List products (to scope by product area)
curl -H "Authorization: Bearer $PRODUCTBOARD_TOKEN" \
     -H "X-Version: 1" \
  "https://api.productboard.com/products"

# Feature detail (includes linked notes + vote counts)
curl -H "Authorization: Bearer $PRODUCTBOARD_TOKEN" \
     -H "X-Version: 1" \
  "https://api.productboard.com/features/{feature_id}"
```

**What to extract:**
- Features sorted by vote count / request frequency → top pain points
- Notes with sentiment tags → verbatim user quotes for /pm-user-feedback themes
- Features in "under consideration" → what's already on the team's radar
- Features with high votes but no roadmap item → unaddressed signals

**Setup for users:**
```bash
export PRODUCTBOARD_TOKEN="..."
```
Get token: Productboard → Profile → API tokens → Create token (needs "Features" + "Notes" read scope)

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

**URL discovery (first run):**
```bash
$B goto https://app.productboard.com
$B snapshot
# Claude finds workspace URL from the app shell
# Stores: nanopm_config_set "productboard_url" "https://app.productboard.com/{workspace}"
```

**Subsequent runs:**
```bash
PRODUCTBOARD_URL=$(nanopm_config_get "productboard_url")
$B goto "${PRODUCTBOARD_URL}/feature-board"
$B snapshot  # read feature list with vote counts
$B goto "${PRODUCTBOARD_URL}/insights"
$B snapshot  # read user notes / insights
```

**Cookie auth:** Sign in to Productboard in your browser. nanopm reuses the existing session via the browse binary.

**What to parse from snapshot:**
- Feature names with vote counts visible on the feature board
- Note titles and snippets on the insights page

---

## Tier 4 (Manual fallback)

**FEEDBACK.md questions this connector answers:**
- Top requested features (name + rough frequency)
- Verbatim user quotes about pain points
- Features users have specifically asked for by name

If no tier is available, ask the user to paste their top 3-5 feature requests from
Productboard with rough vote counts, or describe the dominant themes.
