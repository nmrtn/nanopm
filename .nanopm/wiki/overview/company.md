---
type: overview
section: define
generated: 2026-06-26
sources: [vision-mission.md, business-model.md, org.md, product.md, personas.md]
---

# PM Context Brief
Generated 2026-06-26 · Project: nanopm · Sources: vision-mission.md, business-model.md, org.md, product.md, personas.md

## What we do
nanopm is a free, open-source (MIT) skill pack of ~20 `/pm-*` commands that install into an AI coding agent (Claude Code, Mistral Vibe, OpenAI Codex) and turn it into an autonomous PM running the full product loop — discover → decide → plan → build → learn — from the terminal where the builder already codes. Its differentiator is an LLM-wiki memory layer the agent owns and refines: immutable raw sources feed into LLM-authored wiki pages, with a company brief and a plan brief injected into every skill run so context compounds across sessions instead of resetting to zero. A read-only macOS SwiftUI viewer renders the wiki by phase. The product is mechanically complete across four phases (Define / Discover / Plan / Build) plus daily ops; whether it is actually wanted is the open question.
_More detail: `.nanopm/wiki/docs/product.md`_

## Who it's for
**Primary — Solo-builder Sam:** a solo founder who is simultaneously PM, engineer, and founder, coding with an AI agent in their terminal. Job to be done: run the full product loop without leaving the coding environment, and feel like a real PM process is running alongside them — not ad hoc decisions in their head. Anti-persona: **Established-PM Pat** — a product manager at a company that already has a PM seat; nanopm would duplicate, not replace, their function, and their feature requests would pull the product off its terminal-first axis.
_More detail: `.nanopm/wiki/docs/personas.md`_

## How we make money
No revenue today; monetization is explicitly undecided and deliberately deferred. The tool is free OSS. GTM is developer-led and bottom-up: zero-friction install (`curl | bash` or native Claude Code plugin), the macOS viewer as a hook, word-of-mouth in AI coding agent communities (Claude Code Discord, the plugin marketplace). Distribution is untested — no organic install rate exists yet. Unit economics: N/A (near-zero marginal cost — it's markdown, bash, and the user's own LLM).
_More detail: `.nanopm/wiki/docs/business-model.md`_

## Why we exist
**Mission:** replace the PM workflow end-to-end for AI coding agents — give the solo builder an autonomous PM that runs the whole product loop in the same terminal as their code. **Vision (3–5 yr):** become the PM layer for agentic development, with memory that compounds across sessions for anyone building with an AI coding agent. **Stage:** early / pre-product-market-fit; open-source project, not a company; zero external users; the core loop works mechanically but its value is unproven. The one belief everything rests on (currently unproven): that solo builders want an autonomous, compounding PM loop in their terminal rather than Notion, ChatGPT, or their own head.
_More detail: `.nanopm/wiki/docs/vision-mission.md`_

## Who decides
Open-source project — no legal entity, no funding, no employees. **Nicolas** (maintainer/founder) is the sole decision-maker on scope and releases; he is in practice also the PM, lead engineer, and designer. **Guillaume** is the major contributor, driving substantial work via pull requests reviewed and merged by Nicolas. All product functions — product, engineering, design, docs, release — sit with the maintainer. The PM nanopm automates is the maintainer's own role, which is both its strongest signal (genuine dogfooding) and its biggest blind spot (n=1 view of the user).
_More detail: `.nanopm/wiki/docs/org.md`_

## What's NOT known yet
- **Whether the core value is wanted.** Zero external users have run the full pipeline unprompted. The load-bearing belief — that solo builders want autonomous PM in their terminal — is assumed, not evidenced.
- **Distribution.** No organic install rate exists; the GTM motion is untested.
- **Monetization path.** Deliberately undecided; not a gap to fill now, but to note for downstream planning.
- **Small-team persona (Mia).** Named as a future secondary target but entirely unvalidated — no small team has ever run nanopm. Treat as hypothesis only.
- **Memory layer adoption.** The LLM-wiki is new and heavier than a low-signal project may need; real-world friction is unknown.
- **n=1 blind spot.** All validation is against the maintainer's own workflow; gap between "one person confirms this" and "10 strangers adopt the habit loop" is the critical unknown.
