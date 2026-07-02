import Foundation
import SwiftUI

@MainActor
final class SyncStatusMonitor: ObservableObject {

    enum Status {
        case idle
        case clean
        case pending(wiki: Int, raw: Int)
        case notConfigured
    }

    @Published var status: Status = .idle

    func check(projectPath: String) async {
        let home = NSHomeDirectory()
        let envPath = home + "/.nanopm/.env"
        guard FileManager.default.fileExists(atPath: envPath) else {
            status = .notConfigured
            return
        }
        let agentPath = home + "/.nanopm/bin/nanopm-ingest-agent"
        let quoted = ShellRunner.quote(projectPath)
        let cmd = "\(ShellRunner.quote(agentPath)) --project \(quoted) status 2>/dev/null"
        guard let output = try? await ShellRunner.runAsync(cmd) else { return }
        status = Self.parse(output)
    }

    // Parse "sync status: N in sync · M modified locally · K never synced"
    // and "raw sync status: …" — both sections use the same middle-dot format.
    private static func parse(_ output: String) -> Status {
        var wikiPending = 0
        var rawPending  = 0
        for line in output.components(separatedBy: "\n") {
            guard line.contains("in sync ·") else { continue }
            let parts = line.components(separatedBy: "·")
            let mod   = parts.count > 1
                ? Int(parts[1].trimmingCharacters(in: .letters.union(.whitespaces))) ?? 0 : 0
            let never = parts.count > 2
                ? Int(parts[2].trimmingCharacters(in: .letters.union(.whitespaces))) ?? 0 : 0
            if line.hasPrefix("raw") { rawPending  = mod + never }
            else                     { wikiPending = mod + never }
        }
        let total = wikiPending + rawPending
        return total == 0 ? .clean : .pending(wiki: wikiPending, raw: rawPending)
    }
}

struct SyncStatusBadge: View {
    @ObservedObject var monitor: SyncStatusMonitor

    var body: some View {
        switch monitor.status {
        case .idle, .notConfigured:
            EmptyView()
        case .clean:
            HStack(spacing: 4) {
                Circle().fill(Color.npOlive).frame(width: 6, height: 6)
                Text("In sync").font(.caption).foregroundStyle(.secondary)
            }
            .help("All content backed up to Supabase")
        case .pending(let wiki, let raw):
            HStack(spacing: 4) {
                Circle().fill(Color.npAmber).frame(width: 6, height: 6)
                Text("\(wiki + raw) to sync").font(.caption).foregroundStyle(Color.npAmber)
            }
            .help(pendingHelp(wiki: wiki, raw: raw))
        }
    }

    private func pendingHelp(wiki: Int, raw: Int) -> String {
        var parts: [String] = []
        if wiki > 0 { parts.append("\(wiki) wiki file(s)") }
        if raw  > 0 { parts.append("\(raw) raw file(s)") }
        return "\(parts.joined(separator: " and ")) not yet pushed — run a skill or `sync` to push"
    }
}
