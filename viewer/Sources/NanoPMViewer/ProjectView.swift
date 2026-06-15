import SwiftUI
import MarkdownUI

struct ProjectView: View {
    static let runTagPrefix = "run:"
    static let competitorTagPrefix = "competitor:"
    /// Leading indent for documents nested under a phase entry.
    static let childIndent: CGFloat = 14
    /// Row insets driven by `.listRowInsets` (not inner `.padding`) so the
    /// selection capsule and the row content share one geometry — without this
    /// the content visibly nudges when a row becomes selected.
    static let phaseRowInsets = EdgeInsets(top: 6, leading: 10, bottom: 4, trailing: 10)
    static let childRowInsets = EdgeInsets(top: 3, leading: 10 + childIndent, bottom: 3, trailing: 10)

    let project: Project
    let onSwitchProject: () -> Void

    @StateObject private var store: ArtifactStore
    @EnvironmentObject private var runManager: RunManager
    @Environment(\.openWindow) private var openWindow
    @State private var selection: String?
    @State private var competitorsExpanded = false
    @State private var prdsExpanded = false

    private var activeRunCount: Int {
        runManager.runs.filter(\.isActive).count
    }

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.npPaper)
        }
        .task { await store.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await store.refresh() }
        }
        .onChange(of: store.artifacts) { _, newValue in
            if let selection,
               !selection.hasPrefix("overview:"),
               !selection.hasPrefix("page:"),
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

    private var prdArtifacts: [Artifact] {
        store.artifacts
            .filter { PRDFiles.isPRD($0.relativePath) }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack(spacing: 0) {
            projectHeader
            Divider()
            if store.state == .loading {
                SparkleView(size: 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    phaseGroup(.daily)
                    phaseGroup(.define)
                    phaseGroup(.discover)
                    phaseGroup(.plan)
                    phaseGroup(.ship)
                }
                .listStyle(.sidebar)
                .contentMargins(.top, 10, for: .scrollContent)
                .tint(Color.npSelection)
            }
            Divider()
            sidebarFooter
        }
    }

    /// Activity + memory + refresh actions, pinned at the bottom of the nav column.
    private var sidebarFooter: some View {
        HStack(spacing: 14) {
            Button {
                openWindow(id: NanoPMViewerApp.activityWindowID)
            } label: {
                HStack(spacing: 6) {
                    if activeRunCount > 0 {
                        SparkleView(size: 11)
                        Text("\(activeRunCount) running")
                            .font(.caption)
                            .foregroundStyle(Color.npCoral)
                    } else {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.secondary)
                        Text("Activity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.borderless)
            .help(activeRunCount > 0
                  ? "\(activeRunCount) run(s) in progress — open the live activity monitor"
                  : "Open the activity monitor")

            Button {
                selection = NavRoute.memoryPage
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "brain")
                        .foregroundStyle(.secondary)
                    Text("Memory")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .help("What NanoPM remembers about this project — every skill run leaves a trace here")

            Spacer()

            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(ActionButtonStyle())
            .fixedSize()
            .help("Re-read .nanopm/ from disk")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    /// Current project at the top of the sidebar, with the switcher.
    private var projectHeader: some View {
        HStack(spacing: 8) {
            Text(project.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(project.path)
            Spacer()
            Button {
                onSwitchProject()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Switch project")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// Sidebar icon for an artifact — its skill's catalog icon when one owns
    /// the file, else a generic doc/json glyph.
    private func iconFor(_ artifact: Artifact) -> String {
        SkillCatalog.icon(forArtifact: artifact.relativePath)
            ?? (artifact.isMarkdown ? "doc.text" : "curlybraces")
    }

    /// A phase as a clickable entry (no collapse): clicking the row opens the
    /// phase overview; its artifacts and folders sit directly below it.
    @ViewBuilder
    private func phaseGroup(_ phase: Phase) -> some View {
        let items = store.artifacts.filter { artifact in
            artifact.phase == phase
                && !(showCompetitorsSection && CompetitorFiles.isCompetitorFile(artifact.relativePath))
                && !PRDFiles.isPRD(artifact.relativePath)
                // The context brief is rendered inline atop the Define overview,
                // not listed as a child document.
                && artifact.relativePath != "CONTEXT-SUMMARY.md"
                // Reasoning sidecars surface as a pane on their clean doc's
                // detail view, not as sidebar rows.
                && !ReasoningFiles.isReasoning(artifact.relativePath)
        }
        let pending = pendingRuns(for: phase)
        let hasOverview = !SkillCatalog.docs(for: phase).isEmpty
        let showPRDs = phase == .ship && !prdArtifacts.isEmpty
        if hasOverview || !items.isEmpty || !pending.isEmpty || showPRDs {
            Section {
                phaseLabel(phase, hasOverview: hasOverview)
                ForEach(items) { artifact in
                    Label(artifact.displayName, systemImage: iconFor(artifact))
                        .tag(artifact.id)
                        .help(".nanopm/" + artifact.relativePath)
                        .listRowInsets(Self.childRowInsets)
                }
                if showPRDs {
                    prdsEntry.listRowInsets(Self.childRowInsets)
                }
                if phase == .discover && showCompetitorsSection {
                    competitorsEntry.listRowInsets(Self.childRowInsets)
                }
                ForEach(pending, id: \.expectedRelPath) { run in
                    pendingRow(run).listRowInsets(Self.childRowInsets)
                }
            }
        }
    }

    @ViewBuilder
    private func phaseLabel(_ phase: Phase, hasOverview: Bool) -> some View {
        let label = Text(phase.rawValue.uppercased())
            .font(.system(size: 15, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(Color.npCoral)
            .listRowInsets(Self.phaseRowInsets)
        if hasOverview {
            label
                .tag(NavRoute.overview(phase))
                .help("\(phase.rawValue) overview — status and actions")
        } else {
            label
        }
    }

    @ViewBuilder
    private func pendingRow(_ run: RunManager.SkillRun) -> some View {
        HStack(spacing: 6) {
            switch run.status {
            case .running:
                SparkleView(size: 11)
            case .waitingForInput:
                Image(systemName: "questionmark.bubble.fill")
                    .foregroundStyle(Color.npAmber)
            default:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Color.npRust)
            }
            Text(prettyDocName(run.expectedRelPath))
                .foregroundStyle(.secondary)
        }
        .tag(Self.runTagPrefix + run.expectedRelPath)
        .help(sidebarHelp(for: run))
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
                .tag(NavRoute.competitorsPage)
                .help("Latest intel report — expand for per-competitor pages")
        }
    }

    @ViewBuilder
    private var prdsEntry: some View {
        DisclosureGroup(isExpanded: $prdsExpanded) {
            ForEach(prdArtifacts) { prd in
                Label(prettyDocName(prd.relativePath), systemImage: "doc.text")
                    .tag(prd.id)
                    .help(".nanopm/" + prd.relativePath)
            }
        } label: {
            Label("PRDs", systemImage: SkillCatalog.prdsIcon)
                .tag(NavRoute.prdsPage)
                .help("All product specs and their status — expand for each PRD")
        }
    }

    private func overviewPhase(_ id: String) -> Phase? {
        Phase.allCases.first { NavRoute.overview($0) == id }
    }

    @ViewBuilder
    private var detail: some View {
        if let selection, let phase = overviewPhase(selection) {
            PhaseOverviewView(
                phase: phase,
                store: store,
                onOpen: { route in
                    self.selection = (route == "COMPETITORS.md" && showCompetitorsSection)
                        ? NavRoute.competitorsPage
                        : route
                },
                onAnswer: { relPath in self.selection = Self.runTagPrefix + relPath }
            )
        } else if selection == NavRoute.competitorsPage {
            CompetitorsPageView(store: store)
        } else if selection == NavRoute.memoryPage {
            MemoryView(store: store)
        } else if selection == NavRoute.prdsPage {
            PRDsOverviewView(store: store) { artifactID in
                selection = artifactID
            }
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
                    "Pick a phase or document",
                    systemImage: "sidebar.left",
                    description: Text("Click a phase (Discover → Plan → Build) to see its overview, or expand it to open a document.")
                )
            }
        }
    }
}

struct ArtifactDetailView: View {
    enum Pane: String {
        case document = "Document"
        case reasoning = "Reasoning"
    }

    @ObservedObject var store: ArtifactStore
    let artifact: Artifact

    @Environment(\.openWindow) private var openWindow
    @State private var content: String?
    @State private var loadError: String?
    @State private var pane: Pane = .document

    /// The reasoning sidecar paired with this doc, when one exists on disk.
    private var reasoningArtifact: Artifact? {
        guard !ReasoningFiles.isReasoning(artifact.relativePath) else { return nil }
        let sidecar = ReasoningFiles.sidecarPath(for: artifact.relativePath)
        return store.artifacts.first { $0.relativePath == sidecar }
    }

    /// What the body actually renders — the doc, or its reasoning sidecar.
    private var shownArtifact: Artifact {
        pane == .reasoning ? (reasoningArtifact ?? artifact) : artifact
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(artifact.displayName)
                            .font(.npDisplay(30))
                            .foregroundStyle(Color.npInk)
                            .textSelection(.enabled)
                        Spacer()
                        if let reasoning = reasoningArtifact {
                            ActionButton(
                                title: "Reasoning",
                                systemImage: "brain",
                                tone: pane == .reasoning ? .accent : .neutral,
                                prominent: pane == .reasoning,
                                help: "Reasoning: why each section was written this way — what's evidenced vs assumed, and the sources"
                            ) {
                                pane = (pane == .reasoning) ? .document : .reasoning
                            }
                            Button {
                                openWindow(
                                    id: NanoPMViewerApp.reasoningWindowID,
                                    value: ReasoningWindowContext(
                                        absolutePath: store.project.nanopmPath + "/" + reasoning.relativePath,
                                        docName: artifact.displayName
                                    )
                                )
                            } label: {
                                Image(systemName: "macwindow.on.rectangle")
                            }
                            .buttonStyle(ActionButtonStyle())
                            .help("Open the reasoning in a separate window, to read alongside the document")
                        }
                    }
                    HStack(spacing: 6) {
                        Text(".nanopm/" + shownArtifact.relativePath)
                            .font(.system(.footnote, design: .monospaced))
                        Text("·")
                        Text("updated \(shownArtifact.modifiedAt, format: .relative(presentation: .named))")
                            .font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                }

                Divider().overlay(Color.npBorder)

                if let loadError {
                    ContentUnavailableView(
                        "Couldn't read file",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if let content {
                    Markdown(shownArtifact.isMarkdown ? content : "```json\n\(content)\n```")
                        .markdownTheme(.nanopm)
                        .textSelection(.enabled)
                } else {
                    SparkleView(size: 18)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .task(id: "\(shownArtifact.id)#\(store.generation)") {
            await load()
        }
        .onChange(of: artifact.id) { _, _ in
            pane = .document
        }
    }

    private func load() async {
        do {
            content = try await store.content(of: shownArtifact)
            loadError = nil
        } catch {
            content = nil
            loadError = "\(error)"
        }
    }
}
