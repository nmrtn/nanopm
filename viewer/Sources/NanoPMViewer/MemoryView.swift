import SwiftUI

/// One line of ~/.nanopm/memory/<slug>.jsonl — what a skill run recorded.
struct MemoryEntry: Identifiable {
    let id: Int
    let skill: String
    let timestamp: Date?
    let outputs: [(key: String, value: String)]
}

enum MemoryLog {
    /// Memory journal path for a project, mirroring `nanopm_slug()` in
    /// lib/nanopm.sh: git repo name when inside a repo, else folder name.
    static func file(forProjectAt path: String) -> String {
        let quoted = ShellRunner.quote(path)
        let slug = ((try? ShellRunner.run(
            "basename \"$(git -C \(quoted) rev-parse --show-toplevel 2>/dev/null || echo \(quoted))\""
        )) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = slug.isEmpty ? (path as NSString).lastPathComponent : slug
        return NSHomeDirectory() + "/.nanopm/memory/" + name + ".jsonl"
    }

    /// Lenient JSONL parse — interrupted runs leave truncated lines, so
    /// anything unparseable is skipped rather than failing the page.
    static func parse(_ content: String) -> [MemoryEntry] {
        let iso = ISO8601DateFormatter()
        var entries: [MemoryEntry] = []
        for (index, line) in content.components(separatedBy: "\n").enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let data = trimmed.data(using: .utf8),
                  let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let skill = object["skill"] as? String else { continue }
            let outputs = ((object["outputs"] as? [String: Any]) ?? [:])
                .map { (key: $0.key, value: stringify($0.value)) }
                .sorted { $0.key < $1.key }
            entries.append(MemoryEntry(
                id: index,
                skill: skill,
                timestamp: (object["ts"] as? String).flatMap { iso.date(from: $0) },
                outputs: outputs
            ))
        }
        return entries.reversed() // append-only journal → newest first
    }

    private static func stringify(_ value: Any) -> String {
        if let string = value as? String { return string }
        if let number = value as? NSNumber {
            if number === kCFBooleanTrue { return "true" }
            if number === kCFBooleanFalse { return "false" }
            return number.stringValue
        }
        return "\(value)"
    }
}

/// Read-only page over the project's NanoPM memory: the global append-only
/// journal each skill writes to and later runs read back for context.
struct MemoryView: View {
    @ObservedObject var store: ArtifactStore

    @State private var entries: [MemoryEntry] = []
    @State private var filePath: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Memory")
                        .font(.npDisplay(30))
                        .foregroundStyle(Color.npInk)
                    Text("What NanoPM remembers about \(store.project.name) — every skill run leaves a trace here, and later runs read it back for context.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    if let filePath {
                        Text(abbreviateHome(filePath))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider().overlay(Color.npBorder)

                if filePath == nil {
                    SparkleView(size: 18)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else if entries.isEmpty {
                    ContentUnavailableView(
                        "No memory yet",
                        systemImage: "brain",
                        description: Text("No NanoPM skill has recorded anything for this project. Run one (e.g. from a phase overview) and check back.")
                    )
                } else {
                    ForEach(entries) { entry in
                        card(entry)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .task(id: store.generation) { await load() }
    }

    @ViewBuilder
    private func card(_ entry: MemoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon(for: entry.skill))
                    .foregroundStyle(Color.npCoral)
                    .frame(width: 28, height: 28)
                    .background(Color.npCoral.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
                Text("/" + entry.skill)
                    .font(.headline)
                    .textSelection(.enabled)
                Spacer()
                if let timestamp = entry.timestamp {
                    Text(timestamp, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help(timestamp.formatted(date: .abbreviated, time: .shortened))
                }
            }
            ForEach(entry.outputs, id: \.key) { output in
                VStack(alignment: .leading, spacing: 2) {
                    Text(output.key)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Text(output.value)
                        .font(.callout)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.npSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.npBorder))
    }

    /// Icon of the catalog skill that wrote the entry; sparkle for retired or
    /// unknown skills whose traces are still in the journal.
    private func icon(for skill: String) -> String {
        SkillCatalog.all.first { $0.skillCommand == "/" + skill }?.icon ?? "sparkles"
    }

    private func abbreviateHome(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }

    private func load() async {
        let projectPath = store.project.path
        let (file, content) = await Task.detached(priority: .userInitiated) { () -> (String, String) in
            let file = MemoryLog.file(forProjectAt: projectPath)
            let content = (try? ShellRunner.run("cat \(ShellRunner.quote(file)) 2>/dev/null")) ?? ""
            return (file, content)
        }.value
        entries = MemoryLog.parse(content)
        filePath = file
    }
}
