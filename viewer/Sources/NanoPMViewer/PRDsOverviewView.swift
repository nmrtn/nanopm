import SwiftUI

/// Recap page for the PRDs folder: every PRD with its parsed status, opening
/// into the individual PRD on click.
struct PRDsOverviewView: View {
    @ObservedObject var store: ArtifactStore
    /// Opens a PRD's full detail by artifact id (relative path).
    let onOpen: (String) -> Void

    struct Row: Identifiable {
        let artifact: Artifact
        let title: String
        let status: String?
        let date: String?
        var id: String { artifact.id }
    }

    @State private var rows: [Row] = []
    @State private var loaded = false

    private var prds: [Artifact] {
        store.artifacts
            .filter { PRDFiles.isPRD($0.relativePath) }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("PRDs", systemImage: "doc.text.fill")
                        .font(.largeTitle.bold())
                    Text(prds.count == 1 ? "1 product spec" : "\(prds.count) product specs")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if prds.isEmpty {
                    ContentUnavailableView(
                        "No PRDs yet",
                        systemImage: "doc.badge.plus",
                        description: Text("Run /pm-prd in your agent to write a product spec — it lands in .nanopm/prds/.")
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(displayRows) { row in
                            Button { onOpen(row.artifact.id) } label: {
                                rowView(row)
                            }
                            .buttonStyle(.plain)
                            if row.id != displayRows.last?.id { Divider() }
                        }
                    }
                    .background(.quinary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .task(id: "\(prds.map(\.id).joined())#\(store.generation)") {
            await loadRows()
        }
    }

    /// Parsed rows when available; otherwise a filename-only fallback so the
    /// list never appears empty while loading.
    private var displayRows: [Row] {
        loaded ? rows : prds.map {
            Row(artifact: $0, title: prettyDocName($0.relativePath), status: nil, date: nil)
        }
    }

    private func rowView(_ row: Row) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "doc.text")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.title).font(.headline)
                HStack(spacing: 6) {
                    Text(row.artifact.fileName)
                    if let date = row.date { Text("· \(date)") }
                    Text("· updated \(row.artifact.modifiedAt, format: .relative(presentation: .named))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            StatusBadge(status: row.status)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private func loadRows() async {
        var result: [Row] = []
        for prd in prds {
            let content = (try? await store.content(of: prd)) ?? ""
            let parsed = PRDFiles.summary(from: content, fallbackName: prettyDocName(prd.relativePath))
            result.append(Row(artifact: prd, title: parsed.title, status: parsed.status, date: parsed.date))
        }
        rows = result
        loaded = true
    }
}

/// Colored pill for a PRD status (DRAFT / READY / SHIPPED / …).
struct StatusBadge: View {
    let status: String?

    private var tint: Color {
        switch (status ?? "").uppercased() {
        case "DRAFT": return .orange
        case "READY", "APPROVED": return .green
        case "SHIPPED", "DONE": return .blue
        case "ARCHIVED": return .secondary
        default: return .secondary
        }
    }

    var body: some View {
        if let status, !status.isEmpty {
            Text(status.uppercased())
                .font(.caption2.weight(.semibold))
                .kerning(0.4)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tint.opacity(0.15), in: Capsule())
                .foregroundStyle(tint)
        }
    }
}
