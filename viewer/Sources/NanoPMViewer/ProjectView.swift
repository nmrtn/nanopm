import SwiftUI
import MarkdownUI

struct ProjectView: View {
    static let discoverOverviewID = "overview:discover"
    private static let runTagPrefix = "run:"

    let project: Project
    let onSwitchProject: () -> Void

    @StateObject private var store: ArtifactStore
    @EnvironmentObject private var runManager: RunManager
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
            if let selection,
               selection != Self.discoverOverviewID,
               !selection.hasPrefix(Self.runTagPrefix),
               !newValue.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
        }
        .onChange(of: runManager.completionTick) { _, _ in
            Task { await store.refresh() }
        }
    }

    /// Active or failed runs whose artifact isn't on disk yet — shown as
    /// placeholder rows in the phase they will land in.
    private func pendingRuns(for phase: Phase) -> [RunManager.SkillRun] {
        var latestByPath: [String: RunManager.SkillRun] = [:]
        for run in runManager.runs(in: project.path) {
            latestByPath[run.expectedRelPath] = run
        }
        return latestByPath.values
            .filter { $0.status != .succeeded }
            .filter { PhaseMapper.phase(for: $0.expectedRelPath) == phase }
            .filter { run in !store.artifacts.contains { $0.relativePath == run.expectedRelPath } }
            .sorted { $0.expectedRelPath < $1.expectedRelPath }
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
                    let pending = pendingRuns(for: phase)
                    if phase == .discover || !items.isEmpty || !pending.isEmpty {
                        Section {
                            if phase == .discover {
                                Label("Overview", systemImage: "square.grid.2x2")
                                    .tag(Self.discoverOverviewID)
                                    .help("Discover phase recap — status and actions")
                            }
                            ForEach(items) { artifact in
                                Label(artifact.displayName, systemImage: artifact.isMarkdown ? "doc.text" : "curlybraces")
                                    .tag(artifact.id)
                                    .help(".nanopm/" + artifact.relativePath)
                            }
                            ForEach(pending, id: \.expectedRelPath) { run in
                                HStack(spacing: 6) {
                                    if run.status == .running {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(.orange)
                                    }
                                    Text(prettyDocName(run.expectedRelPath))
                                        .foregroundStyle(.secondary)
                                }
                                .tag(Self.runTagPrefix + run.expectedRelPath)
                                .help(run.status == .running
                                      ? "\(run.skillCommand) is generating this document"
                                      : "\(run.skillCommand) failed")
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
        if selection == Self.discoverOverviewID {
            DiscoverOverviewView(store: store) { artifactID in
                selection = artifactID
            }
        } else if let selection,
                  selection.hasPrefix(Self.runTagPrefix),
                  let run = runManager.latestRun(for: String(selection.dropFirst(Self.runTagPrefix.count)),
                                                 in: project.path) {
            RunStatusView(run: run)
        } else {
            stateDetail
        }
    }

    @ViewBuilder
    private var stateDetail: some View {
        switch store.state {
        case .missingNanopm:
            ContentUnavailableView(
                "No NanoPM artifacts here",
                systemImage: "folder.badge.questionmark",
                description: Text("“\(project.name)” has no .nanopm/ folder yet.\nRun a NanoPM skill in your agent (e.g. /pm-run), then refresh — or open the Discover overview to launch one from here.")
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
