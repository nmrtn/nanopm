# The Product Loop

**The nanopm method for continuous, agent-run product management.**

This is not a feature list. It is a doctrine — the opinionated method the nanopm skill
pack implements, the way *Shape Up* is the method Basecamp's tools implement. Read it
to decide whether you want to work this way. If you do, nanopm is the tooling. If you
don't, no amount of tooling will help.

---

## Part 1 — The diagnosis

**Building got fast. Deciding didn't.**

An AI coding agent ships a feature in an afternoon. The decision about *which* feature
— grounded in what users actually said, checked against strategy, weighed against
everything else you could do — still runs on the old clock: a human, a doc, a backlog
groomed by hand, a roadmap that was true the day it was written.

The result is a new failure mode: **execution outruns judgment.** You ship faster than
you can decide what's worth shipping. The bottleneck moved and the tools didn't.

**Trackers track. They don't think.**

Every PM tool you've used is a filing cabinet with opinions about columns. It knows
your tickets. It doesn't know your code, your users' verbatims, your strategy, or
what you shipped yesterday — and it forgets everything between sessions. The thinking
happens in your head and evaporates.

**The unit of product work is not the ticket. It is the loop:**

> signal → problem → bet → ship → learn → signal

Every method that works — Teresa Torres' continuous discovery, Basecamp's Shape Up,
the Lean loop — is a variation of this cycle. The methods failed in practice not
because they were wrong but because they were *expensive*: maintaining an evidence
base, re-ranking priorities, keeping a roadmap honest — that's hours of disciplined
human labor per week, so nobody did it.

Agents make the marginal cost of discipline near zero. That is the whole opening.
The loop can finally run at the speed the method always demanded.

---

## Part 2 — The principles

### 1. Problems before solutions

The center of gravity is a ranked database of **user problems** — the Opportunity
Solution Tree's middle layer — not a backlog of features. Solutions are hypotheses
attached to problems, never free-floating. A feature idea with no parent problem is
noise, however good it sounds.

Two levels only: Theme → Opportunity. If you need a third level, your opportunities
are too vague.

### 2. Evidence is identity

Every claim carries its provenance, never silently: **nano-hypothesis** (the agent
guessed), **user-stated** (someone said it once), or **evidence-backed** (corroborated).
Every verbatim is archived raw, immutable, before anything is extracted from it, and
cited as `"<quote>" — <source>, <date>`. The citation *is* the dedup key: same source,
same date, same quote — same fact.

A claim without a source is a hypothesis, and it says so on its face. This is the
difference between a wiki you trust and a wiki that flatters you.

### 3. Every bet is falsifiable

A bet names a **number**, a **segment**, a **behavior**, and a **timeframe** — or it
is not a bet, it is a wish. "Improve onboarding" is a wish. "≥40% of the prototype
cohort voluntarily runs a second pipeline within 14 days" is a bet: it can lose, and
you'll know when.

Strategy that cannot name the evidence that would prove it wrong is guesswork with
confidence.

### 4. Appetite, not estimates

You don't ask "how long will this take?" — with an agent building, the answer is
mostly "less than you think" and always unreliable. You ask "how much is this
*worth*?" — small bet or big bet — and the work fits the budget or gets cut. Appetite
is a constraint you set; an estimate is a prediction you'll be wrong about.

### 5. Adversarial by default

Every strategy, every PRD, every plan meets a skeptic before it ships — an adversarial
pass whose first move is naming **the question you're avoiding**. Conviction that
hasn't survived an attack is just mood.

The skeptic is cheap now. Use it every time.

### 6. Agents do; humans decide

The agent writes, ranks, dedupes, indexes, archives, cross-links, and remembers.
The human makes exactly the calls that are theirs:

1. **What's true** — confirm which problems are real, which evidence holds.
2. **What to bet** — choose the solution, approve the strategy.
3. **How much it's worth** — set the appetite.

Everything outside those three decisions is agent work, and routing it to a human is
waste. Automating *those three* is malpractice. The loop pauses there, every time.

### 7. Memory compounds or nothing does

Every run starts already knowing who the company is and what it's working on — two
generated briefs, loaded into every skill, regenerated whenever their sources change.
The rest of memory is an agent-maintained wiki: write freely, lint surfaces problems,
the human curates. History is superseded, never deleted — you can always see what you
used to believe and when you stopped.

A session that starts from zero is a session that repeats last month's thinking at
full price.

### 8. All work competes in one queue

An opportunity, a solution, a task, a bug, a chore — these are different shapes of
the same question: **what is the next best action?** They do not live in separate
lists with separate rankings that a human merges in their head. One sift types every
incoming item. One ranking, anchored to strategy and objectives, orders them all.
The output is a literal ordered list a human — or an autonomous agent — can execute
from directly.

If your bugs live in one tool, your ideas in another, and your strategy in a doc,
then "what should I do next?" has no answer — it has a negotiation.

### 9. The roadmap is an output, not a document

Nobody writes the roadmap. The loop **renders** it: the current ordering of bets,
each labeled with the problem it answers and the objective it serves, at more than
one altitude (execution view, stakeholder view). When priorities shift, the roadmap
changed and can say why. If a roadmap is stale, it's because the loop stopped — not
because someone forgot to edit a page.

A hand-written roadmap is a screenshot of a decision, decaying from the moment it's
taken.

### 10. Close every loop

Shipped work updates the entities that predicted it: the PRD ships → its solution
transitions → its opportunity is archived *with a reason a stranger can understand*.
Retro measures the plan against the actual commits and carries the drift forward.
Falsification deadlines are watched, and a bet that quietly expired is called out.

An unclosed loop is a lie the wiki tells. The archive with its reason is not
bureaucracy — it's the difference between a memory and a landfill.

---

## Part 3 — The Loop

The method is one cycle, five stages, running on a **tick** — daily, or whenever an
input arrives. Most ticks do nothing. That's the point: cheap ticks are what make the
expensive ones timely.

```
        ┌──────────────────────────────────────────────┐
        │                                              │
        ▼                                              │
     SENSE ──► SIFT ──► RANK ──► ACT ──► LEARN ────────┘
                          ▲
              (strategy · objectives · memory)
```

**SENSE** — Inputs arrive: user feedback, interview notes, product data, competitor
moves, commits, incoming bugs, your own observations. Each is archived raw and
verbatim before anything else touches it. Refreshed on the tick or on trigger.

**SIFT** — Every input becomes typed work. A discovery filter (Mom Test: keep
problems and past behavior, demote feature requests and hypotheticals) separates
signal from noise. New signal either *grounds* an existing opportunity (evidence
appended, provenance upgraded) or *becomes* new typed work: opportunity, bug, chore,
task. Dedup runs at the gate — high-confidence merges happen; near-matches get linked,
not merged.

**RANK** — One prioritization pass across the whole queue — every type together —
anchored to the current strategy and objectives. Output: the **Next List**, a ranked,
typed, actionable list. This is the living roadmap's source of truth. Re-ranking is
cheap, so it happens continuously, and every reorder can explain itself.

**ACT** — The top of the list gets executed with the right context: the two briefs,
the entity and its evidence, the parent problem. Big items flow through the tree —
solution panel, adversarial gate, PRD, breakdown, handoff to the tracker or the
coding agent. Small items (bugs, chores) skip the ceremony and just get done. The
human intervenes only at the three decisions.

**LEARN** — Reality flows back: commits, closed tickets, test results, retention
signals. Statuses transition, opportunities archive with reasons, retro measures
plan vs. shipped, drift above threshold triggers a re-rank. What's learned is written
into memory with provenance — which is what makes the next SENSE smarter than the
last.

---

## Part 4 — What we refuse

The method is defined as much by what it won't do:

- **No numeric priority scores presented as fact.** Coarse judgment (high/medium/low),
  owned and overridable, beats a RICE spreadsheet's false precision.
- **No estimates.** Appetite only.
- **No rebuilding the tracker.** Tickets live in Linear, GitHub, wherever the team
  works. The loop hands off and reads back; it does not become another place tickets
  go to age.
- **No dashboard theater.** A metric enters the loop when a bet names it. Vanity
  numbers stay out.
- **No silent automation of judgment.** The loop never confirms a problem, chooses a
  bet, or sets an appetite on its own. Speed everywhere else buys deliberation exactly
  there.
- **No unmarked guesses.** The agent hypothesizes freely — labeled as such. The moment
  a guess dresses as evidence, the whole memory is worthless.

---

## Part 5 — State of the method

This manifesto obeys its own provenance rule. As of 2026-07-06, running on nanopm
itself:

**Practiced — evidence-backed by the dogfood:**

- The vertical chain: raw signal → archived verbatim → manifest-linked opportunity →
  solution panel → chosen solution → PRD with falsification gate → breakdown handoff.
  (42 opportunities, 35 solutions, 31 PRDs, manifest links resolving raw quotes to
  entity slugs.)
- Provenance discipline, adversarial gates, appetite, the memory wiki with briefs,
  lint, supersede-never-delete, archive-with-reason.
- Retro comparing roadmap against commits; typed event log as heartbeat.

**Doctrine ahead of code — assumed, being built:**

- Tasks, bugs, and chores as first-class typed work (today they exit via handoff and
  never return).
- RANK: the single cross-type prioritizer and the Next List it emits.
- The roadmap as a rendered output with problem/objective labels at two altitudes
  (today it's a generated document without entity-level links).
- The tick: today every stage is invoked by hand; nothing triggers, polls, or
  re-ranks on its own.
- LEARN backpropagation: auto status transitions on ship, KR progress readback,
  falsification-deadline watching.

The gap is not hidden and not accidental: the loop's own discovery process surfaced
each missing brick as a ranked opportunity in its own database before this document
named them. That is the method working — on itself, first.
