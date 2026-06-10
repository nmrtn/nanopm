import Foundation
import SwiftUI
import UserNotifications

/// Launches nanopm skills headlessly through the `claude` CLI in a background
/// process — terminal commands, not an API — and tracks their lifecycle.
@MainActor
final class RunManager: ObservableObject {
    struct SkillRun: Identifiable {
        let id = UUID()
        let projectPath: String
        let skillCommand: String
        /// The artifact this run is expected to produce, relative to .nanopm/
        let expectedRelPath: String
        let startedAt = Date()
        var status: Status = .running

        enum Status: Equatable {
            case running
            case succeeded
            case failed(String)
        }
    }

    @Published private(set) var runs: [SkillRun] = []
    /// Bumped each time a run finishes — views watch this to refresh artifact lists.
    @Published private(set) var completionTick = 0

    private var processes: [UUID: Process] = [:]

    func runs(in projectPath: String) -> [SkillRun] {
        runs.filter { $0.projectPath == projectPath }
    }

    func latestRun(for relPath: String, in projectPath: String) -> SkillRun? {
        runs.last { $0.projectPath == projectPath && $0.expectedRelPath == relPath }
    }

    func isRunning(_ relPath: String, in projectPath: String) -> Bool {
        latestRun(for: relPath, in: projectPath)?.status == .running
    }

    func launch(_ doc: DiscoverDoc, in projectPath: String) {
        guard let skillCommand = doc.skillCommand,
              !isRunning(doc.relativePath, in: projectPath) else { return }

        Notifier.requestAuthorizationIfNeeded()

        let run = SkillRun(projectPath: projectPath,
                           skillCommand: skillCommand,
                           expectedRelPath: doc.relativePath)
        runs.append(run)

        let prompt = [skillCommand, doc.headlessArgs].compactMap { $0 }.joined(separator: " ")
        // zsh -l loads the user's PATH so the `claude` CLI resolves when the
        // app is launched from Finder.
        let shellCommand = "cd \(ShellRunner.quote(projectPath)) && claude --permission-mode bypassPermissions -p \(ShellRunner.quote(prompt)) </dev/null 2>&1"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", shellCommand]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            processes[run.id] = process
        } catch {
            finish(run.id, exitCode: -1, output: "\(error)")
            return
        }

        // Drain the pipe off the main actor (prevents the child blocking on a
        // full pipe buffer), then report termination back.
        Task.detached(priority: .utility) { [weak self] in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(data: data, encoding: .utf8) ?? ""
            let code = process.terminationStatus
            await self?.finish(run.id, exitCode: code, output: output)
        }
    }

    private func finish(_ id: UUID, exitCode: Int32, output: String) {
        guard let index = runs.firstIndex(where: { $0.id == id }) else { return }
        processes[id] = nil
        let run = runs[index]
        if exitCode == 0 {
            runs[index].status = .succeeded
            Notifier.send(
                title: "\(run.expectedRelPath) is ready",
                body: "\(run.skillCommand) finished — open NanoPM Viewer to read it."
            )
        } else {
            let tail = output.split(separator: "\n").suffix(4).joined(separator: " · ")
            runs[index].status = .failed(String(tail.prefix(400)))
            Notifier.send(
                title: "\(run.skillCommand) failed",
                body: String("Exit \(exitCode). \(tail)".prefix(160))
            )
        }
        completionTick += 1
    }
}

/// macOS notifications, with an AppleScript fallback when UserNotifications
/// authorization is unavailable (e.g. denied, or ad-hoc-signed quirks).
enum Notifier {
    private static var authRequested = false

    static func requestAuthorizationIfNeeded() {
        guard !authRequested else { return }
        authRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func send(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                center.add(UNNotificationRequest(identifier: UUID().uuidString,
                                                 content: content, trigger: nil))
            default:
                sendViaAppleScript(title: title, body: body)
            }
        }
    }

    private static func sendViaAppleScript(title: String, body: String) {
        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
        }
        let script = "display notification \"\(esc(body))\" with title \"\(esc(title))\""
        _ = try? ShellRunner.run("osascript -e \(ShellRunner.quote(script))")
    }
}
