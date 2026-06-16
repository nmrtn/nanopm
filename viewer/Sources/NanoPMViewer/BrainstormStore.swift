import Foundation
import SwiftUI

/// One resumable brainstorm conversation, surfaced in the Brainstorm history.
struct BrainstormSession: Identifiable, Equatable {
    let id: String          // the host (Claude) session id — what `--resume` takes
    let title: String       // host ai-title, or a fallback label
    let lastActivity: Date
}

/// Cross-launch persistence + discovery for brainstorm conversations.
///
/// The viewer can't tell, from the host session store alone, which Claude
/// sessions in a project were brainstorms vs. other work — so we remember the
/// session ids the viewer itself launched (in UserDefaults, scoped per project)
/// and enrich each from the host's own JSONL: Claude auto-writes an `ai-title`
/// record per session, which is the free auto-naming source (no title generation
/// of our own). Resume is delegated to the host via `claude --resume <id>` in
/// RunManager — this store only scopes and labels the list.
@MainActor
final class BrainstormStore: ObservableObject {
    let projectPath: String
    @Published private(set) var sessions: [BrainstormSession] = []

    private let maxRemembered = 40
    private var defaultsKey: String { "brainstormSessions:" + projectPath }

    init(projectPath: String) {
        self.projectPath = projectPath
        reload()
    }

    /// Record a session id the viewer launched (newest first, deduped, capped),
    /// then refresh the labelled list.
    func remember(_ sessionID: String) {
        let trimmed = sessionID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var ids = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        ids.removeAll { $0 == trimmed }
        ids.insert(trimmed, at: 0)
        ids = Array(ids.prefix(maxRemembered))
        UserDefaults.standard.set(ids, forKey: defaultsKey)
        reload()
    }

    /// Rebuild the list from remembered ids, dropping any whose host session
    /// file has gone (e.g. expired past Claude's retention window).
    func reload() {
        let ids = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        let dir = Self.claudeProjectDir(for: projectPath)
        let found: [BrainstormSession] = ids.compactMap { id in
            let url = URL(fileURLWithPath: "\(dir)/\(id).jsonl")
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let modified = attrs[.modificationDate] as? Date else { return nil }
            let title = Self.readTitle(url) ?? "Untitled jam"
            return BrainstormSession(id: id, title: title, lastActivity: modified)
        }
        sessions = found.sorted { $0.lastActivity > $1.lastActivity }
    }

    // MARK: - Host session store

    /// `~/.claude/projects/<encoded-cwd>` — Claude encodes the working directory
    /// by replacing every non-alphanumeric character with `-` (e.g.
    /// `/Users/me/proj` → `-Users-me-proj`). Case is preserved; dashes are not
    /// collapsed (1:1 per character).
    nonisolated static func claudeProjectDir(for projectPath: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let encoded = String(projectPath.map { c in
            (c.isASCII && (c.isLetter || c.isNumber)) ? c : "-"
        })
        return "\(home)/.claude/projects/\(encoded)"
    }

    /// Last `ai-title` record in a session's JSONL — Claude's own auto-title.
    /// Returns nil if the file is unreadable or has no title yet (~rare; the
    /// caller falls back to a generic label).
    nonisolated static func readTitle(_ url: URL) -> String? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        var title: String?
        content.enumerateLines { line, _ in
            guard let data = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["type"] as? String == "ai-title",
                  let t = obj["aiTitle"] as? String,
                  !t.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            title = t   // keep the last one
        }
        return title
    }
}
