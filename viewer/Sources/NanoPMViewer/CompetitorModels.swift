import Foundation

/// One entry of .nanopm/competitors.json (written by /pm-competitors-intel).
struct Competitor: Identifiable, Hashable, Codable, Sendable {
    struct Pages: Hashable, Codable, Sendable {
        var changelog: String?
        var apiDocs: String?
        var pricing: String?
        var other: String?
    }

    var name: String
    var slug: String
    var pages: Pages
    var lastChecked: String?

    var id: String { slug }

    var lastCheckedDate: Date? {
        guard let lastChecked else { return nil }
        return ISO8601DateFormatter().date(from: lastChecked)
    }

    /// Monitored pages in display order, nils skipped.
    var monitoredPages: [(title: String, url: URL)] {
        [("Changelog", pages.changelog),
         ("API Docs", pages.apiDocs),
         ("Pricing", pages.pricing),
         ("Site", pages.other)]
            .compactMap { title, raw in
                guard let raw, let url = URL(string: raw) else { return nil }
                return (title, url)
            }
    }
}

enum CompetitorFiles {
    /// The competitor landscape report — the wiki-canonical page, with the legacy
    /// flat path as a fallback for un-migrated projects. (pm-competitors-intel writes
    /// wiki/docs/competitors.md under wiki-canonical writes.)
    static let reportPaths = ["wiki/docs/competitors.md", "COMPETITORS.md"]
    static func isLandscape(_ relativePath: String) -> Bool {
        reportPaths.contains(relativePath)
    }

    /// True for artifacts owned by the Competitors nav section (hidden from
    /// the generic phase lists when that section is visible).
    static func isCompetitorFile(_ relativePath: String) -> Bool {
        isLandscape(relativePath)
            || relativePath == "raw/competitors/competitors.json" || relativePath == "competitors.json"
            || relativePath.hasPrefix("raw/competitors/")
    }

    static func isReport(_ relativePath: String) -> Bool {
        isLandscape(relativePath)
            || (relativePath.hasPrefix("raw/competitors/INTEL-") && relativePath.hasSuffix(".md"))
    }

    static func reportTitle(_ relativePath: String) -> String {
        if isLandscape(relativePath) { return "Latest Report" }
        let base = (((relativePath as NSString).lastPathComponent) as NSString).deletingPathExtension
        return base.replacingOccurrences(of: "INTEL-", with: "Report ")
    }

    /// "raw/competitors/snapshots/<slug>/<page>.md" → page key, e.g. "changelog"
    static func snapshotPage(_ relativePath: String) -> String? {
        let parts = relativePath.split(separator: "/")
        guard parts.count == 5, parts[0] == "raw", parts[1] == "competitors", parts[2] == "snapshots" else { return nil }
        return (String(parts[4]) as NSString).deletingPathExtension
    }

    static let pageOrder = ["changelog", "api_docs", "pricing", "other"]

    static func pageTitle(_ key: String) -> String {
        switch key {
        case "changelog": return "Changelog"
        case "api_docs": return "API Docs"
        case "pricing": return "Pricing"
        case "other": return "Site"
        default: return key.capitalized
        }
    }
}
