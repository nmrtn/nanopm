import SwiftUI
import MarkdownUI

struct ProjectView: View {
    let project: Project
    let onSwitchProject: () -> Void

    @StateObject private var store: ArtifactStore
    @State private var selection: String?

    init(project: Project, onSwitchProject: @escaping () -> Void) {
        self.project = project
        self.onSwitchProject = onSwitchProject
        _store = StateObject(wrappedValue: ArtifactStore(project: project))
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            detail
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    onSwitchProject()
                } label: {
                    Label("Projects", systemImage: "chevron.backward")
                }
                .help("Back to the project picker")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Re-read .nanopm/ from disk")
            }
        }
        .task { await store.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await store.refresh() }
        }
        .onChange(of: store.artifacts) { _, newValue in
            if let selection, !newValue.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if store.state == .loading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selection) {
                ForEach(Phase.allCases) { phase in
                    let items = store.artifacts.filter { $0.phase == phase }
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { artifact in
                                Label(artifact.displayName, systemImage: artifact.isMarkdown ? "doc.text" : "curlybraces")
                                    .tag(artifact.id)
                                    .help(".nanopm/" + artifact.relativePath)
                            }
                        } header: {
                            Label(phase.rawValue, systemImage: phase.icon)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch store.state {
        case .missingNanopm:
            ContentUnavailableView(
                "No NanoPM artifacts here",
                systemImage: "folder.badge.questionmark",
                description: Text("“\(project.name)” has no .nanopm/ folder yet.\nRun a NanoPM skill in your agent (e.g. /pm-run), then refresh.")
            )
        case .error(let message):
            ContentUnavailableView(
                "Couldn't read .nanopm",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded where store.artifacts.isEmpty:
            ContentUnavailableView(
                "Nothing here yet",
                systemImage: "tray",
                description: Text(".nanopm/ exists but holds no artifacts. Run a NanoPM skill to generate some.")
            )
        default:
            if let artifact = store.artifacts.first(where: { $0.id == selection }) {
                ArtifactDetailView(store: store, artifact: artifact)
            } else {
                ContentUnavailableView(
                    "Select an artifact",
                    systemImage: "sidebar.left",
                    description: Text("Pick a document from the sidebar.\nDiscover → Plan → Ship.")
                )
            }
        }
    }
}

struct ArtifactDetailView: View {
    @ObservedObject var store: ArtifactStore
    let artifact: Artifact

    @State private var content: String?
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.displayName)
                        .font(.largeTitle.bold())
                        .textSelection(.enabled)
                    HStack(spacing: 6) {
                        Text(".nanopm/" + artifact.relativePath)
                        Text("·")
                        Text("updated \(artifact.modifiedAt, format: .relative(presentation: .named))")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                Divider()

                if let loadError {
                    ContentUnavailableView(
                        "Couldn't read file",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if let content {
                    Markdown(artifact.isMarkdown ? content : "```json\n\(content)\n```")
                        .markdownTheme(.gitHub)
                        .textSelection(.enabled)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .task(id: "\(artifact.id)#\(store.generation)") {
            await load()
        }
    }

    private func load() async {
        do {
            content = try await store.content(of: artifact)
            loadError = nil
        } catch {
            content = nil
            loadError = "\(error)"
        }
    }
}
