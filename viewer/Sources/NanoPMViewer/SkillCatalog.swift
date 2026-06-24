import Foundation

/// Stable nav-route identifiers shared between the catalog and ProjectView.
enum NavRoute {
    static let prdsPage = "page:prds"
    static let opportunitiesPage = "page:opportunities"
    static let competitorsPage = "page:competitors"
    static let memoryPage = "page:memory"
    static let brainstormPage = "page:brainstorm"
    static func overview(_ phase: Phase) -> String { "overview:" + phase.rawValue }
}

/// One runnable skill in a phase overview: what it produces, where it lands,
/// and the command that generates it.
struct SkillDoc: Identifiable {
    /// What the skill produces, which drives the row's status display.
    enum Output: Equatable {
        case file(String)                          // canonical .nanopm/ path
        case folder(prefix: String, opens: String) // many files; opens a folder page
        case handoff(String)                       // no .nanopm output (note text)
    }

    let title: String
    let blurb: String
    let icon: String
    let skillCommand: String?
    let headlessArgs: String?
    let phase: Phase
    let output: Output

    var id: String { title }

    /// Run-tracking key (and canonical artifact path for `.file`).
    var trackingPath: String {
        switch output {
        case .file(let path): return path
        case .folder(let prefix, _): return prefix
        case .handoff: return skillCommand ?? title
        }
    }
}

enum SkillCatalog {
    static func docs(for phase: Phase) -> [SkillDoc] { all.filter { $0.phase == phase } }

    /// True if a `.file(output)` skill owns this artifact. Under wiki-canonical writes
    /// a skill's output moved from the legacy flat `<DOC>.md` to its wiki page
    /// `wiki/docs/<slug>.md`, where <slug> is the output basename lowercased with
    /// '_'/' ' -> '-' (matching nanopm_wiki_doc_path). Dated docs (standup/retro)
    /// match by `<slug>-` prefix, e.g. wiki/docs/standup-2026-06-24.md. The legacy
    /// flat path still matches so un-migrated projects keep working.
    static func fileMatches(output: String, artifact: String) -> Bool {
        if output == artifact { return true }
        guard artifact.hasPrefix("wiki/docs/") else { return false }
        func stem(_ p: String) -> String {
            let base = ((p as NSString).lastPathComponent as NSString).deletingPathExtension
            return base.lowercased()
                .replacingOccurrences(of: "_", with: "-")
                .replacingOccurrences(of: " ", with: "-")
        }
        let o = stem(output), a = stem(artifact)
        if a == o { return true }
        // Dated docs only (standup-YYYY-MM-DD, retro-YYYY-MM-DD): the remainder after
        // "<slug>-" must be an ISO date, so a future page slug like "org-chart" can't
        // be silently claimed by the "org" skill.
        guard a.hasPrefix(o + "-") else { return false }
        let suffix = String(a.dropFirst(o.count + 1))
        return suffix.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
    }

    /// Icon for the skill that produces this artifact, so the sidebar matches
    /// the overview pages. Nil when no catalog skill owns the path.
    static func icon(forArtifact relativePath: String) -> String? {
        all.first { doc in
            if case .file(let path) = doc.output { return fileMatches(output: path, artifact: relativePath) }
            return false
        }?.icon
    }

    /// The skill whose output owns this artifact, so a document's own detail
    /// page can offer the same Run action as the phase overview. Matches a
    /// `.file` output (legacy flat path or its wiki page) or a `.folder` output by
    /// path prefix; returns nil for artifacts no skill produces.
    static func doc(forArtifact relativePath: String) -> SkillDoc? {
        all.first { doc in
            switch doc.output {
            case .file(let path): return fileMatches(output: path, artifact: relativePath)
            case .folder(let prefix, _): return relativePath.hasPrefix(prefix)
            case .handoff: return false
            }
        }
    }

    /// The PRDs folder skill icon, so the nav folder matches its overview row.
    static var prdsIcon: String {
        all.first { $0.title == "PRDs" }?.icon ?? "folder"
    }

    /// The Opportunities folder skill icon, so the nav entry matches its overview row.
    static var opportunitiesIcon: String {
        all.first { $0.title == "Opportunities" }?.icon ?? "lightbulb"
    }

    /// One-line intro shown under each phase overview title.
    static func subtitle(for phase: Phase) -> String {
        switch phase {
        case .define: return "Company & product context — map the terrain (vision, business, org, product, personas) before you plan."
        case .discover: return "The three external signals — market, user research, and data — before you plan."
        case .plan: return "Objectives, strategy, and roadmap — decide what to build and why."
        case .ship: return "Specs and handoff — turn the plan into PRDs and engineering tickets."
        case .daily: return "Recurring PM ops — the daily briefing, the weekly stakeholder update, and an adversarial challenge whenever you need one."
        case .other: return "Markdown under .nanopm/ that doesn't belong to a phase — notes and anything the skills don't own."
        }
    }

    static let all: [SkillDoc] = [
        // MARK: Define
        SkillDoc(
            title: "Vision & Mission",
            blurb: "Mission, vision, values, and company stage — the north star every downstream decision ladders up to.",
            icon: "flag",
            skillCommand: "/pm-vision-mission",
            headlessArgs: nil,
            phase: .define, output: .file("VISION-MISSION.md")
        ),
        SkillDoc(
            title: "Business Model",
            blurb: "How the company makes money — business model, pricing, packaging, and go-to-market motion.",
            icon: "dollarsign.circle",
            skillCommand: "/pm-business-model",
            headlessArgs: nil,
            phase: .define, output: .file("BUSINESS-MODEL.md")
        ),
        SkillDoc(
            title: "Org",
            blurb: "The org map — key roles, teams, and the decision-makers you'll need to align.",
            icon: "person.3",
            skillCommand: "/pm-org",
            headlessArgs: nil,
            phase: .define, output: .file("ORG.md")
        ),
        SkillDoc(
            title: "Product",
            blurb: "Deep product map — surface area, features, core workflows. Reads the code and the public site.",
            icon: "doc.text.magnifyingglass",
            skillCommand: "/pm-product",
            headlessArgs: nil,
            phase: .define, output: .file("PRODUCT.md")
        ),
        SkillDoc(
            title: "Personas",
            blurb: "Who you're building for — JTBD personas and the anti-persona, reverse-engineered from the product.",
            icon: "person.crop.circle",
            skillCommand: "/pm-personas",
            headlessArgs: nil,
            phase: .define, output: .file("PERSONAS.md")
        ),
        // MARK: Discover
        SkillDoc(
            title: "User Feedback",
            blurb: "Aggregated user signal from Dovetail, Productboard, Notion, Linear and GitHub, clustered into themes.",
            icon: "bubble.left.and.bubble.right",
            skillCommand: "/pm-user-feedback",
            headlessArgs: "If no feedback sources are reachable, ask the user (via the interface contract) where their user feedback lives before giving up.",
            phase: .discover, output: .file("FEEDBACK.md")
        ),
        SkillDoc(
            title: "Analytics",
            blurb: "Quantitative findings from PostHog or Amplitude — trends, funnels, retention, paths.",
            icon: "chart.line.uptrend.xyaxis",
            skillCommand: "/pm-data",
            headlessArgs: "Ask the user (via the interface contract) which product question to answer if one is not obvious from prior context.",
            phase: .discover, output: .file("DATA.md")
        ),
        SkillDoc(
            title: "Discovery",
            blurb: "Opportunity space, riskiest assumptions, and the cheapest tests to run before building.",
            icon: "safari",
            skillCommand: "/pm-discovery",
            headlessArgs: nil,
            phase: .discover, output: .file("DISCOVERY.md")
        ),
        SkillDoc(
            title: "Opportunities",
            blurb: "A ranked, agent-maintained database of user opportunities (Teresa Torres) — the problems behind what you build, not the solutions. bootstrap drafts the set from feedback + your assumptions + Nano's hypotheses; add captures one at a time.",
            icon: "lightbulb",
            skillCommand: "/pm-opportunities",
            headlessArgs: "The launch context may carry a structured hint. A line starting with `add:` means capture that one user problem — go straight to add with that text. A line starting with `generate:` (optionally `generate: <N>` or `generate: <N> for theme <theme>`) means run the additive generate mode for that count and optional theme. With no hint, auto-detect: run `bootstrap` if .nanopm/opportunities/SCHEMA.md does not exist, otherwise run `add` and ask the user (via the interface contract) for the user problem to capture.",
            phase: .discover, output: .file("opportunities/INDEX.md")
        ),
        SkillDoc(
            title: "Competitor Intel",
            blurb: "Competitor changelogs, docs, pricing and product updates — snapshotted, diffed against the last run, reported.",
            icon: "binoculars",
            skillCommand: "/pm-competitors-intel",
            headlessArgs: "If .nanopm/competitors.json exists, default to running the intel check on all configured competitors without asking. If it is missing, set it up first by asking the user (via the interface contract) which competitors to monitor and which pages, then write the config and run the check.",
            phase: .discover, output: .file("COMPETITORS.md")
        ),

        // MARK: Planning
        SkillDoc(
            title: "Objectives",
            blurb: "Product objectives and key results (OKRs) with measurable goals and anti-goals.",
            icon: "target",
            skillCommand: "/pm-objectives",
            headlessArgs: nil,
            phase: .plan, output: .file("OBJECTIVES.md")
        ),
        SkillDoc(
            title: "Strategy",
            blurb: "The strategic bet, stress-tested by an adversarial challenge, with the risk named.",
            icon: "flag.checkered",
            skillCommand: "/pm-strategy",
            headlessArgs: nil,
            phase: .plan, output: .file("STRATEGY.md")
        ),
        SkillDoc(
            title: "Roadmap",
            blurb: "An outcome-driven roadmap (Shape Up bets, Scrum sprints, or NOW / NEXT / LATER).",
            icon: "map",
            skillCommand: "/pm-roadmap",
            headlessArgs: nil,
            phase: .plan, output: .file("ROADMAP.md")
        ),

        // MARK: Build
        SkillDoc(
            title: "PRDs",
            blurb: "Full product specs (or Shape Up pitches) for a feature, gated on a falsifiable bet.",
            icon: "doc.text.fill",
            skillCommand: "/pm-prd",
            headlessArgs: "Ask the user (via the interface contract) which feature to spec if it is not obvious from ROADMAP.md.",
            phase: .ship, output: .folder(prefix: "prds/", opens: NavRoute.prdsPage)
        ),
        SkillDoc(
            title: "Breakdown",
            blurb: "Break a PRD into engineering tasks and hand off to Linear, GitHub, OpenSpec, gstack, Symphony, or a markdown file.",
            icon: "checklist",
            skillCommand: "/pm-breakdown",
            headlessArgs: "Ask the user (via the interface contract) which PRD to break down and which handoff target to use before doing the work.",
            phase: .ship, output: .handoff("Hands off to an external tracker — no .nanopm file is produced.")
        ),

        // MARK: Day to Day
        SkillDoc(
            title: "Standup",
            blurb: "Daily briefing — what shipped across your repos, today's meetings, priorities, and drift.",
            icon: "sunrise",
            skillCommand: "/pm-standup",
            headlessArgs: nil,
            phase: .daily, output: .file("STANDUP.md")
        ),
        SkillDoc(
            title: "Weekly Update",
            blurb: "Stakeholder update email — what shipped, what slipped, what changed — adapted to the audience.",
            icon: "envelope",
            skillCommand: "/pm-weekly-update",
            headlessArgs: "Ask the user (via the interface contract) which audience the update is for (manager, CEO, investors, team) if it is not obvious from prior context.",
            phase: .daily, output: .file("WEEKLY_UPDATE.md")
        ),
        SkillDoc(
            title: "Challenge Me",
            blurb: "Three adversarial challenges from a skeptical CPO — strategy, users, focus — starting with the question you're avoiding.",
            icon: "figure.fencing",
            skillCommand: "/pm-challenge-me",
            headlessArgs: nil,
            phase: .daily, output: .file("CHALLENGES.md")
        ),
    ]
}
