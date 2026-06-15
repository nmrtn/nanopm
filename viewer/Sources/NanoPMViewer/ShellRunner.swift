import Foundation

enum ShellError: Error, CustomStringConvertible {
    case failed(command: String, code: Int32, stderr: String)

    var description: String {
        switch self {
        case let .failed(command, code, stderr):
            return "`\(command)` exited \(code): \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }
}

/// All access to the project's files goes through real shell commands —
/// the app never talks to the Claude Code API.
enum ShellRunner {
    @discardableResult
    static func run(_ command: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ShellError.failed(
                command: command,
                code: process.terminationStatus,
                stderr: String(data: errData, encoding: .utf8) ?? ""
            )
        }
        return String(data: outData, encoding: .utf8) ?? ""
    }

    static func runAsync(_ command: String) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try run(command)
        }.value
    }

    /// Single-quote a path for safe interpolation into a zsh command.
    static func quote(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Prefix that guarantees the `claude` CLI resolves regardless of how the
    /// app was launched. The native Claude Code installer drops the binary in
    /// `~/.local/bin` but only adds that dir to the interactive `.zshrc`, which
    /// a non-interactive login shell (`zsh -lc`, what we use to run skills from
    /// Finder) never sources — so the CLI looks missing. Prepend it explicitly.
    /// Used by both the availability check and the run command — keep them in
    /// sync by routing through this constant.
    static let claudePathPrefix = #"export PATH="$HOME/.local/bin:$PATH"; "#

    /// Whether the `claude` CLI resolves in the run shell — Run actions are
    /// disabled when it doesn't. Shared by every surface that offers a Run.
    static func claudeAvailable() async -> Bool {
        let probe = claudePathPrefix + "command -v claude"
        let result = try? await runAsync("zsh -lc \(quote(probe)) 2>/dev/null")
        return !(result ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
