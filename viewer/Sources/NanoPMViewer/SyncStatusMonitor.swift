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
    @Published var isSyncing = false
    @Published var pullPending: Int = 0
    private var lastProjectPath = ""

    func check(projectPath: String) async {
        lastProjectPath = projectPath
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
        status = Self.parseLocalStatus(output)
    }

    /// Check how many Supabase pages are newer than local (metadata-only network call).
    func checkRemote() async {
        guard !lastProjectPath.isEmpty else { return }
        let agentPath = NSHomeDirectory() + "/.nanopm/bin/nanopm-ingest-agent"
        let cmd = "\(ShellRunner.quote(agentPath)) --project \(ShellRunner.quote(lastProjectPath)) remote-status 2>/dev/null"
        guard let output = try? await ShellRunner.runAsync(cmd) else { return }
        // Parse "remote status: N page(s) to pull"
        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("remote status:") {
                let n = line.components(separatedBy: ": ").dropFirst().joined(separator: ": ")
                    .components(separatedBy: " ").first.flatMap(Int.init) ?? 0
                pullPending = n
                return
            }
        }
    }

    /// Push pending local changes then pull remote changes, then refresh both badges.
    /// Push runs first so local edits win on any same-file conflict.
    func pushAndPull() async {
        guard !isSyncing, !lastProjectPath.isEmpty else { return }
        isSyncing = true
        // Capture path before first suspension point — polling loop can mutate
        // lastProjectPath while we're awaiting, causing post-sync checks to target
        // the wrong project.
        let projectPath = lastProjectPath
        let agent = ShellRunner.quote(NSHomeDirectory() + "/.nanopm/bin/nanopm-ingest-agent")
        let proj  = ShellRunner.quote(projectPath)
        _ = try? await ShellRunner.runAsync("\(agent) --project \(proj) push-pending 2>/dev/null")
        _ = try? await ShellRunner.runAsync("\(agent) --project \(proj) pull 2>/dev/null")
        isSyncing = false
        async let localCheck: () = check(projectPath: projectPath)
        async let remoteCheck: () = checkRemote()
        _ = await (localCheck, remoteCheck)
    }

    /// Convenience — existing call sites that only needed push now get push+pull.
    func push() async { await pushAndPull() }

    // Parse "sync status: N in sync · M modified locally · K never synced"
    // and "raw sync status: …" — both sections use the same middle-dot format.
    private static func parseLocalStatus(_ output: String) -> Status {
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

    private var pushCount: Int {
        if case .pending(let w, let r) = monitor.status { return w + r }
        return 0
    }
    private var pullCount: Int { monitor.pullPending }
    private var isClean: Bool {
        if case .clean = monitor.status { return pullCount == 0 }
        return false
    }

    var body: some View {
        if monitor.status == .idle || monitor.status == .notConfigured {
            EmptyView()
        } else if monitor.isSyncing {
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("Syncing…").font(.caption).foregroundStyle(Color.npAmber)
            }
        } else if isClean {
            HStack(spacing: 4) {
                Circle().fill(Color.npOlive).frame(width: 6, height: 6)
                Text("In sync").font(.caption).foregroundStyle(.secondary)
            }
            .help("All content backed up to Supabase")
        } else {
            Button { Task { await monitor.pushAndPull() } } label: {
                HStack(spacing: 4) {
                    if pushCount > 0 {
                        Circle().fill(Color.npAmber).frame(width: 6, height: 6)
                    } else {
                        Circle().fill(Color.blue).frame(width: 6, height: 6)
                    }
                    Text(badgeLabel).font(.caption).foregroundStyle(badgeTint)
                }
            }
            .buttonStyle(.plain)
            .help(badgeHelp)
        }
    }

    private var badgeLabel: String {
        switch (pushCount, pullCount) {
        case (let p, let r) where p > 0 && r > 0: return "\(p) to sync · \(r) to pull"
        case (let p, _) where p > 0:              return "\(p) to sync"
        default:                                   return "\(pullCount) to pull"
        }
    }

    private var badgeTint: Color {
        pushCount > 0 ? Color.npAmber : .blue
    }

    private var badgeHelp: String {
        switch (pushCount, pullCount) {
        case (let p, let r) where p > 0 && r > 0:
            return "\(p) local change(s) to push and \(r) remote page(s) to pull — click to sync"
        case (let p, _) where p > 0:
            return "\(p) local change(s) not yet pushed — click to push now"
        default:
            return "\(pullCount) remote page(s) newer than local — click to pull now"
        }
    }
}

extension SyncStatusMonitor.Status: Equatable {
    static func == (lhs: SyncStatusMonitor.Status, rhs: SyncStatusMonitor.Status) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.clean, .clean), (.notConfigured, .notConfigured): return true
        case (.pending(let lw, let lr), .pending(let rw, let rr)): return lw == rw && lr == rr
        default: return false
        }
    }
}
