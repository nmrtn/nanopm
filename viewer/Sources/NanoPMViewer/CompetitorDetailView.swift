import SwiftUI
import MarkdownUI

/// Landing page for the Competitors entry: the latest intel report rendered,
/// with a History menu to read any past report (newest → oldest).
struct CompetitorsPageView: View {
    @ObservedObject var store: ArtifactStore

    @State private var selectedReportID: String?

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

                if let report = displayed {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(".nanopm/\(report.relativePath) · updated \(report.modifiedAt, format: .relative(presentation: .named))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Divider()
                        MarkdownFileView(store: store, artifact: report)
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
