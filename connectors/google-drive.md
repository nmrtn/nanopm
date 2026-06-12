# Connector: Google Drive

Fetches PRDs, research docs, strategy decks, and meeting notes stored in Google Drive.
Used by `/pm-challenge-me` and `/pm-prd` to pull existing product context — prior specs, customer research, OKR docs — before generating new output.

## Tier 1 (MCP)

**Detection:** `grep "mcp__google_drive__" ~/.claude/CLAUDE.md 2>/dev/null || grep "Google_Drive" ~/.claude/CLAUDE.md 2>/dev/null`

**Key tools:**
```
mcp__google_drive__search           — search files by name or content
mcp__google_drive__get_file_content — get the text content of a doc
mcp__google_drive__list_files       — list files in a specific folder
```

**Usage in `/pm-challenge-me` — pull existing product context:**
```
mcp__google_drive__search("product spec")
mcp__google_drive__search("user research")
mcp__google_drive__search("strategy")
mcp__google_drive__search("OKR")
```
Take the top 3 results ordered by `modifiedTime desc`. For each, call `mcp__google_drive__get_file_content` and extract: document title, last modified date, key headings (H1/H2), and any metrics, decisions, or goals mentioned.

**Usage in `/pm-prd` — check for existing specs:**
```
mcp__google_drive__search("PRD {feature name}")
mcp__google_drive__search("spec {feature name}")
```
If a match exists, read it before drafting. Surface any prior decisions or constraints to avoid contradicting existing work.

**What to extract:**
- Document title and last modified date → establishes recency and relevance
- Key headings → reveals document structure and scope
- Metrics or KPIs mentioned → feeds `/pm-challenge-me` success criteria section
- Decisions and anti-goals → prevents the new output from rehashing closed debates

**Setup for users:**
Add the Google Drive MCP server to your agent's MCP configuration and grant read access to the relevant Drive.

---

## Tier 2 (API)

**Detection:** `[ -n "$GOOGLE_API_KEY" ]`

**Note:** Google Drive API v3 requires OAuth 2.0 for private files — complex to set up for automated use. The `GOOGLE_API_KEY` approach below works only for files shared publicly or with link access. For most teams, MCP (Tier 1) is strongly preferred.

**Search public/shared docs:**
```bash
curl -s "https://www.googleapis.com/drive/v3/files?q=fullText+contains+'product'+AND+mimeType='application/vnd.google-apps.document'&orderBy=modifiedTime+desc&pageSize=5&key=$GOOGLE_API_KEY" \
  -H "Accept: application/json"
```

**Get file metadata:**
```bash
curl -s "https://www.googleapis.com/drive/v3/files/${FILE_ID}?fields=id,name,modifiedTime,description&key=$GOOGLE_API_KEY"
```

**Export a Google Doc as plain text (OAuth required for private files):**
```bash
curl -s "https://www.googleapis.com/drive/v3/files/${FILE_ID}/export?mimeType=text/plain" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN"
```

**Required env vars:** `GOOGLE_API_KEY` (public files only), or `GOOGLE_OAUTH_TOKEN` for private files.
Get API key: Google Cloud Console → APIs & Services → Credentials → Create API key → restrict to Drive API.

**Heuristics:**
- If search returns 0 results for "product spec" or "strategy": the team likely docs in another tool (Notion, Linear, Confluence). Skip gracefully and note the gap in `/pm-challenge-me`.
- If the most recent strategy doc is >6 months old: flag as a strategic drift risk — the written strategy may not match current priorities.

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

```bash
$B goto https://drive.google.com
$B snapshot
# Read the recent files list — titles visible in the main Drive view
# To search for a specific doc:
$B goto "https://drive.google.com/drive/search?q=product+spec"
$B snapshot
# Navigate to the most relevant result and read the document content
```

**Cookie auth:** Sign in to Google Drive in your browser. nanopm reuses the existing session via the browse binary.

**What to parse from snapshot:**
- File names and last-modified timestamps in the search results list
- Document body text when a specific file is opened

**Limitations:** Google Docs renders content in a canvas-like editor. Snapshot captures visible text only; very long documents require scrolling. For full document extraction, Tier 1 (MCP) or Tier 2 (API export) is significantly more reliable.

---

## Tier 4 (Manual fallback)

**For `/pm-challenge-me`:** Ask the user:
> "Do you have a strategy doc, prior PRD, or research doc you'd like me to use as context? Paste the content or share a URL."

**For `/pm-prd`:** Ask the user:
> "Is there an existing spec or research doc for this feature? Paste it here and I'll incorporate any prior decisions before drafting."

If the user has nothing to share, skip silently. Both skills proceed without prior docs — this connector is enrichment, not a blocker.
