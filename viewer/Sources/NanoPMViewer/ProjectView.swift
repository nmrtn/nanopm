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
    @State private var opportunitiesExpanded = false
    @State private var weeklyUpdatesExpanded = false
    @State private var standupsExpanded = false
    // Which phases have their "Entities" group expanded (entities appear in several
    // phases, so a single bool would toggle them all together).
    @State private var expandedEntityPhases: Set<Phase> = []
    // Settings → "Display entities": hide the wiki entity groups from the nav when off.
    @AppStorage(AppSettings.displayEntities) private var displayEntities = true

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
               !selection.hasPrefix(NavRoute.seriesPrefix),
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
        // Brainstorm runs produce no artifact — they never belong in a phase's
        // pending-document rows (they live in the Brainstorm surface instead).
        for run in runManager.runs(in: project.path) where run.kind == .skill {
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

    /// True when the Discovery Opportunity DB has any files — it gets its own
    /// expandable nav entry instead of a flat row per opportunity.
    private var showOpportunitiesSection: Bool {
        store.artifacts.contains { OpportunityFiles.isOpportunityFile($0.relativePath) }
    }

    /// Children of the "Opportunities" entry: the individual opportunities only
    /// (alphabetical). INDEX is the entry's landing; LOG and SCHEMA are DB
    /// machinery and stay out of the nav entirely.
    private var opportunityChildren: [Artifact] {
        store.artifacts
            .filter { OpportunityFiles.isOpportunityFile($0.relativePath) && !OpportunityFiles.isReserved($0.relativePath) }
            .sorted { $0.relativePath.lowercased() < $1.relativePath.lowercased() }
    }

    /// Dated-series folders under wiki/docs/ (weekly-updates/, standups/) — one page
    /// per period, each grouped under a single expandable entry in DAY TO DAY (newest
    /// first) instead of a flat row per date. Detection is by folder prefix, the same
    /// way PhaseMapper routes them — structural, not a filename heuristic.
    private static let datedSeriesPrefixes = ["wiki/docs/weekly-updates/", "wiki/docs/standups/"]

    private func isDatedSeriesDoc(_ relativePath: String) -> Bool {
        let l = relativePath.lowercased()
        return Self.datedSeriesPrefixes.contains { l.hasPrefix($0) }
    }

    /// Pages under one series folder, newest first (by the ISO date in the filename).
    private func seriesArtifacts(prefix: String) -> [Artifact] {
        store.artifacts
            .filter { $0.relativePath.lowercased().hasPrefix(prefix) }
            .sorted { (datedSuffix($0.relativePath) ?? "") > (datedSuffix($1.relativePath) ?? "") }
    }

    /// The ISO date a dated page carries in its filename (`…/2026-06-15.md` ->
    /// `"2026-06-15"`) — a tidy child label and the newest-first sort key. Nil for an
    /// undated file (which then sorts last).
    private func datedSuffix(_ relativePath: String) -> String? {
        let stem = ((relativePath as NSString).lastPathComponent as NSString).deletingPathExtension
        guard let r = stem.range(of: #"\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) else { return nil }
        return String(stem[r])
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
                    // Catch-all for markdown that maps to no phase. Renders only
                    // when such files exist (phaseGroup self-hides when empty).
                    phaseGroup(.other)
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
                // The context & plan briefs are rendered inline atop their phase
                // overviews (Define / Plan), not listed as child documents.
                // Case-insensitive (isPhaseBrief): a brief written as
                // plan-summary.md must still be excluded here and found by its card.
                && !artifact.isPhaseBrief
                // Reasoning sidecars open from a "Reasoning" button on their
                // clean doc's detail view, not as sidebar rows.
                && !ReasoningFiles.isReasoning(artifact.relativePath)
                // Opportunity DB files are grouped under one expandable
                // "Opportunities" entry (INDEX is the landing), not flat rows.
                && !(showOpportunitiesSection && OpportunityFiles.isOpportunityFile(artifact.relativePath))
                // Wiki entity pages collapse under a per-phase "Entities" group, not
                // ~18 flat rows. They're the substrate behind the briefs.
                && !artifact.relativePath.lowercased().hasPrefix("wiki/entities/")
                // Dated-series pages (weekly updates, standups) collapse under one
                // entry per series in DAY TO DAY (newest first), not a flat row per date.
                && !isDatedSeriesDoc(artifact.relativePath)
        }
        let entities = entityArtifacts(for: phase)
        // Settings → "Display entities" hides the entity groups from the nav (the
        // entity pages stay out of the flat rows either way — they're the substrate).
        let showEntities = displayEntities && !entities.isEmpty
        let pending = pendingRuns(for: phase)
        let hasOverview = !SkillCatalog.docs(for: phase).isEmpty
        let showPRDs = phase == .ship && !prdArtifacts.isEmpty
        // Brainstorm is an always-on interactive surface (not artifact-driven),
        // pinned at the top of DAY TO DAY so it's always reachable.
        let showBrainstorm = phase == .daily
        if hasOverview || !items.isEmpty || showEntities || !pending.isEmpty || showPRDs || showBrainstorm {
            Section {
                phaseLabel(phase, hasOverview: hasOverview)
                if showBrainstorm {
                    Label("Brainstorm", systemImage: "bubble.left.and.bubble.right")
                        .tag(NavRoute.brainstormPage)
                        .help("Jam with Nano, your expert CPO — informal, context-loaded, resumable")
                        .listRowInsets(Self.childRowInsets)
                }
                ForEach(items) { artifact in
                    Label(artifact.displayName, systemImage: iconFor(artifact))
                        .tag(artifact.id)
                        .help(".nanopm/" + artifact.relativePath)
                        .listRowInsets(Self.childRowInsets)
                }
                if showEntities {
                    entitiesEntry(phase: phase, entities: entities).listRowInsets(Self.childRowInsets)
                }
                if phase == .daily {
                    let weeklies = seriesArtifacts(prefix: "wiki/docs/weekly-updates/")
                    if !weeklies.isEmpty {
                        datedSeriesEntry(title: "Weekly Updates", icon: "envelope",
                                         artifacts: weeklies, isExpanded: $weeklyUpdatesExpanded)
                            .listRowInsets(Self.childRowInsets)
                    }
                    let standups = seriesArtifacts(prefix: "wiki/docs/standups/")
                    if !standups.isEmpty {
                        datedSeriesEntry(title: "Standups", icon: "sunrise",
                                         artifacts: standups, isExpanded: $standupsExpanded)
                            .listRowInsets(Self.childRowInsets)
                    }
                }
                if showPRDs {
                    prdsEntry.listRowInsets(Self.childRowInsets)
                }
                if phase == .discover && showOpportunitiesSection {
                    opportunitiesEntry.listRowInsets(Self.childRowInsets)
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

    private func entityArtifacts(for phase: Phase) -> [Artifact] {
        store.artifacts.filter {
            $0.phase == phase && $0.relativePath.lowercased().hasPrefix("wiki/entities/")
        }
    }

    /// Wiki entity pages collapse under one "Entities" group per phase, so the nav
    /// shows the canonical docs + curated sections instead of a flat row per entity.
    @ViewBuilder
    private func entitiesEntry(phase: Phase, entities: [Artifact]) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { expandedEntityPhases.contains(phase) },
            set: { expanded in
                if expanded { expandedEntityPhases.insert(phase) }
                else { expandedEntityPhases.remove(phase) }
            }
        )) {
            ForEach(entities) { entity in
                Label(entity.displayName, systemImage: iconFor(entity))
                    .tag(entity.id)
                    .help(".nanopm/" + entity.relativePath)
                    .listRowInsets(Self.childRowInsets)
            }
        } label: {
            Label("Entities (\(entities.count))", systemImage: "square.grid.2x2")
                .help("Wiki entity pages — the substrate behind the briefs (personas, competitors, features, …)")
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

    @ViewBuilder
    private var opportunitiesEntry: some View {
        DisclosureGroup(isExpanded: $opportunitiesExpanded) {
            ForEach(opportunityChildren) { opp in
                Label(prettyDocName(opp.relativePath), systemImage: iconFor(opp))
                    .tag(opp.id)
                    .help(".nanopm/" + opp.relativePath)
            }
        } label: {
            Label("Opportunities", systemImage: SkillCatalog.opportunitiesIcon)
                .tag(NavRoute.opportunitiesPage)
                .help("Ranked user-opportunity database (Teresa Torres) — opens the ranked table; expand for each opportunity")
        }
    }

    /// A dated-series folder (weekly updates, standups) collapses under one entry,
    /// newest first, instead of a flat row per date. The label just toggles the list
    /// (no landing page), like the per-phase "Entities" group.
    @ViewBuilder
    private func datedSeriesEntry(title: String, icon: String, artifacts: [Artifact],
                                  isExpanded: Binding<Bool>) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            ForEach(artifacts) { a in
                Label(datedSuffix(a.relativePath) ?? a.displayName, systemImage: iconFor(a))
                    .tag(a.id)
                    .help(".nanopm/" + a.relativePath)
            }
        } label: {
            Label(title, systemImage: icon)
                .help("\(title) — most recent first")
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
                    self.selection = (CompetitorFiles.isLandscape(route) && showCompetitorsSection)
                        ? NavRoute.competitorsPage
                        : route
                },
                onAnswer: { relPath in self.selection = Self.runTagPrefix + relPath }
            )
        } else if selection == NavRoute.competitorsPage {
            CompetitorsPageView(store: store)
        } else if selection == NavRoute.memoryPage {
            MemoryView(store: store)
        } else if selection == NavRoute.brainstormPage {
            BrainstormView(projectPath: project.path)
        } else if selection == NavRoute.prdsPage {
            PRDsOverviewView(store: store) { artifactID in
                selection = artifactID
            }
        } else if selection == NavRoute.opportunitiesPage {
            OpportunitiesOverviewView(
                store: store,
                onOpen: { artifactID in selection = artifactID },
                onAnswer: { relPath in selection = Self.runTagPrefix + relPath }
            )
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
        } else if let selection,
                  OpportunityFiles.isOpportunityFile(selection),
                  !OpportunityFiles.isReserved(selection),
                  let opp = store.artifacts.first(where: { $0.id == selection }) {
            OpportunityDetailView(store: store, artifact: opp) { id in self.selection = id }
        } else if let selection,
                  selection.hasPrefix(NavRoute.seriesPrefix),
                  let newest = seriesArtifacts(
                      prefix: String(selection.dropFirst(NavRoute.seriesPrefix.count)).lowercased()
                  ).first {
            // A dated-series card ("N documents") opens the most recent page; the
            // sidebar's series entry is where you browse the full list.
            ArtifactDetailView(store: store, artifact: newest,
                               onAnswer: { relPath in self.selection = Self.runTagPrefix + relPath },
                               onOpenArtifact: { id in self.selection = id })
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
                ArtifactDetailView(store: store, artifact: artifact,
                                   onAnswer: { relPath in selection = Self.runTagPrefix + relPath },
                                   onOpenArtifact: { id in selection = id })
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
    @ObservedObject var store: ArtifactStore
    let artifact: Artifact
    /// Navigate to the live run session when a launched skill needs input.
    var onAnswer: (String) -> Void = { _ in }
    /// Navigate to another artifact when an in-repo markdown link is clicked
    /// (e.g. an opportunity link in the opportunities INDEX).
    var onOpenArtifact: (String) -> Void = { _ in }

    @Environment(\.openWindow) private var openWindow
    @State private var content: String?
    @State private var loadError: String?
    @State private var claudeAvailable: Bool?

    /// The skill that produces this document, so it can be re-run from here —
    /// the same Run action as the phase overview. Nil for docs no skill owns.
    private var runDoc: SkillDoc? {
        SkillCatalog.doc(forArtifact: artifact.relativePath)
            .flatMap { $0.skillCommand == nil ? nil : $0 }
    }

    /// Where the "Reasoning" window reads from, as a path relative to .nanopm/.
    /// Wiki-canonical: this doc page itself when its provenance is folded inline
    /// (the window extracts the "## Provenance & assumptions" section). Legacy:
    /// a separate `reasoning/<doc>.md` sidecar if one exists on disk. Nil when the
    /// doc has neither, so the button doesn't show.
    private var reasoningSourcePath: String? {
        if let content, ReasoningFiles.hasProvenance(content) {
            return artifact.relativePath
        }
        guard !ReasoningFiles.isReasoning(artifact.relativePath) else { return nil }
        let sidecar = ReasoningFiles.sidecarPath(for: artifact.relativePath)
        return store.artifacts.first { $0.relativePath == sidecar }?.relativePath
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
                        if let runDoc {
                            SkillRunButton(doc: runDoc, store: store,
                                           claudeAvailable: claudeAvailable, onAnswer: onAnswer)
                        }
                        if let reasoningPath = reasoningSourcePath {
                            ActionButton(
                                title: "Reasoning",
                                systemImage: "macwindow.on.rectangle",
                                help: "Open the reasoning in a separate window — why each section was written this way, what's evidenced vs assumed, and the sources"
                            ) {
                                openWindow(
                                    id: NanoPMViewerApp.reasoningWindowID,
                                    value: ReasoningWindowContext(
                                        absolutePath: store.project.nanopmPath + "/" + reasoningPath,
                                        docName: artifact.displayName
                                    )
                                )
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        Text(".nanopm/" + artifact.relativePath)
                            .font(.system(.footnote, design: .monospaced))
                        Text("·")
                        Text("updated \(artifact.modifiedAt, format: .relative(presentation: .named))")
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
                    Markdown(artifact.isMarkdown ? content : "```json\n\(content)\n```")
                        .markdownTheme(.nanopm)
                        .textSelection(.enabled)
                        .environment(\.openURL, OpenURLAction { url in
                            // In-repo relative links (e.g. an opportunity link in the
                            // opportunities INDEX) navigate in-app; http(s) open the browser.
                            if url.scheme == nil || url.isFileURL {
                                if let id = inRepoArtifactID(for: url) {
                                    onOpenArtifact(id)
                                    return .handled
                                }
                                return .discarded
                            }
                            return .systemAction
                        })
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
        .task(id: "\(artifact.id)#\(store.generation)") {
            await load()
        }
        .task { claudeAvailable = await ShellRunner.claudeAvailable() }
    }

    private func load() async {
        do {
            // Strip leading YAML frontmatter so wiki entity/overview pages render as
            // prose, not a "key: value …" metadata block.
            content = stripFrontmatter(try await store.content(of: artifact))
            loadError = nil
        } catch {
            content = nil
            loadError = "\(error)"
        }
    }

    /// Resolves a markdown link to a scanned artifact id, relative to this
    /// document's directory. Nil for absolute or unknown links.
    private func inRepoArtifactID(for url: URL) -> String? {
        let raw = url.isFileURL ? url.path : url.absoluteString
        let linkPath = raw.split(separator: "#", maxSplits: 1).first.map(String.init) ?? raw
        guard !linkPath.isEmpty else { return nil }
        let dir = (artifact.relativePath as NSString).deletingLastPathComponent
        let combined = dir.isEmpty ? linkPath : "\(dir)/\(linkPath)"
        let target = (combined as NSString).standardizingPath
        return store.artifacts.first { $0.relativePath == target }?.id
    }
}
