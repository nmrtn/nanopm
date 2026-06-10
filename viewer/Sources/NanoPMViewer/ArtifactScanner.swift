import Foundation

enum ScanResult: Sendable {
    case missingNanopm
    case found([Artifact])
}

/// Enumerates .nanopm/ through shell commands (`test`, `find`, `stat`) —
/// per the PRD, the viewer reads via terminal commands, not via any API.
enum ArtifactScanner {
    static let extensions: Set<String> = ["md", "json", "jsonl"]

    static func scan(projectPath: String) throws -> ScanResult {
        let nanopm = projectPath + "/.nanopm"
        let exists = try ShellRunner.run("test -d \(ShellRunner.quote(nanopm)) && echo yes || echo no")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard exists == "yes" else { return .missingNanopm }

        let command = "cd \(ShellRunner.quote(nanopm)) && find . -type f -not -path './.git/*' -exec stat -f '%m|%N' {} \\;"
        let output = try ShellRunner.run(command)

        var artifacts: [Artifact] = []
        for line in output.split(separator: "\n") {
            guard let sep = line.firstIndex(of: "|") else { continue }
            let epochString = String(line[..<sep])
            var path = String(line[line.index(after: sep)...])
            if path.hasPrefix("./") { path.removeFirst(2) }
            let ext = (path as NSString).pathExtension.lowercased()
            guard extensions.contains(ext) else { continue }
            artifacts.append(Artifact(
                relativePath: path,
                phase: PhaseMapper.phase(for: path),
                modifiedAt: Date(timeIntervalSince1970: TimeInterval(epochString) ?? 0)
            ))
        }
        artifacts.sort {
            ($0.phase.order, $0.relativePath.lowercased()) < ($1.phase.order, $1.relativePath.lowercased())
        }
        return .found(artifacts)
    }
}
