import Foundation

/// `NanoPMViewer --smoke /path/to/project` prints the scanned artifact list
/// and exits — lets the scanner logic be verified without the UI.
enum SmokeTest {
    static func runIfRequested() {
        let args = CommandLine.arguments
        if let flag = args.firstIndex(of: "--parse-report"), args.count > flag + 1 {
            parseReport(args[flag + 1])
        }
        if let flag = args.firstIndex(of: "--parse-stream"), args.count > flag + 1 {
            parseStream(args[flag + 1])
        }
        if let flag = args.firstIndex(of: "--parse-memory"), args.count > flag + 1 {
            parseMemory(args[flag + 1])
        }
        if args.contains("--parse-update-check") {
            parseUpdateCheck()
        }
        guard let flag = args.firstIndex(of: "--smoke") else { return }
        guard args.count > flag + 1 else {
            print("usage: NanoPMViewer --smoke /path/to/project")
            exit(64)
        }
        let path = args[flag + 1]
        do {
            switch try ArtifactScanner.scan(projectPath: path) {
            case .missingNanopm:
                print("MISSING: \(path)/.nanopm does not exist")
                exit(2)
            case .found(let artifacts):
                for artifact in artifacts {
                    print("\(artifact.phase.rawValue)\t.nanopm/\(artifact.relativePath)")
                }
                print("TOTAL: \(artifacts.count)")
                let competitors = ArtifactScanner.loadCompetitors(projectPath: path)
                for competitor in competitors {
                    print("COMPETITOR\t\(competitor.slug)\t\(competitor.name)\tpages:\(competitor.monitoredPages.count)\tchecked:\(competitor.lastCheckedDate != nil)")
                }
                exit(0)
            }
        } catch {
            print("SMOKE FAIL: \(error)")
            exit(1)
        }
    }

    /// `NanoPMViewer --parse-update-check` runs UpdateChecker.parse against a
    /// fixed table of cases and exits non-zero on any mismatch. Locks down the
    /// "scan every line, ignore incidental shell output" contract the banner
    /// relies on. Mirrors the other --parse-* smoke hooks.
    private static func parseUpdateCheck() {
        let cases: [(name: String, input: String, expect: (String, String)?)] = [
            ("clean",            "UPGRADE_AVAILABLE 0.10.0 0.11.0",                     ("0.10.0", "0.11.0")),
            ("buried-in-output", "sourcing lib…\nUPGRADE_AVAILABLE 0.10.0 0.11.0\n",   ("0.10.0", "0.11.0")),
            ("extra-spacing",    "  UPGRADE_AVAILABLE 1.2.3 1.2.4  ",                   ("1.2.3", "1.2.4")),
            ("empty",            "",                                                    nil),
            ("malformed-2-field","UPGRADE_AVAILABLE 0.10.0",                            nil),
            ("unrelated-output", "some other output\nVERSION: 0.10.0",                  nil),
        ]
        var failures = 0
        for c in cases {
            let got = UpdateChecker.parse(c.input)
            let ok: Bool
            switch (got, c.expect) {
            case let (g?, e?): ok = (g.local == e.0 && g.remote == e.1)
            case (nil, nil):   ok = true
            default:           ok = false
            }
            let shown = got.map { "\($0.local)->\($0.remote)" } ?? "nil"
            print("\(ok ? "PASS" : "FAIL")\t\(c.name)\tgot=\(shown)")
            if !ok { failures += 1 }
        }
        print("PARSE-UPDATE-CHECK: \(cases.count - failures)/\(cases.count) passed")
        exit(failures == 0 ? 0 : 1)
    }

    private static func parseMemory(_ projectPath: String) {
        let file = MemoryLog.file(forProjectAt: projectPath)
        print("FILE: \(file)")
        let content = (try? ShellRunner.run("cat \(ShellRunner.quote(file)) 2>/dev/null")) ?? ""
        let entries = MemoryLog.parse(content)
        for entry in entries {
            let ts = entry.timestamp.map { ISO8601DateFormatter().string(from: $0) } ?? "-"
            print("MEMORY\t\(entry.skill)\t\(ts)\toutputs:\(entry.outputs.count)")
        }
        print("ENTRIES: \(entries.count)")
        exit(0)
    }

    private static func parseStream(_ file: String) {
        guard let content = try? ShellRunner.run("cat \(ShellRunner.quote(file))") else {
            print("STREAM: cannot read"); exit(1)
        }
        var turn = 1, events = 0, terminal = false
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let (event, result) = RunManager.parseStreamLine(trimmed, turn: turn)
            if let event {
                events += 1
                let detail = (event.detail?.replacingOccurrences(of: "\n", with: " ").prefix(50)).map(String.init) ?? "-"
                print("[\(event.kind.rawValue)] \(event.title) :: \(detail)")
            }
            if let result {
                terminal = true
                print("RESULT text=\(result.text.prefix(30)) session=\(result.sessionID ?? "-") error=\(result.isError)")
            }
        }
        print("EVENTS: \(events) TERMINAL: \(terminal)")
        exit(terminal ? 0 : 1)
    }

    private static func parseReport(_ file: String) {
        guard let content = try? ShellRunner.run("cat \(ShellRunner.quote(file))"),
              let report = IntelReportParser.parse(content) else {
            print("PARSE: failed")
            exit(1)
        }
        if let summary = report.summaryBody { print("SUMMARY: \(summary.prefix(60))…") }
        if let action = report.action { print("ACTION: \(action.prefix(60))…") }
        for section in report.sections {
            print("SECTION \(section.title): website=\(section.website != nil) monitored=\(section.monitored.count) fields=\(section.fields.map(\.label)) pages=\(section.pages.count) leftover=\(section.leftover.count)ch")
            for page in section.monitored {
                print("  MONITORED \(page.name) failed=\(page.failed) status=\(page.status ?? "-")")
            }
        }
        exit(0)
    }
}
