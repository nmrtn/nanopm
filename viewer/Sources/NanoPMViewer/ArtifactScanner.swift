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

        // -L follows symlinks: company-level docs (VISION-MISSION, BUSINESS-MODEL,
        // ORG) are symlinked into .nanopm/ from the shared ~/.nanopm/companies/<co>/,
        // so without -L they'd be type `l` and skipped. `2>/dev/null || true` keeps
        // a single bad link (e.g. a symlink loop) from making find exit non-zero and
        // blanking the whole scan — the files it did find are still emitted.
        let command = "cd \(ShellRunner.quote(nanopm)) && { find -L . -type f -not -path './.git/*' -exec stat -f '%m|%N' {} \\; 2>/dev/null || true; }"
        let output = try ShellRunner.run(command)

        var artifacts: [Artifact] = []
        for line in output.split(separator: "\n") {
            guard let sep = line.firstIndex(of: "|") else { continue }
            let epochString = String(line[..<sep])
            var path = String(line[line.index(after: sep)...])
            if path.hasPrefix("./") { path.removeFirst(2) }
            let ext = (path as NSString).pathExtension.lowercased()
            guard extensions.contains(ext) else { continue }
            guard let phase = PhaseMapper.phase(for: path) else { continue }
            artifacts.append(Artifact(
                relativePath: path,
                phase: phase,
                modifiedAt: Date(timeIntervalSince1970: TimeInterval(epochString) ?? 0)
            ))
        }
        artifacts.sort {
            ($0.phase.order, $0.relativePath.lowercased()) < ($1.phase.order, $1.relativePath.lowercased())
        }
        return .found(artifacts)
    }

    /// Reads .nanopm/competitors.json (written by /pm-competitors-intel);
    /// empty when missing or unparseable.
    static func loadCompetitors(projectPath: String) -> [Competitor] {
        let file = projectPath + "/.nanopm/raw/competitors/competitors.json"
        guard let raw = try? ShellRunner.run("cat \(ShellRunner.quote(file)) 2>/dev/null"),
              let data = raw.data(using: .utf8) else { return [] }
        struct Config: Codable { var competitors: [Competitor] }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decoder.decode(Config.self, from: data))?.competitors ?? []
    }
}
