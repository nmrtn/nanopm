import SwiftUI
import MarkdownUI

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
        // vNext: the canonical episodic log moved to the project-local wiki raw
        // layer (mirrors _nanopm_memory_file in lib/nanopm.sh). Prefer it; fall back
        // to the legacy global ~/.nanopm/memory/<slug>.jsonl for un-migrated projects.
        let local = path + "/.nanopm/raw/events.jsonl"
        if FileManager.default.fileExists(atPath: local) { return local }
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

/// Read-only window onto the project's NanoPM memory. Primary: the curated wiki
/// heartbeat (.nanopm/wiki/log.md — what the memory recorded/changed). Secondary:
/// the raw per-run activity trace (.nanopm/raw/events.jsonl). Note the wiki briefs
/// (Define/Plan), not this log, are what each skill reads back into context.
struct MemoryView: View {
    @ObservedObject var store: ArtifactStore

    @State private var entries: [MemoryEntry] = []
    @State private var eventsPath: String?
    /// Rendered body of wiki/log.md (frontmatter + intro stripped); empty when the
    /// wiki has recorded nothing yet.
    @State private var logBody: String = ""
    @State private var logPath: String?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Memory")
                        .font(.npDisplay(30))
                        .foregroundStyle(Color.npInk)
                    Text("How NanoPM's memory of \(store.project.name) changed over time. What every skill reads back is the wiki briefs (see Define & Plan) — below is the curated change log, and the raw run history behind it.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    if let logPath {
                        Text(abbreviateHome(logPath))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider().overlay(Color.npBorder)

                if !loaded {
                    SparkleView(size: 18)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else if logBody.isEmpty && entries.isEmpty {
                    ContentUnavailableView(
                        "No memory yet",
                        systemImage: "brain",
                        description: Text("No NanoPM skill has recorded anything for this project. Run one (e.g. from a phase overview) and check back.")
                    )
                } else {
                    // Primary: the curated wiki heartbeat (what the memory recorded/changed).
                    if logBody.isEmpty {
                        Text("No wiki memory recorded yet — this change log fills in as the wiki ingests sources, runs the judgment lint, or migrates.")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    } else {
                        Markdown(logBody)
                            .markdownTheme(.nanopm)
                            .textSelection(.enabled)
                    }

                    // Secondary: the raw per-run activity trace (collapsed by default).
                    if !entries.isEmpty {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 10) {
                                if let eventsPath {
                                    Text(abbreviateHome(eventsPath))
                                        .font(.system(.footnote, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(entries) { entry in
                                    card(entry)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            Text("Activity — \(entries.count) skill run\(entries.count == 1 ? "" : "s")")
                                .font(.headline)
                        }
                        .padding(.top, 6)
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
        let logFile = store.project.nanopmPath + "/wiki/log.md"
        let (logText, logExists, eventsFile, eventsText) = await Task.detached(priority: .userInitiated) {
            () -> (String, Bool, String, String) in
            let logText = (try? ShellRunner.run("cat \(ShellRunner.quote(logFile)) 2>/dev/null")) ?? ""
            let logExists = FileManager.default.fileExists(atPath: logFile)
            let eventsFile = MemoryLog.file(forProjectAt: projectPath)
            let eventsText = (try? ShellRunner.run("cat \(ShellRunner.quote(eventsFile)) 2>/dev/null")) ?? ""
            return (logText, logExists, eventsFile, eventsText)
        }.value
        logBody = Self.stripLogHeader(stripFrontmatter(logText))
        logPath = logExists ? logFile : nil
        entries = MemoryLog.parse(eventsText)
        eventsPath = eventsText.isEmpty ? nil : eventsFile
        loaded = true
    }

    /// Drop the "# Wiki Log" H1 and the intro line so the page title isn't doubled —
    /// keep from the first `## [date] …` entry on. Empty when there are no entries yet.
    private static func stripLogHeader(_ raw: String) -> String {
        let lines = raw.components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: { $0.hasPrefix("## ") }) else { return "" }
        return lines[start...].joined(separator: "\n").trimmingCharacters(in: .newlines)
    }
}
