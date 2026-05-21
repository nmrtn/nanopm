# Connector: Mixpanel

Fetches product analytics — event trends, funnel analysis, and retention cohorts from Mixpanel.
Used by `/pm-data` as an alternative to PostHog or Amplitude for quantitative product questions.

## Tier 1 (MCP)

Mixpanel does not currently provide an official MCP server.
Use Tier 2 (API) instead.

---

## Tier 2 (API)

**Detection:** `[ -n "$MIXPANEL_SERVICE_ACCOUNT" ] && [ -n "$MIXPANEL_SERVICE_ACCOUNT_SECRET" ]`

**Authentication:** HTTP Basic Auth with service account credentials.

**Base URLs:**
- Query (data): `https://data.mixpanel.com/api/2.0/`
- Management: `https://mixpanel.com/api/2.0/`

**Event segmentation — trend for an event over the last 30 days:**
```bash
curl -s "https://data.mixpanel.com/api/2.0/segmentation" \
  -u "$MIXPANEL_SERVICE_ACCOUNT:$MIXPANEL_SERVICE_ACCOUNT_SECRET" \
  -G \
  -d "project_id=$MIXPANEL_PROJECT_ID" \
  --data-urlencode 'event=your_event_name' \
  -d "from_date=$(date -v-30d +%Y-%m-%d)" \
  -d "to_date=$(date +%Y-%m-%d)" \
  -d "unit=day"
```

**Funnel analysis:**
```bash
curl -s "https://data.mixpanel.com/api/2.0/funnels" \
  -u "$MIXPANEL_SERVICE_ACCOUNT:$MIXPANEL_SERVICE_ACCOUNT_SECRET" \
  -G \
  -d "project_id=$MIXPANEL_PROJECT_ID" \
  -d "funnel_id={FUNNEL_ID}" \
  -d "from_date=$(date -v-30d +%Y-%m-%d)" \
  -d "to_date=$(date +%Y-%m-%d)"
```

To find funnel IDs: `GET https://mixpanel.com/api/2.0/funnels/list?project_id=$MIXPANEL_PROJECT_ID`

**JQL — ad-hoc queries (flexible, most powerful):**
```bash
curl -s "https://data.mixpanel.com/api/2.0/jql" \
  -u "$MIXPANEL_SERVICE_ACCOUNT:$MIXPANEL_SERVICE_ACCOUNT_SECRET" \
  -d "project_id=$MIXPANEL_PROJECT_ID" \
  --data-urlencode 'script=
    function main() {
      return Events({
        from_date: "'"$(date -v-30d +%Y-%m-%d)"'",
        to_date:   "'"$(date +%Y-%m-%d)"'",
        event_selectors: [{ event: "your_event_name" }]
      })
      .groupByUser(mixpanel.reducer.count())
      .reduce(mixpanel.reducer.count());
    }
  '
```

**What to extract:**
- Segmentation → event counts per day, total + % change vs prior period
- Funnel → conversion rate per step, biggest drop-off step and its absolute loss
- JQL → custom aggregations, user-level counts, property breakdowns

**Required env vars:** `MIXPANEL_SERVICE_ACCOUNT`, `MIXPANEL_SERVICE_ACCOUNT_SECRET`, `MIXPANEL_PROJECT_ID`

Get them: Mixpanel → Settings → Service Accounts (for credentials) and Settings → Project Settings (for project ID).

---

## Tier 3 (Browser)

**Detection:** `$B` available

**URL:** `https://mixpanel.com/project/$MIXPANEL_PROJECT_ID/view/reports/insights`

Navigate to the relevant Insights, Funnels, or Retention report, take a screenshot, and parse the visible numbers.

```bash
$B goto "https://mixpanel.com/project/${MIXPANEL_PROJECT_ID}/view/reports/insights"
$B screenshot
```

Useful for one-off reads when a saved report already has the right configuration, but unreliable for structured or repeatable extraction.

---

## Tier 4 (Manual fallback)

If no tier is available, `/pm-data` asks:
> "Paste the key metrics you have — conversion rates, DAU/MAU, retention numbers, anything. Raw numbers are fine."
