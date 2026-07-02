# Business Model
Mode: reverse-engineered from repo + install paths + maintainer confirmation · 2026-06-25

## Model type
Free, open-source developer tool (MIT). A skill pack that installs `/pm-*` commands
into an AI coding agent. **No revenue model — monetization is explicitly undecided.**
The "business" today is distribution and learning, not money.

## Revenue streams
None today, none committed. Monetization is an open question, deliberately deferred
until adoption exists. Recording it as undecided rather than inventing a model.

## Pricing & packaging
- **Price:** free.
- **Packaging:** the whole skill pack, installed two ways —
  - `curl -fsSL …/setup | bash` (works for Claude Code, Vibe, Codex).
  - Native **Claude Code plugin** (marketplace + `SessionStart` hook bootstrap).
- A companion **macOS viewer** (read-only) renders the `.nanopm/` wiki.

## Go-to-market motion
Developer-led / bottom-up. The wedge is "install in seconds, plan in your terminal":
- Zero-friction install, runs where the builder already works.
- The viewer as a hook (something to look at, not just CLI output).
- Word-of-mouth in AI-coding-agent communities (Claude Code Discord, the plugin
  marketplace). Distribution is currently **untested** — no organic install rate yet.

## Unit economics
N/A — no revenue, near-zero marginal cost (it's markdown + bash + the user's own LLM).

## The riskiest assumption
That **adoption happens at all.** With zero external users and an untested distribution
channel, monetization is moot — the prior question is whether strangers install and
return. Until that's answered, "business model" = "get one real user," not "pick a price."

---

## Provenance & assumptions
- **Free / OSS / install paths** — *Evidenced.* From `setup`, `.claude-plugin/`,
  `LICENSE` (MIT), and `README.md`.
- **GTM = developer-led, viewer-as-hook** — *Evidenced.* From the install design and the
  `viewer/` app; the Discord/marketplace channel is named in the roadmap.
- **Monetization undecided** — *User-stated.* Maintainer confirmed this run: genuinely open.
- **Distribution untested / adoption is the real risk** — *Evidenced.* The project's own
  AUDIT/STRATEGY and this session both state zero external users and an unrun adoption test.
