import Foundation
import SwiftUI
import UserNotifications

/// A question the model asks mid-run, mirrored from the `nanopm-question`
/// protocol block (same shape as AskUserQuestion, which is unavailable headless).
struct UserQuestion: Identifiable, Equatable, Codable {
    struct Option: Equatable, Codable, Hashable {
        var label: String
        var description: String?
    }

    var question: String
    var header: String?
    var multiSelect: Bool?
    var options: [Option]?

    var id: String { question }
    var isMultiSelect: Bool { multiSelect ?? false }
    var choices: [Option] { options ?? [] }
}

/// Launches nanopm skills through the `claude` CLI in background processes —
/// terminal commands, not an API — and drives a multi-turn session: when the
/// model needs input it emits a `nanopm-question` block and stops; the app
/// collects answers and resumes the same session (`claude --resume`).
@MainActor
final class RunManager: ObservableObject {
    struct TranscriptEntry: Identifiable, Equatable {
        enum Role { case model, user }
        let id = UUID()
        let role: Role
        let text: String
    }

    struct SkillRun: Identifiable {
        let id = UUID()
        let projectPath: String
        let skillCommand: String
        /// The artifact this run is expected to produce, relative to .nanopm/
        let expectedRelPath: String
        let startedAt = Date()
        var sessionID: String?
        var status: Status = .running
        var transcript: [TranscriptEntry] = []

        enum Status: Equatable {
            case running
            case waitingForInput([UserQuestion])
            case succeeded
            case failed(String)
        }

        var isActive: Bool {
            switch status {
            case .running, .waitingForInput: return true
            case .succeeded, .failed: return false
            }
        }

        var pendingQuestions: [UserQuestion] {
            if case .waitingForInput(let questions) = status { return questions }
            return []
        }
    }

    @Published private(set) var runs: [SkillRun] = []
    /// Bumped each time a run finishes — views watch this to refresh artifact lists.
    @Published private(set) var completionTick = 0

    private var processes: [UUID: Process] = [:]

    /// Appended to every initial prompt so skills work without interactive tools.
    static let interfaceContract = """
    INTERFACE CONTRACT — you are running headlessly behind the NanoPM Viewer GUI. \
    Interactive tools such as AskUserQuestion are NOT available; never call them. \
    When you need user input (choices or free text), end your reply with exactly one \
    fenced code block tagged nanopm-question containing JSON of this exact shape: \
    {"questions":[{"question":"<full question>","header":"<short label>","multiSelect":false,"options":[{"label":"<choice>","description":"<what it means>"}]}]} \
    Use an empty options array for free-text questions. Ask at most 2 questions per \
    block, then STOP your turn — the user's answers arrive in the next user message. \
    Never repeat a question that was already answered. When the document is finished \
    and written to disk, do NOT emit a nanopm-question block — summarize what you \
    created instead.
    """

    func runs(in projectPath: String) -> [SkillRun] {
        runs.filter { $0.projectPath == projectPath }
    }

    func latestRun(for relPath: String, in projectPath: String) -> SkillRun? {
        runs.last { $0.projectPath == projectPath && $0.expectedRelPath == relPath }
    }

    func isActive(_ relPath: String, in projectPath: String) -> Bool {
        latestRun(for: relPath, in: projectPath)?.isActive ?? false
    }

    func launch(_ doc: DiscoverDoc, in projectPath: String) {
        guard let skillCommand = doc.skillCommand,
              !isActive(doc.relativePath, in: projectPath) else { return }

        Notifier.requestAuthorizationIfNeeded()

        let run = SkillRun(projectPath: projectPath,
                           skillCommand: skillCommand,
                           expectedRelPath: doc.relativePath)
        runs.append(run)

        let prompt = [skillCommand, doc.headlessArgs, Self.interfaceContract]
            .compactMap { $0 }
            .joined(separator: "\n\n")
        startTurn(run.id, prompt: prompt, resumeSession: nil)
    }

    /// Resume a waiting run with the user's composed answers.
    func submitAnswers(_ runID: UUID, _ answerText: String) {
        guard let index = runs.firstIndex(where: { $0.id == runID }),
              case .waitingForInput = runs[index].status else { return }
        runs[index].transcript.append(TranscriptEntry(role: .user, text: answerText))
        runs[index].status = .running
        startTurn(runID, prompt: answerText, resumeSession: runs[index].sessionID)
    }

    func cancel(_ runID: UUID) {
        guard let index = runs.firstIndex(where: { $0.id == runID }),
              runs[index].isActive else { return }
        runs[index].status = .failed("Cancelled by user")
        completionTick += 1
        processes[runID]?.terminate()
        processes[runID] = nil
    }

    // MARK: - Turn lifecycle

    private func startTurn(_ runID: UUID, prompt: String, resumeSession: String?) {
        guard let index = runs.firstIndex(where: { $0.id == runID }) else { return }
        let projectPath = runs[index].projectPath

        var cli = "claude --permission-mode bypassPermissions --output-format json"
        if let resumeSession {
            cli += " --resume \(ShellRunner.quote(resumeSession))"
        }
        cli += " -p \(ShellRunner.quote(prompt)) </dev/null"
        // zsh -l loads the user's PATH so the `claude` CLI resolves when the
        // app is launched from Finder.
        let shellCommand = "cd \(ShellRunner.quote(projectPath)) && \(cli)"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", shellCommand]
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            processes[runID] = process
        } catch {
            applyFailure(runID, message: "\(error)")
            return
        }

        // Drain pipes off the main actor (prevents the child blocking on a
        // full pipe buffer), then report the turn result back.
        Task.detached(priority: .utility) { [weak self] in
            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let code = process.terminationStatus
            await self?.finishTurn(runID, exitCode: code, stdout: outData, stderr: errData)
        }
    }

    private func finishTurn(_ runID: UUID, exitCode: Int32, stdout: Data, stderr: Data) {
        guard let index = runs.firstIndex(where: { $0.id == runID }) else { return }
        // Cancelled (or otherwise resolved) while the process was draining.
        guard runs[index].status == .running else { return }
        processes[runID] = nil
        let run = runs[index]

        guard let parsed = Self.parseCLIOutput(stdout) else {
            let err = String(data: stderr, encoding: .utf8) ?? ""
            let out = String(data: stdout, encoding: .utf8) ?? ""
            let detail = (err.isEmpty ? out : err).trimmingCharacters(in: .whitespacesAndNewlines)
            applyFailure(runID, message: detail.isEmpty
                         ? "claude exited \(exitCode) with no parseable output"
                         : String(detail.suffix(400)))
            return
        }

        if let sessionID = parsed.sessionID {
            runs[index].sessionID = sessionID
        }
        let questions = Self.extractQuestions(from: parsed.text)
        let visibleText = Self.stripQuestionBlock(from: parsed.text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !visibleText.isEmpty {
            runs[index].transcript.append(TranscriptEntry(role: .model, text: visibleText))
        }

        if parsed.isError || exitCode != 0 {
            applyFailure(runID, message: visibleText.isEmpty
                         ? "claude exited \(exitCode)"
                         : String(visibleText.suffix(400)))
        } else if !questions.isEmpty {
            runs[index].status = .waitingForInput(questions)
            Notifier.send(
                title: "\(run.skillCommand) needs your input",
                body: questions.first?.question ?? "Answer in NanoPM Viewer to continue."
            )
        } else {
            runs[index].status = .succeeded
            completionTick += 1
            Notifier.send(
                title: "\(run.expectedRelPath) is ready",
                body: "\(run.skillCommand) finished — open NanoPM Viewer to read it."
            )
        }
    }

    private func applyFailure(_ runID: UUID, message: String) {
        guard let index = runs.firstIndex(where: { $0.id == runID }) else { return }
        processes[runID] = nil
        runs[index].status = .failed(message)
        completionTick += 1
        Notifier.send(title: "\(runs[index].skillCommand) failed",
                      body: String(message.prefix(160)))
    }

    // MARK: - CLI output parsing

    struct CLIResult {
        let text: String
        let sessionID: String?
        let isError: Bool
    }

    /// `claude -p --output-format json` prints one JSON object. A login shell
    /// profile may print noise before it, so parse from the first `{`.
    static func parseCLIOutput(_ data: Data) -> CLIResult? {
        guard var text = String(data: data, encoding: .utf8) else { return nil }
        if let brace = text.firstIndex(of: "{") {
            text = String(text[brace...])
        }
        guard let jsonData = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return nil }
        return CLIResult(
            text: object["result"] as? String ?? "",
            sessionID: object["session_id"] as? String,
            isError: object["is_error"] as? Bool ?? false
        )
    }

    private static let questionFence = "```nanopm-question"

    static func extractQuestions(from text: String) -> [UserQuestion] {
        guard let start = text.range(of: questionFence) else { return [] }
        let after = text[start.upperBound...]
        guard let end = after.range(of: "```") else { return [] }
        let json = String(after[..<end.lowerBound])
        struct Block: Codable { var questions: [UserQuestion] }
        guard let data = json.data(using: .utf8),
              let block = try? JSONDecoder().decode(Block.self, from: data)
        else { return [] }
        return block.questions
    }

    static func stripQuestionBlock(from text: String) -> String {
        guard let start = text.range(of: questionFence) else { return text }
        let after = text[start.upperBound...]
        guard let end = after.range(of: "```") else {
            return String(text[..<start.lowerBound])
        }
        return String(text[..<start.lowerBound]) + String(after[end.upperBound...])
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
