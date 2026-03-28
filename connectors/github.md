# Connector: GitHub

Fetches recent commits, issues, PRs, and releases from GitHub.
Also supports **write operations** for `/pm-breakdown` ticket creation via GitHub Issues.

## Tier 1 (MCP)

**Detection:** `grep "mcp__github__" CLAUDE.md`

**Read tools:**
```
mcp__github__list_commits       — recent commits (last 30 days)
mcp__github__list_issues        — open issues by label
mcp__github__list_pull_requests — merged PRs (shipped work)
mcp__github__get_release        — latest release notes
```

**Write tools (used by /pm-breakdown):**
```
mcp__github__create_issue       — create a new issue in a repo
```

**Creating an issue (MCP):**
```
mcp__github__create_issue(
  owner: "{owner}",          # from stored github_repo config: "owner/repo"
  repo:  "{repo}",
  title: "Implement X",
  body:  "Engineering task description.\n\n**Acceptance:** ...\n**Ties to:** PRD §N\n\n*Created by nanopm /pm-breakdown*",
  labels: ["nanopm"]         # optional — create label first if it doesn't exist
)
```

**What to extract:**
- Merged PRs in last 30 days → feeds CONTEXT.md Q4 (what shipped)
- Open issues by `bug` label and count → signals quality/debt
- Open issues by `feature` or `enhancement` label → signals demand signals
- Latest release tag and notes → context for /pm-audit

**Setup for users:**
Install GitHub MCP server and add to CLAUDE.md:
```
# GitHub MCP
Use mcp__github__* tools for GitHub access.
```

---

## Tier 2 (API)

**Detection:** `[ -n "$GITHUB_TOKEN" ]`

**Read endpoints:**
```bash
REPO="owner/repo"  # stored in ~/.nanopm/config as github_repo

# Recent merged PRs
curl "https://api.github.com/repos/${REPO}/pulls?state=closed&sort=updated&per_page=30" \
  -H "Authorization: token $GITHUB_TOKEN"

# Open issues
curl "https://api.github.com/repos/${REPO}/issues?state=open&per_page=50" \
  -H "Authorization: token $GITHUB_TOKEN"

# Latest release
curl "https://api.github.com/repos/${REPO}/releases/latest" \
  -H "Authorization: token $GITHUB_TOKEN"
```

**Write — create issue (used by /pm-breakdown):**
```bash
OWNER=$(echo "$REPO" | cut -d/ -f1)
NAME=$(echo  "$REPO" | cut -d/ -f2)

curl -s -X POST "https://api.github.com/repos/${OWNER}/${NAME}/issues" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Implement X\",
    \"body\":  \"Engineering task description.\n\n**Acceptance:** ...\n**Ties to:** PRD §N\n\n*Created by nanopm /pm-breakdown*\",
    \"labels\": [\"nanopm\"]
  }"
```

Extract from response: `.html_url` for the created issue URL.

**Note on token scope:** Tokens need `issues: write` permission for issue creation. Classic tokens need the `repo` scope. Fine-grained tokens need `Issues: Read and write`.

**Setup for users:**
```bash
export GITHUB_TOKEN="ghp_..."
```
Create token: github.com/settings/tokens → Fine-grained → Issues: Read and write

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

**URL discovery (first run):**
```bash
$B goto https://github.com
$B snapshot
# Claude finds first repo URL from dashboard or user profile
# Stores: nanopm_config_set "github_url" "https://github.com/{owner}/{repo}"
```

**Subsequent runs:**
```bash
GITHUB_URL=$(nanopm_config_get "github_url")
$B goto "${GITHUB_URL}/pulls?q=is%3Apr+is%3Amerged+sort%3Aupdated-desc"
$B snapshot  # read merged PR titles
$B goto "${GITHUB_URL}/issues?q=is%3Aissue+is%3Aopen+sort%3Acomments-desc"
$B snapshot  # read top open issues by comment count
```

**Cookie auth:** GitHub sessions are typically long-lived. Sign in to GitHub in your browser; nanopm reuses the existing session via the browse binary.

---

## Tier 4 (Manual fallback)

**CONTEXT.md questions this connector answers:**
- Q4: "What did you ship in the last 30 days?"

GitHub is often the most reliable Tier 1/2 option since most technical founders
already have a GITHUB_TOKEN in their environment.
