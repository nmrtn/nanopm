import Foundation

enum Phase: String, CaseIterable, Identifiable, Sendable {
    case discover = "Discover"
    case plan = "Plan"
    case ship = "Ship"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .discover: return "magnifyingglass"
        case .plan: return "map"
        case .ship: return "shippingbox"
        case .other: return "tray"
        }
    }

    var order: Int { Phase.allCases.firstIndex(of: self) ?? 0 }
}

struct Project: Identifiable, Hashable, Sendable {
    let path: String

    var id: String { path }
    var name: String { (path as NSString).lastPathComponent }
    var nanopmPath: String { path + "/.nanopm" }
}

struct Artifact: Identifiable, Hashable, Sendable {
    /// Path relative to .nanopm/
    let relativePath: String
    let phase: Phase
    let modifiedAt: Date

    var id: String { relativePath }
    var fileName: String { (relativePath as NSString).lastPathComponent }
    var isMarkdown: Bool { relativePath.lowercased().hasSuffix(".md") }

    var displayName: String { prettyDocName(relativePath) }
}

/// "STRATEGY.md" → "Strategy", "prds/foo-bar.md" → "foo-bar"
func prettyDocName(_ relativePath: String) -> String {
    let file = (relativePath as NSString).lastPathComponent
    var base = (file as NSString).deletingPathExtension
    if base == base.uppercased() { base = base.capitalized }
    return base
}

/// Fixed artifact → phase mapping (PRD: files that match no rule land in a
/// visible "Other" bucket rather than being hidden).
enum PhaseMapper {
    private static let discoverNames = ["feedback", "data", "scan", "audit", "discovery", "interview", "competitor"]
    private static let planNames = ["objectives", "strategy", "roadmap", "prd"]
    private static let shipNames = ["breakdown", "handoff", "retro", "standup", "weekly", "update", "tasks"]

    static func phase(for relativePath: String) -> Phase {
        let lower = relativePath.lowercased()
        let file = (lower as NSString).lastPathComponent

        if lower.hasPrefix("prds/") { return .plan }
        if lower.hasPrefix("interviews/") || lower.hasPrefix("competitors/") { return .discover }
        if lower.hasPrefix("breakdowns/") || lower.hasPrefix("handoffs/") { return .ship }

        if discoverNames.contains(where: { file.hasPrefix($0) }) { return .discover }
        if planNames.contains(where: { file.hasPrefix($0) }) { return .plan }
        if shipNames.contains(where: { file.hasPrefix($0) }) { return .ship }
        return .other
    }
}
