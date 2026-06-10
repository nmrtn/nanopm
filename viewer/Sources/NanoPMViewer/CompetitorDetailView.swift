import SwiftUI
import MarkdownUI

/// Landing page for the Competitors entry: the latest intel report rendered,
/// with a History menu to read any past report (newest → oldest).
struct CompetitorsPageView: View {
    @ObservedObject var store: ArtifactStore

    struct Implications: Equatable {
        let sourceID: String
        let sourceTitle: String
        let text: String
    }

    @State private var selectedReportID: String?
    @State private var content: String?
    @State private var implications: Implications?
    @Environment(\.colorScheme) private var colorScheme

    /// Claude-style warm ivory in light mode, soft elevation in dark.
    private var calloutBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color(red: 0.980, green: 0.976, blue: 0.961)
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
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Competitors", systemImage: "binoculars")
                            .font(.largeTitle.bold())
                        Text(subtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
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
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        .fixedSize()
                        .help("Read past intel reports, newest to oldest")
                    }
                }

                if let implications {
                    Markdown(implications.text)
                        .markdownTheme(.basic)
                        .textSelection(.enabled)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(calloutBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.06)))
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
                                    .markdownTheme(.basic)
                                    .textSelection(.enabled)
                            }
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No intel report yet",
                        systemImage: "doc.richtext",
                        description: Text("Run Competitor Intel from the Discover overview to generate the first report.")
                    )
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .task(id: "\(displayed?.id ?? "none")#\(store.generation)") {
            content = nil
            if let report = displayed {
                content = try? await store.content(of: report)
            }
            guard let intel = latestIntelReport else {
                implications = nil
                return
            }
            if let intelContent = try? await store.content(of: intel),
               let parsed = IntelReportParser.parse(intelContent),
               let section = parsed.sections.first(where: { $0.title.lowercased().contains("strategic implications") }),
               !section.combinedBody.isEmpty {
                implications = Implications(
                    sourceID: intel.id,
                    sourceTitle: CompetitorFiles.reportTitle(intel.relativePath),
                    text: section.combinedBody
                )
            } else {
                implications = nil
            }
        }
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
        .onAppear {
            if selectedSnapshotID == nil { selectedSnapshotID = snapshots.first?.id }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(competitor.name, systemImage: "building.2")
                .font(.largeTitle.bold())
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
                    .markdownTheme(.gitHub)
                    .textSelection(.enabled)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .task(id: "\(artifact.id)#\(store.generation)") {
            content = try? await store.content(of: artifact)
        }
    }
}
