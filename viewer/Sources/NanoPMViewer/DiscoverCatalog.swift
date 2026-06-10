import Foundation

/// One canonical Discover-phase document: what it is, where it lands,
/// and — when runnable from the app — the skill that produces it.
struct DiscoverDoc: Identifiable, Hashable {
    /// Path relative to .nanopm/
    let relativePath: String
    let title: String
    let blurb: String
    let icon: String
    /// Slash command that generates this doc, nil when not runnable from the app (yet).
    let skillCommand: String?
    /// Extra instructions appended to the prompt so the skill behaves headlessly.
    let headlessArgs: String?

    var id: String { relativePath }
}

enum DiscoverCatalog {
    static let docs: [DiscoverDoc] = [
        DiscoverDoc(
            relativePath: "FEEDBACK.md",
            title: "User Feedback",
            blurb: "Aggregated user signal from Dovetail, Productboard, Notion, Linear and GitHub, clustered into themes.",
            icon: "bubble.left.and.bubble.right",
            skillCommand: nil,
            headlessArgs: nil
        ),
        DiscoverDoc(
            relativePath: "DATA.md",
            title: "Analytics",
            blurb: "Quantitative findings from PostHog or Amplitude — trends, funnels, retention, paths.",
            icon: "chart.line.uptrend.xyaxis",
            skillCommand: nil,
            headlessArgs: nil
        ),
        DiscoverDoc(
            relativePath: "SCAN.md",
            title: "Codebase Scan",
            blurb: "What the product actually does, reverse-engineered from routes, models, tests and git history.",
            icon: "doc.text.magnifyingglass",
            skillCommand: nil,
            headlessArgs: nil
        ),
        DiscoverDoc(
            relativePath: "AUDIT.md",
            title: "Product Audit",
            blurb: "Brutal honest assessment: what you're building, who it's for, and the question you're avoiding.",
            icon: "stethoscope",
            skillCommand: nil,
            headlessArgs: nil
        ),
        DiscoverDoc(
            relativePath: "DISCOVERY.md",
            title: "Discovery",
            blurb: "Opportunity space, riskiest assumptions, and the cheapest tests to run before building.",
            icon: "safari",
            skillCommand: nil,
            headlessArgs: nil
        ),
        DiscoverDoc(
            relativePath: "COMPETITORS.md",
            title: "Competitor Intel",
            blurb: "Competitor changelogs, docs, pricing and product updates — snapshotted, diffed against the last run, reported.",
            icon: "binoculars",
            skillCommand: "/pm-competitors-intel",
            headlessArgs: "If .nanopm/competitors.json exists, default to running the intel check on all configured competitors without asking. If it is missing, set it up first by asking the user (via the interface contract) which competitors to monitor and which pages, then write the config and run the check."
        ),
    ]
}
