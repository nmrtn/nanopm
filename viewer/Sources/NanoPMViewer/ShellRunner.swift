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
}
