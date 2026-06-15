import SwiftUI
import MarkdownUI

/// Landing page for the Competitors entry: the latest intel report rendered,
/// with a History menu to read any past report (newest → oldest).
struct CompetitorsPageView: View {
    @ObservedObject var store: ArtifactStore
    @EnvironmentObject private var runManager: RunManager

    /// The Competitor Intel skill, used to launch its modes from this page.
    private var intelDoc: SkillDoc? {
        SkillCatalog.all.first { $0.skillCommand == "/pm-competitors-intel" }
    }

    private var intelRunning: Bool {
        guard let doc = intelDoc else { return false }
        return runManager.isActive(doc.trackingPath, in: store.project.path)
    }

    /// Launches Competitor Intel in one of its three modes. The mode is carried
    /// in the launch context; the skill detects discovery / `analyze` intent
    /// from it (see pm-competitors-intel Preamble + Phase 1).
    private func launchIntel(_ context: String?) {
        guard let doc = intelDoc else { return }
        runManager.launch(doc, in: store.project.path, userContext: context)
    }

    struct Implications: Equatable {
        let sourceID: String
        let sourceTitle: String
        let text: String
    }

    /// One-glance summary shown at the very top of the page: the most
    /// significant change + recommended action (from the newest INTEL report)
    /// and, if an analyze run produced a positioning matrix, where we win /
    /// where we're exposed (from COMPETITORS.md).
    struct TLDR: Equatable {
        var latestChange: String?
        var action: String?
        var win: String?
        var exposed: String?
        var isEmpty: Bool { latestChange == nil && action == nil && win == nil && exposed == nil }
    }

    @State private var selectedReportID: String?
    @State private var content: String?
    @State private var implications: Implications?
    @State private var tldr: TLDR?
    @State private var reasoningContent: String?
    @State private var showReasoning = false

    /// Pull the "Where we win / Where we're exposed" verdict lines out of the
    /// COMPETITORS.md positioning-matrix section. Tolerant of bold markers and
    /// either apostrophe (the LLM that writes the doc may use ASCII ' or U+2019),
    /// and scoped to the matrix section so a quoted verdict elsewhere can't match.
    private static func matrixVerdict(in markdown: String) -> (win: String?, exposed: String?) {
        let scope: Substring = markdown.range(of: "## Positioning matrix")
            .map { markdown[$0.upperBound...] } ?? markdown[...]
        var win: String?
        var exposed: String?
        for raw in scope.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces)
            guard let colon = line.firstIndex(of: ":") else { continue }
            let label = line[..<colon].lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if value.isEmpty { continue }
            if win == nil, label.contains("where we win") { win = value }
            else if exposed == nil, label.contains("exposed") { exposed = value }
            if win != nil, exposed != nil { break }
        }
        return (win, exposed)
    }

    /// The reasoning sidecar for COMPETITORS.md (written by /pm-competitors-intel
    /// in analyze mode). Surfaces as a "Reasoning" pane on the landscape report,
    /// never as its own sidebar row — mirrors the Define-doc convention.
    private var reasoningArtifact: Artifact? {
        guard displayed?.relativePath == "COMPETITORS.md" else { return nil }
        let path = ReasoningFiles.sidecarPath(for: "COMPETITORS.md")
        return store.artifacts.first { $0.relativePath == path }
    }

    /// Newest dated INTEL report — source of the page-top Strategic implications.
    private var latestIntelReport: Artifact? {
        store.artifacts
            .filter { $0.relativePath.hasPrefix("intel/INTEL-") && $0.relativePath.hasSuffix(".md") }
            .sorted { $0.relativePath > $1.relativePath }
            .first
    }

    /// Newest first: COMPETITORS.md (the current report), then dated INTEL reports.
    private var reports: [Artifact] {
        store.artifacts
            .filter { CompetitorFiles.isReport($0.relativePath) }
            .sorted {
                if $0.relativePath == "COMPETITORS.md" { return true }
                if $1.relativePath == "COMPETITORS.md" { return false }
                return $0.relativePath > $1.relativePath
            }
    }

    private var displayed: Artifact? {
        reports.first { $0.id == selectedReportID } ?? reports.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label {
                            Text("Competitors")
                                .foregroundStyle(Color.npInk)
                        } icon: {
                            Image(systemName: "binoculars")
                                .foregroundStyle(Color.npCoral)
                        }
                        .font(.npDisplay(30))
                        Text(subtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Menu {
                        Button {
                            launchIntel(nil)
                        } label: {
                            Label("Intel check", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button {
                            launchIntel("Re-scan the web for new competitor entrants I'm not tracking yet "
                                        + "(discovery maintenance mode), propose only net-new ones for me to confirm, "
                                        + "then run the intel check.")
                        } label: {
                            Label("Find new competitors", systemImage: "sparkle.magnifyingglass")
                        }
                        Button {
                            launchIntel("Run the full competitive analysis in analyze mode: first discover any new "
                                        + "entrants, then produce the per-competitor SWOT and the scored positioning "
                                        + "matrix with a reasoning sidecar.")
                        } label: {
                            Label("Full analysis (SWOT + matrix)", systemImage: "chart.bar.doc.horizontal")
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")
                            Text(intelRunning ? "Running…" : "Run")
                            Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                        }
                    }
                    .menuStyle(.button)
                    .buttonStyle(ActionButtonStyle(tone: .accent, prominent: !intelRunning))
                    .fixedSize()
                    .disabled(intelRunning)
                    .help("Launch Competitor Intel: diff veille, discover new entrants, or full SWOT + positioning analysis")

                    if reasoningArtifact != nil {
                        ActionButton(
                            title: showReasoning ? "Hide reasoning" : "Reasoning",
                            systemImage: "brain",
                            tone: showReasoning ? .accent : .neutral,
                            prominent: showReasoning,
                            help: "Evidenced/Assumed calls, scoring rationale, and sources behind the landscape"
                        ) {
                            showReasoning.toggle()
                        }
                    }
                    if !reports.isEmpty {
                        Menu {
                            ForEach(reports) { report in
                                Button {
                                    selectedReportID = report.id
                                } label: {
                                    if report.id == displayed?.id {
                                        Label(CompetitorFiles.reportTitle(report.relativePath),
                                              systemImage: "checkmark")
                                    } else {
                                        Text(CompetitorFiles.reportTitle(report.relativePath))
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("History")
                                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                            }
                        }
                        .menuStyle(.button)
                        .buttonStyle(ActionButtonStyle())
                        .fixedSize()
                        .help("Read past intel reports, newest to oldest")
                    }
                }

                if let tldr, !tldr.isEmpty {
                    tldrCard(tldr)
                }

                if let implications {
                    Markdown(implications.text)
                        .markdownTheme(.nanopm)
                        .textSelection(.enabled)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.npSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.npBorder))
                }

                if let report = displayed {
                    VStack(alignment: .leading, spacing: 10) {
                        if let content {
                            if let parsed = IntelReportParser.parse(content) {
                                IntelReportView(
                                    report: parsed,
                                    skipSectionIDs: report.id == implications?.sourceID
                                        ? Set(parsed.sections
                                            .filter { $0.title.lowercased().contains("strategic implications") }
                                            .map(\.id))
                                        : []
                                )
                            } else {
                                Markdown(content)
                                    .markdownTheme(.nanopm)
                                    .textSelection(.enabled)
                            }
                        } else {
                            SparkleView(size: 16)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No intel report yet",
                        systemImage: "doc.richtext",
                        description: Text("Use the Run menu above to generate the first report — or Find new competitors to start from scratch.")
                    )
                }

                if showReasoning, reasoningArtifact != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Reasoning", systemImage: "brain")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        if let reasoningContent {
                            Markdown(reasoningContent)
                                .markdownTheme(.nanopm)
                                .textSelection(.enabled)
                        } else {
                            SparkleView(size: 14)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.npSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.npBorder))
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .task(id: "\(displayed?.id ?? "none")#\(store.generation)") {
            content = nil
            reasoningContent = nil
            var loadedContent: String?
            if let report = displayed {
                loadedContent = try? await store.content(of: report)
                content = loadedContent
            }
            if let reasoning = reasoningArtifact {
                reasoningContent = try? await store.content(of: reasoning)
            }

            var newTLDR = TLDR()

            // Strategic implications + TL;DR change/action from the newest INTEL report.
            if let intel = latestIntelReport,
               let intelContent = try? await store.content(of: intel),
               let parsed = IntelReportParser.parse(intelContent) {
                if let section = parsed.sections.first(where: { $0.title.lowercased().contains("strategic implications") }),
                   !section.combinedBody.isEmpty {
                    implications = Implications(
                        sourceID: intel.id,
                        sourceTitle: CompetitorFiles.reportTitle(intel.relativePath),
                        text: section.combinedBody
                    )
                } else {
                    implications = nil
                }
                newTLDR.latestChange = parsed.summaryBody
                newTLDR.action = parsed.action
            } else {
                implications = nil
            }

            // Win / exposed from the COMPETITORS.md positioning matrix (analyze mode).
            var landscape = displayed?.relativePath == "COMPETITORS.md" ? loadedContent : nil
            if landscape == nil, let comp = store.artifacts.first(where: { $0.relativePath == "COMPETITORS.md" }) {
                landscape = try? await store.content(of: comp)
            }
            if let landscape {
                let verdict = Self.matrixVerdict(in: landscape)
                newTLDR.win = verdict.win
                newTLDR.exposed = verdict.exposed
            }

            tldr = newTLDR.isEmpty ? nil : newTLDR
        }
    }

    @ViewBuilder
    private func tldrCard(_ t: TLDR) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("TL;DR", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.npCoral)
            if let change = t.latestChange {
                Text(change)
                    .font(.body)
                    .foregroundStyle(Color.npInk)
                    .textSelection(.enabled)
            }
            if let action = t.action {
                (Text("Action: ").fontWeight(.semibold) + Text(action))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            if t.win != nil || t.exposed != nil {
                Divider().padding(.vertical, 2)
                if let win = t.win {
                    (Text("Win: ").fontWeight(.semibold).foregroundColor(.npOlive) + Text(win))
                        .font(.callout)
                        .textSelection(.enabled)
                }
                if let exposed = t.exposed {
                    (Text("Exposed: ").fontWeight(.semibold).foregroundColor(.npRust) + Text(exposed))
                        .font(.callout)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.npSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.npBorder))
    }

    private var subtitle: String {
        let count = store.competitors.count
        var text = count == 1 ? "1 competitor monitored" : "\(count) competitors monitored"
        if let latest = store.competitors.compactMap(\.lastCheckedDate).max() {
            text += " · last checked \(latest.formatted(.relative(presentation: .named)))"
        }
        return text
    }
}

/// Per-competitor page: monitored page links, last-checked, and the latest
/// snapshot of each monitored page as segmented tabs.
struct CompetitorDetailView: View {
    @ObservedObject var store: ArtifactStore
    let competitor: Competitor

    @State private var selectedSnapshotID: String?

    private var snapshots: [Artifact] {
        store.artifacts
            .filter { $0.relativePath.hasPrefix("intel/snapshots/\(competitor.slug)/") }
            .sorted {
                let a = CompetitorFiles.pageOrder.firstIndex(of: CompetitorFiles.snapshotPage($0.relativePath) ?? "") ?? .max
                let b = CompetitorFiles.pageOrder.firstIndex(of: CompetitorFiles.snapshotPage($1.relativePath) ?? "") ?? .max
                return a < b
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Divider()
                if snapshots.isEmpty {
                    ContentUnavailableView(
                        "No snapshots yet",
                        systemImage: "camera.metering.unknown",
                        description: Text("Run Competitor Intel to capture \(competitor.name)'s pages.")
                    )
                } else {
                    Picker("Page", selection: $selectedSnapshotID) {
                        ForEach(snapshots) { snapshot in
                            Text(CompetitorFiles.pageTitle(CompetitorFiles.snapshotPage(snapshot.relativePath) ?? ""))
                                .tag(Optional(snapshot.id))
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if let snapshot = snapshots.first(where: { $0.id == selectedSnapshotID }) ?? snapshots.first {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(".nanopm/\(snapshot.relativePath) · updated \(snapshot.modifiedAt, format: .relative(presentation: .named))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            MarkdownFileView(store: store, artifact: snapshot)
                        }
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .onAppear {
            if selectedSnapshotID == nil { selectedSnapshotID = snapshots.first?.id }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(competitor.name)
                    .foregroundStyle(Color.npInk)
            } icon: {
                Image(systemName: "building.2")
                    .foregroundStyle(Color.npCoral)
            }
            .font(.npDisplay(30))
            if let date = competitor.lastCheckedDate {
                Text("Last checked \(date, format: .relative(presentation: .named))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(competitor.monitoredPages, id: \.title) { page in
                    Link(destination: page.url) {
                        Label(page.title, systemImage: "arrow.up.right")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quinary, in: Capsule())
                }
            }
        }
    }
}

/// Minimal markdown loader/renderer for embedding inside other pages.
struct MarkdownFileView: View {
    @ObservedObject var store: ArtifactStore
    let artifact: Artifact

    @State private var content: String?

    var body: some View {
        Group {
            if let content {
                Markdown(content)
                    .markdownTheme(.nanopm)
                    .textSelection(.enabled)
            } else {
                SparkleView(size: 16)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .task(id: "\(artifact.id)#\(store.generation)") {
            content = try? await store.content(of: artifact)
        }
    }
}
