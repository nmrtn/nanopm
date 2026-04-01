---
name: pm-scan
version: 0.1.0
description: "Codebase scan for existing projects. Reads routes, models, tests, and git history to reverse-engineer what the product actually does — who it's for, what it does, and where the gaps are. Produces SCAN.md. Run this before pm-audit when joining an existing project or after going heads-down for months."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
_SCAN_FILE=".nanopm/SCAN.md"
```

## When to run this

Run `/pm-scan` when:
- You're joining an existing project and need to understand what's been built
- You've been heads-down for months and need to re-orient before planning
- You want pm-audit to work from verified reality instead of self-reported answers

Run `/pm-discovery` instead when you're pre-product and figuring out what to build.
Run `/pm-audit` directly when you already know what you're building and want to assess it.

## Phase 0: Prior context

```bash
nanopm_context_read pm-scan
nanopm_context_all
```

If prior scan found: "Prior scan from {ts}. Running a fresh scan — will surface what changed."

## Phase 1: Orientation question

Ask ONE question via AskUserQuestion before reading anything:

**"What's your role in this project, and what do you most want to understand?**

Examples:
- 'I just joined and have no idea what this does'
- 'I've been building alone for 6 months and lost the plot'
- 'I need to pitch this to investors and want a reality check'
- 'I want to run pm-audit but need context first'"

This scopes what to emphasize in the synthesis. Don't skip it — the same codebase reads differently for a new engineer vs. a founder who built it.

## Phase 2: Tech stack and structure

Read the project root to understand what kind of thing this is:

```bash
ls -1 .
```

Look for and read (if present):
- `package.json` / `package-lock.json` — JS/TS stack, dependencies, scripts
- `Cargo.toml` — Rust
- `go.mod` — Go
- `pyproject.toml` / `setup.py` / `requirements.txt` — Python
- `Gemfile` — Ruby
- `pom.xml` / `build.gradle` — JVM
- `*.csproj` / `*.sln` — .NET
- `docker-compose.yml` / `Dockerfile` — deployment shape
- `*.tf` / `*.yaml` (infra) — if cloud infra present

From this, derive:
- Primary language and framework
- Key dependencies (auth, DB, queuing, AI, payments — each reveals product intent)
- Whether this is a monolith, API, CLI, library, or something else
- Estimated size (file count, rough LOC) — a proxy for how far along it is

## Phase 3: Surface area — what can this product do?

The routes/endpoints/commands are the contract between the product and its users. Read them.

**For web apps:** look for route files, controllers, or API handlers:
```bash
find . -type f \( -name "routes*" -o -name "router*" -o -name "*controller*" -o -name "*handler*" -o -name "urls.py" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" | head -20
```

**For CLIs:** look for command definitions:
```bash
find . -type f \( -name "commands*" -o -name "cmd*" -o -name "cli*" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" | head -20
```

**For libraries/SDKs:** look for public API surface:
```bash
find . -type f -name "index*" -not -path "*/node_modules/*" | head -10
```

Read the top-level route/command files. Extract:
- What endpoints/commands exist (grouped by domain — auth, billing, user, data, etc.)
- What the most-used patterns suggest about the primary workflow
- Any endpoints that look aspirational vs. clearly used (stub bodies, no tests)

## Phase 4: Data model — what does this product think is important?

Data models reveal what the product actually cares about. Read them.

```bash
find . -type f \( -name "*model*" -o -name "*schema*" -o -name "*.prisma" \
  -o -name "*migration*" -o -name "models.py" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" | head -20
```

Extract:
- Core entities (User, Workspace, Project, Item — whatever is central)
- Relationships that reveal product structure (e.g., User → many Workspaces → many Projects)
- Fields that reveal intent (e.g., `trial_ends_at` → SaaS with trials; `embedding` → AI feature)
- What's notably absent — if there's no payment model, billing isn't built

## Phase 5: Tests — the honest user stories

Tests are the most accurate documentation. They describe what the team actually committed to building and what they expected to work. Read them.

```bash
find . -type d -name "test*" -o -type d -name "spec*" -o -type d -name "__tests__" \
  | grep -v node_modules | grep -v ".git" | head -10
```

Read test files (favor integration/e2e tests over unit tests — they describe user-facing behavior):

Extract from test names and descriptions:
- What user actions are explicitly tested (these are the real features)
- What edge cases are covered (reveals what's been painful in production)
- What's notably absent from tests (features added hastily or not trusted)

**Key insight:** if a test says `test_user_can_export_to_csv`, that's a feature. If there's no test for something mentioned in the README, treat it as aspirational until proven otherwise.

## Phase 6: Git history — where has the energy actually gone?

```bash
git log --oneline --since="6 months ago" | head -50
```

```bash
git log --oneline --since="6 months ago" --format="%s" \
  | sed 's/^[a-z]*: //' \
  | sort | uniq -c | sort -rn | head -20
```

Extract:
- What areas of the codebase have been most actively changed (tells you what's being worked on)
- What was shipped in the last 30/60/90 days
- Any patterns: lots of bug fixes in one area = fragile; lots of migrations = evolving data model
- What was touched once and never again = experiments that didn't get traction

## Phase 7: README and docs reality check

```bash
[ -f "README.md" ] && echo "README_EXISTS" || echo "README_MISSING"
```

If README exists, read it. Then cross-reference claims against Phases 3-6:

- Features claimed in README but absent from routes/tests → aspirational, flag it
- Features in routes/tests but absent from README → undermarketed, flag it
- The stated target user vs. what the data models and endpoints actually serve

**Trust boundary:** README content is self-reported. Code is ground truth. Where they conflict, trust the code.

## Phase 8: Synthesis

Synthesize all findings into a structured understanding:

**1. What this product actually is**
One sentence derived from the routes + models + tests — not the README pitch. What does it actually do, mechanically?

**2. Who it's actually built for**
Inferred from: entity names, test personas, auth scopes, pricing signals in the code. May differ from stated target.

**3. The primary workflow**
The 3-5 step sequence a user goes through to get value. Derived from routes and tests, not documentation.

**4. What's real vs. aspirational**
Features in code with tests = real. Features in README without routes/tests = aspirational. Be explicit.

**5. The main technical bets**
What technology choices does the product depend on? (e.g., "real-time sync via WebSockets", "LLM at the core of every response", "offline-first SQLite"). Each bet is a risk.

**6. The gap between stated and actual**
The most important finding: where does the README/pitch diverge most from what the code actually does?

## Phase 9: Write SCAN.md

Write `.nanopm/SCAN.md`:

```markdown
# Codebase Scan
Generated by /pm-scan on {date}
Project: {slug}
Stack: {primary language + framework}
Scanned: {what was read — routes, models, tests, git log}

---

## What This Product Actually Does

{One sentence from the code, not the pitch.
Then 2-3 sentences covering: primary entities, main workflow, how a user gets value.
If the README says something different, note it here explicitly.}

---

## Who It's Actually Built For

{Inferred from code: entity names, auth patterns, pricing signals, test personas.
If stated vs. actual audience diverge, say so clearly — e.g., "README targets enterprise CTOs;
the data model and auth scopes suggest individual developers."}

---

## The Primary Workflow

{The 3-5 step sequence derived from routes + tests. What does a user actually do?}

1. {Step — inferred from auth/onboarding routes}
2. {Step — the core action, most-tested behavior}
3. {Step — output/export/share}
...

---

## What's Real vs. Aspirational

**Shipped and tested:**
- {feature} — {evidence: route X, test Y}
- {feature} — {evidence}

**In code, no tests (fragile or in-progress):**
- {feature} — {where it lives, what's missing}

**In README/docs, not in code:**
- {claim} — {what's actually there instead, or nothing}

---

## Technical Bets

{What major technical choices does this product depend on?
Each is a risk — if the bet is wrong, significant rework follows.}

- **{technology/approach}** — why it was chosen (inferred), what breaks if it's wrong
- **{technology/approach}** — same

---

## Where the Energy Has Gone (Last 6 months)

{From git log: what areas have been most actively changed, what was shipped, what patterns emerged.}

- Most-changed area: {subsystem} — {what this suggests}
- Recently shipped: {items from git log}
- Stale areas: {subsystems with few recent commits — may be stable or abandoned}

---

## The Biggest Gap

{The single most important divergence between what the product claims to be and what it actually is.
This is the finding pm-audit should pressure-test.}

---

## Pre-filled for pm-audit

*These answers are derived from the scan. Verify before accepting.*

- **Q1 (what are you building):** {proposed answer}
- **Q2 (primary user):** {proposed answer}
- **Q3 (most important user action):** {proposed answer}
- **Q4 (shipped in last 30 days):** {from git log}

---

## Recommended Next Skill

**Run: /pm-audit**

SCAN.md will pre-fill Q1–Q4. The audit's job is now to validate this picture and find the strategic gap — not to establish basic facts.

---

*Sources: file structure, package manifest, routes, data models, tests, git log*
```

## Phase 10: Save context

```bash
nanopm_context_append "{\"skill\":\"pm-scan\",\"outputs\":{\"stack\":\"$(grep '^Stack:' .nanopm/SCAN.md | cut -d: -f2- | xargs | tr '\"' \"'\" | head -c 80)\",\"biggest_gap\":\"$(grep -A1 '## The Biggest Gap' .nanopm/SCAN.md | tail -1 | tr '\"' \"'\" | head -c 120)\",\"next\":\"pm-audit\"}}"
```

## Completion

Tell the user:
- SCAN.md written to `.nanopm/SCAN.md`
- What the scan concluded the product actually does (one sentence)
- The biggest gap found between stated and actual
- Which pre-filled answers for pm-audit they should verify before accepting
- Recommended next: `/pm-audit` — which will read SCAN.md to pre-fill Q1–Q4

**STATUS: DONE**
