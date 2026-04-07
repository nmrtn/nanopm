# Connector: Amplitude

Fetches product analytics — event trends, funnel analysis, retention, and user segments.
Used by `/pm-data` as an alternative or complement to PostHog.

## Tier 1 (MCP)

Amplitude does not currently provide an official MCP server.
Use Tier 2 (API) instead.

---

## Tier 2 (API)

**Detection:** `[ -n "$AMPLITUDE_API_KEY" ] && [ -n "$AMPLITUDE_SECRET_KEY" ]`

**Base URL:** `https://amplitude.com/api/2/`

**Authentication:** HTTP Basic Auth with API key + secret key.

**Event segmentation — trend for an event:**
```bash
curl -s "https://amplitude.com/api/2/events/segmentation" \
  -u "$AMPLITUDE_API_KEY:$AMPLITUDE_SECRET_KEY" \
  -d "e=$(python3 -c "import urllib.parse,json; print(urllib.parse.quote(json.dumps({'event_type':'YOUR_EVENT'})))")" \
  -d "start=$(date -v-30d +%Y%m%d)" \
  -d "end=$(date +%Y%m%d)" \
  -d "i=1"
```

**Funnel analysis:**
```bash
curl -s "https://amplitude.com/api/2/funnels" \
  -u "$AMPLITUDE_API_KEY:$AMPLITUDE_SECRET_KEY" \
  -G \
  --data-urlencode 'e=[{"event_type":"signed_up"},{"event_type":"onboarding_completed"},{"event_type":"first_core_action"}]' \
  -d "start=$(date -v-30d +%Y%m%d)" \
  -d "end=$(date +%Y%m%d)"
```

**Retention:**
```bash
curl -s "https://amplitude.com/api/2/retention" \
  -u "$AMPLITUDE_API_KEY:$AMPLITUDE_SECRET_KEY" \
  -G \
  --data-urlencode 'se={"event_type":"signed_up"}' \
  --data-urlencode 're={"event_type":"core_action"}' \
  -d "start=$(date -v-60d +%Y%m%d)" \
  -d "end=$(date +%Y%m%d)"
```

**User lookup — active users in last 7 days:**
```bash
curl -s "https://amplitude.com/api/2/usersearch" \
  -u "$AMPLITUDE_API_KEY:$AMPLITUDE_SECRET_KEY" \
  -d "user=active"
```

**What to extract:**
- Event counts + % change vs prior period
- Funnel conversion rate per step, biggest drop-off
- Day 1 / Day 7 / Day 30 retention
- Active user counts (DAU, WAU, MAU)

**Required env vars:** `AMPLITUDE_API_KEY`, `AMPLITUDE_SECRET_KEY`
Get them: Amplitude → Settings → Projects → [your project] → API Keys

---

## Tier 3 (Browser)

**Detection:** `$B` available

**URL:** `https://app.amplitude.com`

Navigate to the relevant chart, take a snapshot, and parse the visible numbers.
Useful for one-off reads but unreliable for structured extraction.

---

## Tier 4 (Manual fallback)

If no tier available, `/pm-data` asks:
> "Paste the key metrics you have — conversion rates, DAU/MAU, retention numbers, anything. Raw numbers are fine."
