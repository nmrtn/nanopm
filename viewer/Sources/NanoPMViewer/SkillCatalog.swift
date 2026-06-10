import Foundation

/// Stable nav-route identifiers shared between the catalog and ProjectView.
enum NavRoute {
    static let prdsPage = "page:prds"
    static let competitorsPage = "page:competitors"
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

    /// Icon for the skill that produces this artifact, so the sidebar matches
    /// the overview pages. Nil when no catalog skill owns the path.
    static func icon(forArtifact relativePath: String) -> String? {
        all.first { doc in
            if case .file(let path) = doc.output { return path == relativePath }
            return false
        }?.icon
    }

    /// The PRDs folder skill icon, so the nav folder matches its overview row.
    static var prdsIcon: String {
        all.first { $0.title == "PRDs" }?.icon ?? "folder"
    }

    /// One-line intro shown under each phase overview title.
    static func subtitle(for phase: Phase) -> String {
        switch phase {
        case .discover: return "Signal, research & audits — what's true about your users and your product, before you plan."
        case .plan: return "Objectives, strategy, and roadmap — decide what to build and why."
        case .ship: return "Specs and handoff — turn the plan into PRDs and engineering tickets."
        case .other: return ""
        }
    }

    static let all: [SkillDoc] = [
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
            title: "Codebase Scan",
            blurb: "What the product actually does, reverse-engineered from routes, models, tests and git history.",
            icon: "doc.text.magnifyingglass",
            skillCommand: "/pm-scan",
            headlessArgs: nil,
            phase: .discover, output: .file("SCAN.md")
        ),
        SkillDoc(
            title: "Product Audit",
            blurb: "Brutal honest assessment: what you're building, who it's for, and the question you're avoiding.",
            icon: "stethoscope",
            skillCommand: "/pm-audit",
            headlessArgs: nil,
            phase: .discover, output: .file("AUDIT.md")
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
    ]
}
