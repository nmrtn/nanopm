# Connector: PostHog

Fetches product analytics — trends, funnels, retention, session data, and feature flag usage.
Used by `/pm-data` to answer quantitative product questions.

## Tier 1 (MCP)

**Detection:** `grep "mcp__claude_ai_PostHog__" ~/.claude/CLAUDE.md 2>/dev/null || grep "PostHog" ~/.claude/CLAUDE.md 2>/dev/null`

**Key tools:**
```
mcp__claude_ai_PostHog__query-trends          — time series for any event
mcp__claude_ai_PostHog__query-funnel          — conversion funnel between steps
mcp__claude_ai_PostHog__query-retention       — retention cohort analysis
mcp__claude_ai_PostHog__query-paths           — user paths through the product
mcp__claude_ai_PostHog__query-stickiness      — how often users return to a feature
mcp__claude_ai_PostHog__insight-query         — run a custom HogQL query
mcp__claude_ai_PostHog__persons-list          — list users matching filters
mcp__claude_ai_PostHog__feature-flag-get-all  — all feature flags and their status
mcp__claude_ai_PostHog__projects-get          — current project info
mcp__claude_ai_PostHog__switch-project        — switch active project if needed
```

**Common queries for `/pm-data`:**

Trend — daily active users last 30 days:
```
mcp__claude_ai_PostHog__query-trends(
  events: [{ id: "$pageview", name: "Pageview" }],
  date_from: "-30d"
)
```

Funnel — onboarding drop-off:
```
mcp__claude_ai_PostHog__query-funnel(
  events: [
    { id: "signed_up" },
    { id: "onboarding_step_1_completed" },
    { id: "onboarding_completed" },
    { id: "first_core_action" }
  ],
  date_from: "-30d"
)
```

Retention — week-over-week:
```
mcp__claude_ai_PostHog__query-retention(
  target_entity: { id: "first_core_action" },
  returning_entity: { id: "core_action" },
  period: "Week",
  date_from: "-12w"
)
```

**What to extract:**
- Trend data → absolute numbers + % change vs prior period
- Funnel → conversion rate per step, biggest drop-off step
- Retention → Day 1 / Day 7 / Day 30 retention rates
- Paths → most common paths after key events (reveals unexpected user flows)

**Setup for users:**
Add the PostHog MCP server to your Claude Code configuration.
Ensure the correct project is active with `mcp__claude_ai_PostHog__projects-get`.

---

## Tier 2 (API)

**Detection:** `[ -n "$POSTHOG_API_KEY" ]`

**Base URL:** `https://app.posthog.com/api/` (or self-hosted URL)

**Trends:**
```bash
curl -s "https://app.posthog.com/api/projects/${POSTHOG_PROJECT_ID}/insights/trend/" \
  -H "Authorization: Bearer $POSTHOG_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"events":[{"id":"$pageview"}],"date_from":"-30d","interval":"day"}'
```

**Funnel:**
```bash
curl -s "https://app.posthog.com/api/projects/${POSTHOG_PROJECT_ID}/insights/funnel/" \
  -H "Authorization: Bearer $POSTHOG_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"events":[{"id":"signed_up"},{"id":"onboarding_completed"}],"date_from":"-30d"}'
```

**Required env vars:** `POSTHOG_API_KEY`, `POSTHOG_PROJECT_ID`

---

## Tier 3 (Browser)

Not recommended — PostHog dashboard scraping is fragile. Use Tier 1 or 2.

---

## Tier 4 (Manual fallback)

If no tier available, `/pm-data` asks:
> "Paste the key metrics you have — conversion rates, DAU/MAU, retention numbers, anything. Raw numbers are fine."
