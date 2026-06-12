# Connector: HubSpot

Fetches deal pipeline data, company segments, and contact notes from HubSpot CRM.
Used by `/pm-challenge-me` to surface product-market fit signals from the sales pipeline, and by `/pm-discovery` to identify ICP patterns and recurring objections from deal notes.

## Tier 1 (MCP)

No official HubSpot MCP server exists.
Use Tier 2 (API) instead.

---

## Tier 2 (API)

**Detection:** `[ -n "$HUBSPOT_API_KEY" ]`

**Base URL:** `https://api.hubapi.com/crm/v3`

**Authentication:** `Authorization: Bearer $HUBSPOT_API_KEY`

**Recent deals — pipeline snapshot:**
```bash
curl -s "https://api.hubapi.com/crm/v3/objects/deals?limit=10&properties=dealname,amount,dealstage,closedate,pipeline&sort=-createdate" \
  -H "Authorization: Bearer $HUBSPOT_API_KEY" \
  -H "Content-Type: application/json"
```

**Companies by segment — ICP analysis:**
```bash
curl -s "https://api.hubapi.com/crm/v3/objects/companies?limit=10&properties=name,industry,numberofemployees,hs_lead_status" \
  -H "Authorization: Bearer $HUBSPOT_API_KEY" \
  -H "Content-Type: application/json"
```

**Contacts with role data:**
```bash
curl -s "https://api.hubapi.com/crm/v3/objects/contacts?limit=10&properties=email,jobtitle,company,hs_lead_status" \
  -H "Authorization: Bearer $HUBSPOT_API_KEY" \
  -H "Content-Type: application/json"
```

**Deal pipeline structure — all stages and their counts:**
```bash
curl -s "https://api.hubapi.com/crm/v3/pipelines/deals" \
  -H "Authorization: Bearer $HUBSPOT_API_KEY" \
  -H "Content-Type: application/json"
```

**What to extract:**
- Deal stage distribution → reveals where deals stall (product-market fit signal)
- Common `industry` and `numberofemployees` across closed-won companies → reveals ICP
- `dealstage` breakdown across all open deals → surfaces conversion bottlenecks
- Contact `jobtitle` patterns → identifies who champions the product vs who blocks it
- Recent deal names → often describe use cases verbatim ("Automate X for Y team")

**Required env vars:** `HUBSPOT_API_KEY`
Get it: HubSpot → Settings → Integrations → Private Apps → Create private app → scope: `crm.objects.deals.read`, `crm.objects.companies.read`, `crm.objects.contacts.read`

**Heuristics for `/pm-challenge-me`:**
- If >30% of open deals are in a "Proposal Sent" or "Negotiation" stage with no recent movement to Closed Won: flag as a conversion problem. Likely cause: unclear value prop, missing feature for procurement, or pricing mismatch — worth calling out as a strategic gap.
- If Closed Lost deals cluster around a single stage (e.g., all lost at "Demo Scheduled"): the product is failing to demonstrate value, not failing at sourcing. Surface this as a messaging or onboarding issue, not a feature gap.
- If company `numberofemployees` varies widely across Closed Won (e.g., 5-person shops and 500-person companies both winning): ICP is undefined. Flag as the highest-priority strategic clarification needed.
- If deal amounts vary by 10x+ across Closed Won: pricing strategy is likely inconsistent. Note for `/pm-strategy`.
- If contacts are predominantly individual contributors (no VP/Director titles in Closed Won): the product may lack executive sponsorship, which limits expansion and renewal.

---

## Tier 3 (Browser)

**Detection:** `$B` available (browse binary found)

```bash
# Replace {HUB_ID} with your HubSpot portal ID (found in any HubSpot URL)
$B goto "https://app.hubspot.com/contacts/${HUB_ID}/deals"
$B snapshot
# Read the pipeline board: column headers are deal stages, card counts visible per column
# For a deals list view with stage distribution:
$B goto "https://app.hubspot.com/contacts/${HUB_ID}/objects/0-3/views/all/list"
$B snapshot
```

**Cookie auth:** Sign in to HubSpot in your browser. nanopm reuses the existing session via the browse binary.

**What to parse from snapshot:**
- Pipeline board column headers and card counts → immediate stage distribution read
- Deal card titles visible in the board view → use-case language from real deals
- Filter/sort controls → can narrow to Closed Won or Closed Lost for targeted analysis

**Limitations:** HubSpot's pipeline board is paginated per stage and dynamically rendered. Snapshot captures only what is visible in the viewport. For reliable stage distribution counts, Tier 2 (API) is preferred. Browser is useful for a quick visual read or when the API key is unavailable.

---

## Tier 4 (Manual fallback)

**For `/pm-challenge-me`:** Ask the user:
> "What does your sales pipeline look like? Which deals are closing and which are being lost — and do you know why? (Skip this if sales data isn't relevant to your product.)"

**For `/pm-discovery`:** Ask the user:
> "Describe your typical customer — company size, industry, and what problem they're trying to solve. Are there patterns in who buys vs who doesn't?"

If the user skips or has no sales data (e.g., pre-revenue, self-serve, open source), skip silently. Both skills proceed without CRM data — this connector is enrichment for sales-led or product-led products with an active pipeline.
