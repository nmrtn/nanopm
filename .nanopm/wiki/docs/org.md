# Org
Mode: reverse-engineered from git history + maintainer confirmation · 2026-06-25

## What kind of org
An **open-source project** (MIT), not a company. No legal entity, no employees, no
funding. Governance is maintainer-led, the norm for a small OSS project.

## People & roles
- **Nicolas** — maintainer / founder. Owns direction, decides what ships, reviews and
  merges. In practice also the PM, lead engineer, and designer (the viewer). Sole
  decision-maker on scope and releases.
- **Guillaume** — major contributor. Drives substantial work via pull requests (notably
  the memory / LLM-wiki redesign), reviewed and merged by the maintainer.

## How decisions get made
Founder-led, lightweight. Direction is Nicolas's call. Contributions land as PRs that
Nicolas reviews and merges; disagreements are resolved in PR threads, not by process.
No roadmap committee, no formal sign-offs.

## Functions
All product functions (product, engineering, design, docs, release) sit with the
maintainer. There is no separate sales, marketing, or support — distribution is the
free OSS install and word of mouth.

## Why this matters for the product
The "PM" nanopm automates **is the maintainer's own role.** The target user — a solo
builder who is simultaneously PM, engineer, and founder — is literally the org. This is
the project's strongest signal (genuine dogfooding) and its biggest blind spot (an n=1
view of the user; everything is validated against one person's workflow).

---

## Provenance & assumptions
- **OSS / MIT / maintainer-led** — *User-stated + Evidenced.* Maintainer confirmed this
  run; corroborated by `LICENSE` and the GitHub PR-and-merge workflow.
- **Nicolas = maintainer, Guillaume = major contributor** — *Evidenced.* From git history
  and PR authorship (e.g. the memory-wiki PRs).
- **n=1 blind spot** — *Assumed (interpretation).* Follows from a 2-person OSS project with
  zero external users; flagged so personas/strategy treat "the user = the maintainer" as a
  risk, not a given.
