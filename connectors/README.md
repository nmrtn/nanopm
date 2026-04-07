# nanopm Connectors

Each file documents how nanopm fetches data from a third-party tool.

## How it works

nanopm tries each tier in order and uses the highest available:

```
Tier 1: MCP tool call   — fastest, most structured
Tier 2: Direct API      — requires API key in environment
Tier 3: Browser scrape  — requires browse binary, uses your authenticated session
Tier 4: Manual          — CONTEXT.md fallback, always works
```

Skills check tier availability via `nanopm_has_connector TOOL` from `lib/nanopm.sh`.

## Adding a connector

1. Create `connectors/{toolname}.md`
2. Define these four sections: `## Tier 1 (MCP)`, `## Tier 2 (API)`,
   `## Tier 3 (Browser)`, `## Tier 4 (Manual fallback)`
3. For Tier 3, specify the root URL and what to navigate to
4. Reference the connector name in any skill that can use it

That's it. No code changes needed.

## Available connectors

| Tool | Tier 1 (MCP) | Tier 2 (API) | Tier 3 (Browser) | Data fetched |
|------|-------------|-------------|-----------------|--------------|
| linear | `mcp__linear__*` | `LINEAR_API_KEY` | linear.app | Issues, cycles, roadmap |
| notion | `mcp__notion__*` | `NOTION_API_KEY` | notion.so | Pages, databases |
| dovetail | — | `DOVETAIL_API_KEY` | dovetail.com | Insights, themes, tags |
| github | `mcp__github__*` | `GITHUB_TOKEN` | github.com | Issues, PRs, releases |
| google-calendar | `mcp__claude_ai_Google_Calendar__*` | OAuth v3 | — | Today's events, meetings |
| granola | `mcp__claude_ai_Granola__*` | — | — | Meeting notes, transcripts |
