import SwiftUI
import MarkdownUI

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
