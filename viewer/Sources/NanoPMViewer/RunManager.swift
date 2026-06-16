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

    /// One streamed event from `claude --output-format stream-json` — the unit
    /// of the live debug console.
    struct LogEvent: Identifiable, Equatable {
        enum Kind: String {
            case session, assistant, toolUse, toolResult, summary, result, error, user
        }
        let id = UUID()
        let at = Date()
        /// Which turn (1-based) this event belongs to — runs can span turns.
        let turn: Int
        let kind: Kind
        /// Short headline, e.g. "Bash" or "Session started".
        let title: String
        /// Optional body (tool input, tool output, assistant text…).
        let detail: String?
        var sessionID: String?

        var icon: String {
            switch kind {
            case .session: return "bolt.horizontal.circle"
            case .assistant: return "sparkle"
            case .toolUse: return "wrench.and.screwdriver"
            case .toolResult: return "arrow.turn.down.right"
            case .summary: return "text.append"
            case .result: return "checkmark.seal"
            case .error: return "exclamationmark.triangle"
            case .user: return "person"
            }
        }
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
        /// Live event log streamed from the CLI — drives the activity monitor.
        var events: [LogEvent] = []
        /// 1-based count of turns started (initial launch + each resume).
        var turnCount = 0

        /// Skill runs produce an artifact behind the question-contract; brainstorm
        /// runs are free-form CPO jams with a conversational preamble and a reduced
        /// read-only tool allow-list. Drives prompt assembly and the allow-list.
        var kind: Kind = .skill
        /// Display title for a brainstorm conversation (host ai-title / topic).
        var title: String?
        /// Per-run tool allow-list, read by startTurn when building the CLI.
        /// Skill runs get the full set; brainstorm runs a reduced read-only one.
        var allowedTools: String = RunManager.allowedTools
        /// Tools to hard-deny via `--disallowedTools` — the only real gate (see
        /// the brainstorm-posture note). nil for skill runs; set for brainstorm.
        var disallowedTools: String?

        enum Kind { case skill, brainstorm }

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

        var projectName: String { (projectPath as NSString).lastPathComponent }

        /// Most recent event headline, for compact "what's happening now" lines.
        var lastActivity: String? {
            events.last.map { event in
                event.kind == .toolUse ? "Running \(event.title)" : event.title
            }
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

    // MARK: - Permission posture
    //
    // We deliberately do NOT use `--permission-mode bypassPermissions`. Bypass
    // auto-approves *every* tool call — arbitrary Bash, file writes anywhere, MCP
    // calls — with no gate. Because skills read untrusted input (artifact text,
    // fetched competitor pages), a bypassed run turns a prompt-injection into
    // straight code execution on the user's machine.
    //
    // Instead we run in the default permission mode with an explicit allow-list
    // scoped to what the pm-* skills actually need. Tools off this list are
    // denied (headless print mode can't prompt). This BOUNDS — it does not
    // eliminate — the blast radius: the skills genuinely need Bash (their
    // preambles source nanopm.sh and probe files), so a hostile project can
    // still do damage. Treat the projects you open as trusted, and see the
    // Safety section in README.md before distributing builds.
    static let permissionMode = "default"
    // WebSearch is needed by pm-competitors-intel's discovery mode (find new
    // competitor entrants); without it the headless run falls back to only the
    // competitors it can name from memory.
    // nonisolated: referenced from the nonisolated default of SkillRun.allowedTools.
    nonisolated static let allowedTools = "Read Edit Write Glob Grep Bash WebFetch WebSearch TodoWrite Task"

    // MARK: - Brainstorm posture
    //
    // A brainstorm is a free-form conversation, not a document build. Two
    // deliberate differences from a skill run:
    //   1. A conversational CPO persona preamble REPLACES the question-contract —
    //      otherwise the model halts each turn to emit nanopm-question JSON
    //      instead of talking.
    //   2. Mutating tools are DENIED. A pure chat over untrusted project content
    //      has no business writing files or running Bash, so we shrink the
    //      prompt-injection blast radius the permission-posture note above warns
    //      about. Verified live (2026-06-16): in `-p --permission-mode default`,
    //      `--allowedTools` does NOT deny the tools left off it — non-listed tools
    //      still run. `--disallowedTools` is the only hard gate, so it carries the
    //      restriction; the reduced allow-list is intent + no-prompt only.
    //      Read/Grep/Glob keep the CPO grounded in the repo; WebFetch/WebSearch
    //      for outside facts.
    nonisolated static let brainstormAllowedTools = "Read Grep Glob WebFetch WebSearch"
    nonisolated static let brainstormDisallowedTools = "Bash Edit Write MultiEdit NotebookEdit Task"
    static let brainstormPreamble = """
    You are a seasoned CPO jamming informally with the founder of this project — a \
    thinking partner, not a reviewer. This is a brainstorm: riff on product ideas, user \
    problems, and what to build next. There is no document to produce and no gate to pass.

    Ground yourself in this project's context: read .nanopm/CONTEXT-SUMMARY.md and \
    .nanopm/OBJECTIVES.md if they exist (you have read-only access to the repo). Reference \
    the actual mission, personas, and objectives — not generic product platitudes.

    How to jam: problem first — push toward the user and their problem before the solution; \
    name the question being avoided; offer sharp angles and honest objections as a peer; if \
    an idea collides with a stated anti-goal, say so. Stay concrete and conversational.

    This is a normal back-and-forth chat. Do NOT emit any structured question block, fenced \
    JSON, or nanopm-question block, and never call AskUserQuestion — just talk. Keep replies \
    focused: a few tight paragraphs, not an essay.
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

    func launch(_ doc: SkillDoc, in projectPath: String, userContext: String? = nil) {
        guard let skillCommand = doc.skillCommand,
              !isActive(doc.trackingPath, in: projectPath) else { return }

        Notifier.requestAuthorizationIfNeeded()

        var run = SkillRun(projectPath: projectPath,
                           skillCommand: skillCommand,
                           expectedRelPath: doc.trackingPath)
        let context = (userContext ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !context.isEmpty {
            run.transcript.append(TranscriptEntry(role: .user, text: context))
        }
        runs.append(run)

        var parts = [skillCommand]
        if !context.isEmpty {
            parts.append("CONTEXT FROM THE USER — they typed this when launching the run; "
                         + "let it scope and inform the work:\n\(context)")
        }
        parts.append(contentsOf: [doc.headlessArgs, Self.interfaceContract].compactMap(\.self))
        startTurn(run.id, prompt: parts.joined(separator: "\n\n"), resumeSession: nil)
    }

    /// Resume a waiting run with the user's composed answers.
    func submitAnswers(_ runID: UUID, _ answerText: String) {
        guard let index = runs.firstIndex(where: { $0.id == runID }),
              case .waitingForInput = runs[index].status else { return }
        runs[index].transcript.append(TranscriptEntry(role: .user, text: answerText))
        runs[index].status = .running
        startTurn(runID, prompt: answerText, resumeSession: runs[index].sessionID)
    }

    // MARK: - Brainstorm

    /// Start a new brainstorm jam: a conversational run with the CPO persona
    /// preamble and the reduced allow-list. The first turn fires immediately.
    /// Returns the run id so the view can follow it.
    @discardableResult
    func startBrainstorm(in projectPath: String, firstMessage: String) -> UUID? {
        let message = firstMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return nil }
        Notifier.requestAuthorizationIfNeeded()

        var run = SkillRun(projectPath: projectPath, skillCommand: "Brainstorm", expectedRelPath: "")
        run.kind = .brainstorm
        run.allowedTools = Self.brainstormAllowedTools
        run.disallowedTools = Self.brainstormDisallowedTools
        run.transcript.append(TranscriptEntry(role: .user, text: message))
        runs.append(run)
        startTurn(run.id, prompt: Self.brainstormPreamble + "\n\n" + message, resumeSession: nil)
        return run.id
    }

    /// Open a brainstorm bound to a prior host session. No turn fires yet — the
    /// session already holds the persona and full prior context; the user's next
    /// message resumes it via `claude --resume`. v1 shows only new turns (the
    /// host reloads the transcript server-side).
    @discardableResult
    func resumeBrainstorm(in projectPath: String, sessionID: String, title: String?) -> UUID {
        var run = SkillRun(projectPath: projectPath, skillCommand: "Brainstorm", expectedRelPath: "")
        run.kind = .brainstorm
        run.allowedTools = Self.brainstormAllowedTools
        run.disallowedTools = Self.brainstormDisallowedTools
        run.sessionID = sessionID
        run.title = title
        run.status = .succeeded   // idle/ready — composer enabled, no turn in flight
        runs.append(run)
        return run.id
    }

    /// Send a free-text message into an existing brainstorm and resume its
    /// session. Used for every turn after the first (new or resumed jam).
    func sendMessage(_ runID: UUID, _ text: String) {
        guard let index = runs.firstIndex(where: { $0.id == runID }), !runs[index].isActive else { return }
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        runs[index].transcript.append(TranscriptEntry(role: .user, text: message))
        runs[index].status = .running
        startTurn(runID, prompt: message, resumeSession: runs[index].sessionID)
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
        runs[index].turnCount += 1
        let turn = runs[index].turnCount

        var cli = "claude --permission-mode \(Self.permissionMode)"
        cli += " --allowedTools \(ShellRunner.quote(runs[index].allowedTools))"
        if let disallowed = runs[index].disallowedTools, !disallowed.isEmpty {
            cli += " --disallowedTools \(ShellRunner.quote(disallowed))"
        }
        cli += " --output-format stream-json --verbose"
        if let resumeSession {
            cli += " --resume \(ShellRunner.quote(resumeSession))"
        }
        cli += " -p \(ShellRunner.quote(prompt)) </dev/null"
        // zsh -l loads the user's PATH so the `claude` CLI resolves when the
        // app is launched from Finder; the prefix adds the native installer's
        // `~/.local/bin`, which login shells miss (see ShellRunner).
        let shellCommand = ShellRunner.claudePathPrefix
            + "cd \(ShellRunner.quote(projectPath)) && \(cli)"

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

        // Stream stdout line by line so the console updates live; drain stderr
        // concurrently so a full stderr buffer can't block the child.
        Task.detached(priority: .utility) {
            async let errBytes: Data = errPipe.fileHandleForReading.readDataToEndOfFile()
            var terminal: TerminalResult?
            do {
                for try await line in outPipe.fileHandleForReading.bytes.lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { continue }
                    let (event, result) = Self.parseStreamLine(trimmed, turn: turn)
                    if let result { terminal = result }
                    if let event { await self.appendEvent(runID, event) }
                }
            } catch { /* pipe closed — fall through to finish */ }
            process.waitUntilExit()
            let stderr = String(data: await errBytes, encoding: .utf8) ?? ""
            await self.finishTurn(runID, exitCode: process.terminationStatus,
                                  terminal: terminal, stderr: stderr, turn: turn)
        }
    }

    private func appendEvent(_ runID: UUID, _ event: LogEvent) {
        guard let index = runs.firstIndex(where: { $0.id == runID }),
              runs[index].isActive else { return }
        runs[index].events.append(event)
        if let sid = event.sessionID { runs[index].sessionID = sid }
    }

    private func finishTurn(_ runID: UUID, exitCode: Int32,
                            terminal: TerminalResult?, stderr: String, turn: Int) {
        guard let index = runs.firstIndex(where: { $0.id == runID }) else { return }
        // Cancelled (or otherwise resolved) while the process was draining.
        guard runs[index].status == .running else { return }
        processes[runID] = nil
        let run = runs[index]

        guard let terminal else {
            let detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            applyFailure(runID, message: Self.diagnose(detail, exitCode: exitCode)
                         ?? (detail.isEmpty ? "claude exited \(exitCode) with no result event"
                                            : String(detail.suffix(400))))
            return
        }

        if let sessionID = terminal.sessionID {
            runs[index].sessionID = sessionID
        }
        let questions = Self.extractQuestions(from: terminal.text)
        let visibleText = Self.stripQuestionBlock(from: terminal.text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !visibleText.isEmpty {
            runs[index].transcript.append(TranscriptEntry(role: .model, text: visibleText))
        }

        if terminal.isError || exitCode != 0 {
            applyFailure(runID, message: Self.diagnose(visibleText, exitCode: exitCode)
                         ?? (visibleText.isEmpty ? "claude exited \(exitCode)"
                                                 : String(visibleText.suffix(400))))
        } else if !questions.isEmpty {
            runs[index].status = .waitingForInput(questions)
            Notifier.send(
                title: "\(run.skillCommand) needs your input",
                body: questions.first?.question ?? "Answer in NanoPM Viewer to continue."
            )
        } else {
            runs[index].status = .succeeded
            completionTick += 1
            // Brainstorm replies are watched live — a per-turn notification is just
            // noise. Only skill runs (which produce an artifact) notify on success.
            if run.kind == .skill {
                Notifier.send(
                    title: "\(run.expectedRelPath) is ready",
                    body: "\(run.skillCommand) finished — open NanoPM Viewer to read it."
                )
            }
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

    /// Map a known fatal-error signature to an actionable message. Returns nil
    /// when the text isn't a recognized case (caller falls back to the raw tail).
    /// The two cases the target user actually hits: the CLI isn't installed, and
    /// the CLI is installed but can't authenticate (seen live: a managed org that
    /// disables Claude Code subscription access and has no API key in the shell).
    nonisolated static func diagnose(_ text: String, exitCode: Int32) -> String? {
        let t = text.lowercased()
        if exitCode == 127
            || t.contains("command not found")
            || t.contains("claude: not found") {
            return "The `claude` CLI wasn't found on your PATH. Running skills needs "
                + "Claude Code installed and authenticated; browsing existing artifacts "
                + "works without it."
        }
        if t.contains("disabled claude subscription")
            || t.contains("use an anthropic api key")
            || t.contains("invalid api key")
            || (t.contains("authentication") && t.contains("api key")) {
            return "Claude Code couldn't authenticate. Runs need either Claude Code "
                + "subscription access enabled for your organization, or an "
                + "`ANTHROPIC_API_KEY` available to the shell the app launches from "
                + "(set it in ~/.zprofile, then relaunch). Browsing works without it."
        }
        return nil
    }

    // MARK: - Stream parsing

    /// Carried out of the stream when the final `result` event arrives.
    struct TerminalResult {
        let text: String
        let sessionID: String?
        let isError: Bool
    }

    /// Parse one NDJSON line from `--output-format stream-json` into a console
    /// event and, for the final `result` line, the turn's terminal outcome.
    nonisolated static func parseStreamLine(_ line: String, turn: Int) -> (event: LogEvent?, result: TerminalResult?) {
        guard let data = line.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = obj["type"] as? String
        else {
            // Non-JSON (login-shell noise) — surface as a raw line, not a crash.
            return (LogEvent(turn: turn, kind: .error, title: "stderr", detail: line, sessionID: nil), nil)
        }
        let sid = obj["session_id"] as? String

        func event(_ kind: LogEvent.Kind, _ title: String, _ detail: String?) -> LogEvent {
            LogEvent(turn: turn, kind: kind, title: title, detail: detail, sessionID: sid)
        }

        switch type {
        case "system":
            let subtype = obj["subtype"] as? String
            if subtype == "init" {
                let model = obj["model"] as? String ?? "?"
                return (event(.session, "Session started", "model \(model)"), nil)
            }
            if subtype == "post_turn_summary" {
                return (event(.summary, "Turn summary", obj["status_detail"] as? String), nil)
            }
            return (nil, nil)

        case "assistant":
            return (assistantEvents(obj, turn: turn, sid: sid), nil)

        case "user":
            return (toolResultEvent(obj, turn: turn, sid: sid), nil)

        case "result":
            let text = obj["result"] as? String ?? ""
            let isError = obj["is_error"] as? Bool ?? false
            return (event(.result, isError ? "Run errored" : "Turn finished", resultSummary(obj)),
                    TerminalResult(text: text, sessionID: sid, isError: isError))

        default:
            return (nil, nil) // rate_limit_event and friends — skip as noise
        }
    }

    /// An assistant message may carry text and/or tool_use blocks.
    nonisolated private static func assistantEvents(_ obj: [String: Any], turn: Int, sid: String?) -> LogEvent? {
        guard let message = obj["message"] as? [String: Any],
              let content = message["content"] as? [[String: Any]] else { return nil }
        for block in content {
            let blockType = block["type"] as? String
            if blockType == "tool_use", let name = block["name"] as? String {
                let input = block["input"] as? [String: Any] ?? [:]
                return LogEvent(turn: turn, kind: .toolUse, title: name,
                                detail: toolInputSummary(name: name, input: input), sessionID: sid)
            }
            if blockType == "text", let text = block["text"] as? String,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return LogEvent(turn: turn, kind: .assistant, title: "Assistant",
                                detail: text, sessionID: sid)
            }
        }
        return nil
    }

    nonisolated private static func toolResultEvent(_ obj: [String: Any], turn: Int, sid: String?) -> LogEvent? {
        guard let message = obj["message"] as? [String: Any],
              let content = message["content"] as? [[String: Any]] else { return nil }
        for block in content where block["type"] as? String == "tool_result" {
            let isError = block["is_error"] as? Bool ?? false
            let body = (block["content"] as? String)
                ?? ((block["content"] as? [[String: Any]])?.compactMap { $0["text"] as? String }.joined(separator: "\n"))
                ?? ""
            return LogEvent(turn: turn, kind: isError ? .error : .toolResult,
                            title: isError ? "Tool error" : "Tool result",
                            detail: String(body.prefix(4000)), sessionID: sid)
        }
        return nil
    }

    nonisolated private static func toolInputSummary(name: String, input: [String: Any]) -> String? {
        if let cmd = input["command"] as? String { return cmd }
        if let path = input["file_path"] as? String { return path }
        if let pattern = input["pattern"] as? String { return pattern }
        if let url = input["url"] as? String { return url }
        if let prompt = input["prompt"] as? String { return String(prompt.prefix(200)) }
        guard let data = try? JSONSerialization.data(withJSONObject: input),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json == "{}" ? nil : String(json.prefix(200))
    }

    nonisolated private static func resultSummary(_ obj: [String: Any]) -> String? {
        var parts: [String] = []
        if let ms = obj["duration_ms"] as? Double { parts.append(String(format: "%.1fs", ms / 1000)) }
        if let turns = obj["num_turns"] as? Int { parts.append("\(turns) turns") }
        if let cost = obj["total_cost_usd"] as? Double { parts.append(String(format: "$%.3f", cost)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
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

    /// UNUserNotificationCenter.current() ABORTS the process (NSAssertion →
    /// SIGABRT) when the executable runs outside a real .app bundle — which is
    /// how the viewer ships today (bare SwiftPM binary). Gate every UN call on
    /// this and fall back to AppleScript notifications.
    private static var hasBundleIdentifier: Bool { Bundle.main.bundleIdentifier != nil }

    static func requestAuthorizationIfNeeded() {
        guard hasBundleIdentifier else { return }
        guard !authRequested else { return }
        authRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func send(title: String, body: String) {
        guard hasBundleIdentifier else {
            sendViaAppleScript(title: title, body: body)
            return
        }
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
