import Foundation
import SwiftUI

/// Surfaces nanopm skill-pack updates inside the viewer and applies them with
/// one click — the GUI mirror of the CLI's `nanopm_update_check` + `/pm-upgrade`.
///
/// Detection delegates to the shared bash runtime (`nanopm_update_check`) so the
/// viewer and the terminal never disagree about whether an update exists. The
/// upgrade re-runs the published `setup` from `main`, exactly as `/pm-upgrade`
/// does for non-repo installs. A maintainer guard refuses to run when this is a
/// local clone install, so Guillaume/Nicolas never overwrite their working copy.
@MainActor
final class UpdateChecker: ObservableObject {
    enum Phase: Equatable {
        case idle                       // no update, or check not yet run
        case available                  // a newer version exists
        case updating                   // upgrade in flight
        case updated                    // upgrade succeeded
        case failed(String)             // upgrade failed — message for the banner
        case blockedDevInstall(String)  // maintainer guard tripped — names the clone path
    }

    @Published private(set) var phase: Phase = .idle
    /// Versions parsed from `UPGRADE_AVAILABLE {local} {remote}`.
    @Published private(set) var localVersion = ""
    @Published private(set) var remoteVersion = ""
    /// Dismissed for this launch — suppresses the banner until next launch.
    @Published private(set) var dismissed = false

    private static let setupURL = "https://raw.githubusercontent.com/nmrtn/nanopm/main/setup"
    /// Terminal fallback shown when the in-app update can't run.
    static var fallbackCommand: String { "curl -fsSL \(setupURL) | bash" }

    /// True when the banner should be on screen.
    var showBanner: Bool {
        guard !dismissed else { return false }
        if case .idle = phase { return false }
        return true
    }

    /// Run the shared update check. Fail-silent: any error or no-update leaves us
    /// idle, so a flaky network never nags the user (matches the CLI's behaviour).
    /// Async and called off the launch path, so it never delays the window.
    func check() async {
        guard phase == .idle else { return }
        let script = "source \"$HOME/.nanopm/lib/nanopm.sh\" 2>/dev/null && nanopm_update_check"
        guard let out = try? await ShellRunner.runAsync(script),
              let parsed = Self.parse(out) else { return }
        localVersion = parsed.local
        remoteVersion = parsed.remote
        phase = .available
    }

    /// Apply the update: guard against dev installs first, then re-run setup.
    func update() async {
        if let clonePath = devInstallPath() {
            phase = .blockedDevInstall(clonePath)
            return
        }
        // Don't let a double-click or a Retry-mid-run launch two concurrent
        // setups writing the same ~/.nanopm tree.
        guard phase != .updating else { return }
        let previous = localVersion
        phase = .updating
        do {
            // `pipefail` so a failed curl (no network, DNS, HTTP error) propagates
            // instead of being masked by bash's exit code at the tail of the pipe.
            _ = try await ShellRunner.runAsync("set -o pipefail; curl -fsSL \(Self.setupURL) | bash")
            // setup rewrites ~/.nanopm/VERSION on success. If it's unchanged (or
            // empty), nothing actually installed — don't claim success.
            guard let installed = Self.readInstalledVersion(), installed != previous else {
                phase = .failed("Update didn't complete. Run `\(Self.fallbackCommand)` in a terminal.")
                return
            }
            remoteVersion = installed
            phase = .updated
        } catch {
            phase = .failed("Couldn't update. Run `\(Self.fallbackCommand)` in a terminal.")
        }
    }

    /// The currently installed version from `~/.nanopm/VERSION`, or nil if absent
    /// or empty. Read directly (no subprocess), consistent with `devInstallPath`.
    private static func readInstalledVersion() -> String? {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent(".nanopm/VERSION")
        guard let raw = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        let version = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return version.isEmpty ? nil : version
    }

    func dismiss() { dismissed = true }

    /// Provenance marker written by `setup`. Returns the clone path when this is
    /// a dev install (so the upgrade must be refused), or nil for `remote` /
    /// absent (a normal end-user install — absent defaults to remote so
    /// pre-existing installs aren't falsely flagged).
    private func devInstallPath() -> String? {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent(".nanopm/install-source")
        guard let raw = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        let source = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty, source != "remote" else { return nil }
        // Only treat as a dev install if the clone still exists. A stale marker
        // pointing at a moved/deleted clone must not block updates forever — if
        // the working copy is gone, this machine is effectively an end user.
        guard FileManager.default.fileExists(atPath: source + "/lib/nanopm.sh") else { return nil }
        return source
    }

    /// Parse `UPGRADE_AVAILABLE {local} {remote}` from the check output. Scans
    /// every line so any incidental shell output is ignored. `nonisolated` —
    /// it's pure, so it's callable off the main actor (e.g. the smoke test).
    nonisolated static func parse(_ output: String) -> (local: String, remote: String)? {
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: " ")
            if parts.count == 3, parts[0] == "UPGRADE_AVAILABLE" {
                return (String(parts[1]), String(parts[2]))
            }
        }
        return nil
    }
}
