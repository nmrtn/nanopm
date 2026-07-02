---
id: stale-context-docs
type: opportunity
title: "My company/product context docs go stale as the code and market move, but re-maintaining them is a chore I keep skipping"
theme: Context upkeep
status: draft
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-18
---

## 1. Problem summary
The foundational context — vision, mission, business model, org, product, personas — is the layer every later PM phase reads from, so it has to stay accurate. But code ships and the market shifts faster than the solo builder re-visits these docs, and manual upkeep is unrewarding work that gets deprioritized against actual building. The docs quietly drift out of date, and because everything downstream inherits from them, planning ends up resting on stale assumptions.

## 2. Value to the user
### Job to be done
Keep the company/product baseline trustworthy enough that I can plan against it without re-checking whether it's still true. Today the alternative is either hand-editing each Define doc when I happen to notice it's wrong, or — more often — letting it rot and absorbing the drift silently into downstream work.
### Where we fall short
**Upkeep is manual and gets deprioritized**
The solo builder is also the engineer; re-maintaining VISION / BUSINESS-MODEL / PRODUCT is a chore that loses to shipping code, so the foundation decays.

**Drift is invisible until it bites downstream**
Nothing flags that the product reality (the code) or the market has moved past what the docs claim, so stale assumptions propagate into objectives, strategy, and roadmap unnoticed.

## 3. Value to the company
Phase 1 of the autonomous loop is "context defined AND well maintained." If upkeep doesn't happen, every later phase compounds error instead of insight, and the loop's core premise — that context is the durable foundation — breaks. Solving this protects the integrity of everything downstream. Related: [[cold-start-context]].
