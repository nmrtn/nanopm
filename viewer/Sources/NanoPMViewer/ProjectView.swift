import SwiftUI
import MarkdownUI

struct ProjectView: View {
    static let discoverOverviewID = "overview:discover"
    static let competitorsPageID = "page:competitors"
    static let runTagPrefix = "run:"
    static let competitorTagPrefix = "competitor:"

    let project: Project
    let onSwitchProject: () -> Void

    @StateObject private var store: ArtifactStore
    @EnvironmentObject private var runManager: RunManager
    @State private var selection: String?
    @State private var competitorsExpanded = false

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
                .textSelection(.enabled)
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
               selection != Self.competitorsPageID,
               !selection.hasPrefix(Self.runTagPrefix),
               !selection.hasPrefix(Self.competitorTagPrefix),
               !newValue.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
        }
        .onChange(of: runManager.completionTick) { _, _ in
            Task { await store.refresh() }
        }
    }

    private func sidebarHelp(for run: RunManager.SkillRun) -> String {
        switch run.status {
        case .running: return "\(run.skillCommand) is generating this document"
        case .waitingForInput: return "\(run.skillCommand) needs your input"
        default: return "\(run.skillCommand) failed"
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

    /// True when competitor intel artifacts get their own nav section.
    private var showCompetitorsSection: Bool {
        !store.competitors.isEmpty || hasCompetitorReports
    }

    private var hasCompetitorReports: Bool {
        store.artifacts.contains { CompetitorFiles.isReport($0.relativePath) }
    }

    @ViewBuilder
    private var sidebar: some View {
        if store.state == .loading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selection) {
                phaseSection(.discover)
                phaseSection(.plan)
                phaseSection(.ship)
                phaseSection(.other)
            }
            .listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private func phaseSection(_ phase: Phase) -> some View {
        let items = store.artifacts.filter { artifact in
            artifact.phase == phase
                && !(showCompetitorsSection && CompetitorFiles.isCompetitorFile(artifact.relativePath))
        }
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
                if phase == .discover && showCompetitorsSection {
                    competitorsEntry
                }
                ForEach(pending, id: \.expectedRelPath) { run in
                    HStack(spacing: 6) {
                        switch run.status {
                        case .running:
                            ProgressView().controlSize(.small)
                        case .waitingForInput:
                            Image(systemName: "questionmark.bubble.fill")
                                .foregroundStyle(.orange)
                        default:
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                        Text(prettyDocName(run.expectedRelPath))
                            .foregroundStyle(.secondary)
                    }
                    .tag(Self.runTagPrefix + run.expectedRelPath)
                    .help(sidebarHelp(for: run))
                }
            } header: {
                Label(phase.rawValue, systemImage: phase.icon)
            }
        }
    }

    @ViewBuilder
    private var competitorsEntry: some View {
        DisclosureGroup(isExpanded: $competitorsExpanded) {
            ForEach(store.competitors) { competitor in
                Label(competitor.name, systemImage: "building.2")
                    .tag(Self.competitorTagPrefix + competitor.slug)
                    .help("Snapshots and monitored pages for \(competitor.name)")
            }
        } label: {
            Label("Competitors", systemImage: "binoculars")
                .tag(Self.competitorsPageID)
                .help("Latest intel report — expand for per-competitor pages")
        }
    }

    @ViewBuilder
    private var detail: some View {
        if selection == Self.discoverOverviewID {
            DiscoverOverviewView(
                store: store,
                onOpen: { artifactID in
                    selection = (artifactID == "COMPETITORS.md" && showCompetitorsSection)
                        ? Self.competitorsPageID
                        : artifactID
                },
                onAnswer: { relPath in selection = Self.runTagPrefix + relPath }
            )
        } else if selection == Self.competitorsPageID {
            CompetitorsPageView(store: store)
        } else if let selection,
                  selection.hasPrefix(Self.runTagPrefix),
                  let run = runManager.latestRun(for: String(selection.dropFirst(Self.runTagPrefix.count)),
                                                 in: project.path) {
            RunSessionView(run: run) { artifactID in
                self.selection = artifactID
            }
        } else if let selection,
                  selection.hasPrefix(Self.competitorTagPrefix),
                  let competitor = store.competitors.first(where: {
                      $0.slug == String(selection.dropFirst(Self.competitorTagPrefix.count))
                  }) {
            CompetitorDetailView(store: store, competitor: competitor)
                .id(competitor.slug)
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
