import SwiftUI
import MarkdownUI

// MARK: - Model

/// One opportunity, parsed from its `.nanopm/opportunities/<slug>.md` frontmatter
/// (the schema `/pm-opportunities` writes). Drives both the ranked table and the
/// per-opportunity detail header.
struct Opportunity: Identifiable {
    let artifact: Artifact
    let title: String
    let theme: String
    let priority: String      // high | medium | low | ""
    let provenance: String    // nano-hypothesis | user-stated | evidence-backed | ""
    let status: String        // draft | defining | review | ready-for-solutions | ""
    let summary: String       // first line of "## 1. Problem summary"

    var id: String { artifact.id }
    var lastUpdated: Date { artifact.modifiedAt }

    /// Sort key so high ranks above medium above low (unknown last).
    var priorityOrder: Int { ["high": 0, "medium": 1, "low": 2][priority] ?? 3 }
}

enum OpportunityParser {
    /// Parses the YAML-ish frontmatter + the one-line problem summary.
    static func parse(_ content: String, artifact: Artifact) -> Opportunity {
        let lines = content.components(separatedBy: "\n")
        var fm: [String: String] = [:]
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---" {
            for line in lines.dropFirst() {
                let t = line.trimmingCharacters(in: .whitespaces)
                if t == "---" { break }
                guard let colon = t.firstIndex(of: ":") else { continue }
                let key = String(t[..<colon]).trimmingCharacters(in: .whitespaces)
                var val = String(t[t.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                if let first = val.first, first == "\"" || first == "'" {
                    if let end = val.dropFirst().firstIndex(of: first) {
                        val = String(val[val.index(after: val.startIndex)..<end])
                    }
                } else if let hash = val.range(of: " #") {   // strip inline comment
                    val = String(val[..<hash.lowerBound]).trimmingCharacters(in: .whitespaces)
                }
                fm[key] = val
            }
        }
        var summary = ""
        if let r = content.range(of: #"(?m)^##\s*(?:1\.\s*)?Problem summary\s*$"#, options: .regularExpression) {
            for line in content[r.upperBound...].components(separatedBy: "\n") {
                let s = line.trimmingCharacters(in: .whitespaces)
                if s.isEmpty || s.hasPrefix("#") || s.hasPrefix("<") { continue }
                summary = s
                break
            }
        }
        return Opportunity(
            artifact: artifact,
            title: fm["title"] ?? prettyDocName(artifact.relativePath),
            theme: fm["theme"]?.isEmpty == false ? fm["theme"]! : "Untriaged",
            priority: (fm["priority"] ?? "").lowercased(),
            provenance: (fm["provenance"] ?? "").lowercased(),
            status: (fm["status"] ?? "").lowercased(),
            summary: summary
        )
    }

    /// Strips a leading `---…---` frontmatter block so the body renders cleanly.
    static func strippedBody(_ content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return content }
        var i = 1
        while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces) != "---" { i += 1 }
        guard i < lines.count else { return content }
        return lines[(i + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Badges

func opportunityPriorityTint(_ v: String) -> Color {
    switch v { case "high": return .npCoral; case "medium": return .npAmber; case "low": return .secondary; default: return .secondary }
}
func opportunityProvenanceTint(_ v: String) -> Color {
    switch v { case "evidence-backed": return .npOlive; case "user-stated": return .npAmber; case "nano-hypothesis": return .secondary; default: return .secondary }
}
func opportunityStatusTint(_ v: String) -> Color {
    switch v { case "ready-for-solutions": return .npOlive; case "review": return .npCoral; case "defining": return .npAmber; default: return .secondary }
}

/// Colored capsule for an opportunity attribute (priority / provenance / status).
struct OpportunityBadge: View {
    let text: String
    let tint: Color
    var body: some View {
        if text.isEmpty {
            Text("—").font(.caption).foregroundStyle(.tertiary)
        } else {
            Text(text)
                .font(.caption2.weight(.semibold))
                .kerning(0.3)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(tint.opacity(0.15), in: Capsule())
                .foregroundStyle(tint)
        }
    }
}

/// Resolves a relative markdown link to a scanned artifact id (for in-app
/// navigation from an opportunity body). Nil for absolute/unknown links.
func resolveInRepoArtifactID(_ url: URL, from currentRelPath: String, in artifacts: [Artifact]) -> String? {
    let raw = url.isFileURL ? url.path : url.absoluteString
    let linkPath = raw.split(separator: "#", maxSplits: 1).first.map(String.init) ?? raw
    guard !linkPath.isEmpty else { return nil }
    let dir = (currentRelPath as NSString).deletingLastPathComponent
    let combined = dir.isEmpty ? linkPath : "\(dir)/\(linkPath)"
    let target = (combined as NSString).standardizingPath
    return artifacts.first { $0.relativePath == target }?.id
}

// MARK: - Ranked table

/// The "Opportunities" landing: a sortable table of every opportunity, ranked
/// by priority. Clicking a row opens that opportunity's detail.
struct OpportunitiesOverviewView: View {
    @ObservedObject var store: ArtifactStore
    let onOpen: (String) -> Void
    /// Navigate to the live run session when a launched run needs input.
    var onAnswer: (String) -> Void = { _ in }

    @EnvironmentObject private var runManager: RunManager
    @State private var opportunities: [Opportunity] = []
    /// opportunity-slug → count of child solutions, for the per-row count badge.
    @State private var solutionCounts: [String: Int] = [:]
    @State private var loaded = false
    @State private var selection: Opportunity.ID?
    @State private var claudeAvailable: Bool?
    @State private var showAddSheet = false
    @State private var sortOrder = [
        KeyPathComparator(\Opportunity.priorityOrder, order: .forward),
        KeyPathComparator(\Opportunity.theme, order: .forward),
    ]

    /// The catalog skill that owns this page, so the Run menu reuses the same
    /// launch machinery (RunManager + headless `claude`) as every other skill.
    private var oppDoc: SkillDoc? { SkillCatalog.all.first { $0.skillCommand == "/pm-opportunities" } }

    /// No `SCHEMA.md` means the DB isn't bootstrapped yet — the menu collapses to
    /// a single Bootstrap action (you can't add to / generate into a DB that
    /// doesn't exist; the skill enforces the same override).
    private var hasSchema: Bool { store.artifacts.contains { ["wiki/entities/opportunities/SCHEMA.md","opportunities/SCHEMA.md"].contains($0.relativePath) } }

    /// Live L1 themes, derived from the loaded opportunities, for the
    /// "Generate → By theme" submenu. Empty until the table has loaded.
    private var themes: [String] {
        var seen = Set<String>(); var out: [String] = []
        for o in opportunities where !o.theme.isEmpty && o.theme != "Untriaged" && o.theme != "…" {
            if seen.insert(o.theme).inserted { out.append(o.theme) }
        }
        return out.sorted()
    }

    private var oppArtifacts: [Artifact] {
        store.artifacts.filter {
            OpportunityFiles.isOpportunityFile($0.relativePath) && !OpportunityFiles.isReserved($0.relativePath)
        }
    }

    private var rows: [Opportunity] {
        let base = loaded ? opportunities : oppArtifacts.map {
            Opportunity(artifact: $0, title: prettyDocName($0.relativePath),
                        theme: "…", priority: "", provenance: "", status: "", summary: "")
        }
        return base.sorted(using: sortOrder)
    }

    /// The Run control: an Answer… button when a launched run is waiting on the
    /// human, otherwise a "Run" menu. Empty DB → just Bootstrap; populated DB →
    /// Add one from text… + Generate (global / by theme). Disabled while a run for
    /// this page is in flight or `claude` is unavailable.
    @ViewBuilder
    private var launchControl: some View {
        let run = oppDoc.flatMap { runManager.latestRun(for: $0.trackingPath, in: store.project.path) }
        let isWaiting = run?.pendingQuestions.isEmpty == false
        let isRunning = run?.status == .running
        if isWaiting, let doc = oppDoc {
            ActionButton(title: "Answer…", systemImage: "questionmark.bubble.fill", tone: .waiting,
                         help: "/pm-opportunities needs your input — answer to continue") {
                onAnswer(doc.trackingPath)
            }
        } else {
            Menu {
                if hasSchema {
                    Button { showAddSheet = true } label: {
                        Label("Describe one myself…", systemImage: "square.and.pencil")
                    }
                    Divider()
                    Menu {
                        Button("Across all themes") { launch("generate:") }
                        if !themes.isEmpty {
                            Menu("In one theme") {
                                ForEach(themes, id: \.self) { theme in
                                    Button(theme) { launch("generate: for theme \(theme)") }
                                }
                            }
                        }
                    } label: {
                        Label("Let Nano suggest more", systemImage: "sparkles")
                    }
                } else {
                    Button { launch(nil) } label: {
                        Label("Bootstrap the database", systemImage: "sparkles")
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                    Text(isRunning ? "Running…" : "Add")
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                }
            }
            .menuStyle(.button)
            .buttonStyle(ActionButtonStyle(tone: .accent, prominent: !isRunning))
            .fixedSize()
            .disabled(isRunning || claudeAvailable == false || oppDoc == nil)
            .help("Add to the opportunity database in \(store.project.name) — describe one yourself, or let Nano suggest more")
        }
    }

    private func launch(_ context: String?) {
        guard let doc = oppDoc else { return }
        runManager.launch(doc, in: store.project.path, userContext: context)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label {
                        Text("Opportunities").foregroundStyle(Color.npInk)
                    } icon: {
                        Image(systemName: "lightbulb").foregroundStyle(Color.npCoral)
                    }
                    .font(.npDisplay(30))
                    Text(oppArtifacts.count == 1 ? "1 user problem, ranked. Click a row to open it."
                                                 : "\(oppArtifacts.count) user problems, ranked. Click a row to open one.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                launchControl
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            if oppArtifacts.isEmpty {
                ContentUnavailableView(
                    "No opportunities yet",
                    systemImage: "lightbulb",
                    description: Text("Run /pm-opportunities in your agent to bootstrap the database — it lands in .nanopm/wiki/entities/opportunities/.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(rows, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Opportunity", value: \.title) { o in
                        let oSlug = ((o.artifact.relativePath as NSString).lastPathComponent as NSString).deletingPathExtension
                        let solCount = solutionCounts[oSlug] ?? 0
                        VStack(alignment: .leading, spacing: 2) {
                            Text(o.title).font(.headline).foregroundStyle(Color.npInk).lineLimit(2)
                            if !o.summary.isEmpty {
                                Text(o.summary).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            if solCount > 0 {
                                Text(solCount == 1 ? "1 solution ⊳" : "\(solCount) solutions ⊳")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color.npOlive)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TableColumn("Theme", value: \.theme) { o in
                        Text(o.theme).font(.callout).foregroundStyle(Color.npInk)
                    }
                    TableColumn("Priority", value: \.priorityOrder) { o in
                        OpportunityBadge(text: o.priority, tint: opportunityPriorityTint(o.priority))
                    }.width(78)
                    TableColumn("Provenance", value: \.provenance) { o in
                        OpportunityBadge(text: o.provenance, tint: opportunityProvenanceTint(o.provenance))
                    }.width(132)
                    TableColumn("Status", value: \.status) { o in
                        OpportunityBadge(text: o.status, tint: opportunityStatusTint(o.status))
                    }.width(128)
                    TableColumn("Updated", value: \.lastUpdated) { o in
                        Text(o.lastUpdated, format: .dateTime.day().month(.abbreviated))
                            .font(.caption).foregroundStyle(.secondary)
                    }.width(74)
                }
                .onChange(of: selection) { _, id in if let id { onOpen(id) } }
            }
        }
        .background(Color.npPaper)
        .task(id: "\(oppArtifacts.map(\.id).joined())#\(store.generation)") {
            await load()
        }
        .task { claudeAvailable = await ShellRunner.claudeAvailable() }
        .sheet(isPresented: $showAddSheet) {
            OpportunityAddSheet(projectName: store.project.name) { text in
                launch("add: \(text)")
            }
        }
    }

    private func load() async {
        var result: [Opportunity] = []
        for art in oppArtifacts {
            let content = (try? await store.content(of: art)) ?? ""
            result.append(OpportunityParser.parse(content, artifact: art))
        }
        opportunities = result

        // Tally child solutions per parent opportunity slug for the row badge.
        var counts: [String: Int] = [:]
        let solutionArtifacts = store.artifacts.filter {
            SolutionFiles.isSolutionFile($0.relativePath) && !SolutionFiles.isReserved($0.relativePath)
        }
        for art in solutionArtifacts {
            let content = (try? await store.content(of: art)) ?? ""
            let parsed = SolutionParser.parse(content, artifact: art)
            if !parsed.opportunity.isEmpty { counts[parsed.opportunity, default: 0] += 1 }
        }
        solutionCounts = counts
        loaded = true
    }
}

// MARK: - Detail

/// A single opportunity: title + metadata chips, then the body with the raw
/// frontmatter stripped (it's surfaced as chips instead).
struct OpportunityDetailView: View {
    @ObservedObject var store: ArtifactStore
    let artifact: Artifact
    /// Navigate to the live run session when the launched `/pm-solutions` run
    /// needs the human's input.
    var onAnswer: (String) -> Void = { _ in }
    var onOpenArtifact: (String) -> Void = { _ in }

    @EnvironmentObject private var runManager: RunManager
    @State private var opportunity: Opportunity?
    @State private var bodyText: String?
    @State private var loadError: String?
    @State private var claudeAvailable: Bool?
    @State private var showLaunchPopover = false
    @State private var launchComment = ""
    /// Candidate solutions whose parent is THIS opportunity — the OST children
    /// `/pm-solutions` wrote. Drives the compare-card section.
    @State private var childSolutions: [Solution] = []

    /// The opportunity slug (filename without extension), used as the positional
    /// argument to `/pm-solutions` and the per-opportunity run-tracking key.
    private var slug: String { ((artifact.relativePath as NSString).lastPathComponent as NSString).deletingPathExtension }
    private var trackingKey: String { "solutions:\(slug)" }
    private var solutionsDoc: SkillDoc? { SkillCatalog.all.first { $0.skillCommand == "/pm-solutions" } }
    private var solutionsRun: RunManager.SkillRun? { runManager.latestRun(for: trackingKey, in: store.project.path) }

    /// The catalog skill behind "Spec this →" — launching `/pm-prd <solution>` is
    /// the act of choosing a solution (no frontmatter written by the viewer).
    private var prdDoc: SkillDoc? { SkillCatalog.all.first { $0.skillCommand == "/pm-prd" } }

    private func launchSolutions() {
        guard let doc = solutionsDoc else { return }
        let comment = launchComment.trimmingCharacters(in: .whitespacesAndNewlines)
        runManager.launch(doc, in: store.project.path,
                          userContext: comment.isEmpty ? nil : comment,
                          argument: slug, trackingKey: trackingKey)
        launchComment = ""
        showLaunchPopover = false
    }

    /// "Spec this →" — choosing this solution. Launches `/pm-prd <solution-slug>`;
    /// the act of launching IS the choice (the viewer writes no frontmatter).
    private func specSolution(_ solution: Solution) {
        guard let doc = prdDoc else { return }
        let solSlug = ((solution.artifact.relativePath as NSString).lastPathComponent as NSString).deletingPathExtension
        runManager.launch(doc, in: store.project.path, argument: solSlug, trackingKey: "prd:\(solSlug)")
    }

    /// The header control that drives the `/pm-solutions` run for THIS
    /// opportunity: Answer… while it waits on the human, an inline running strip
    /// while it works, and the Brainstorm launch button otherwise.
    @ViewBuilder
    private var solutionsControl: some View {
        if solutionsRun?.pendingQuestions.isEmpty == false {
            ActionButton(title: "Answer…", systemImage: "questionmark.bubble.fill", tone: .waiting,
                         help: "/pm-solutions needs your input") {
                onAnswer(trackingKey)
            }
        } else if solutionsRun?.status == .running {
            HStack(spacing: 6) {
                SparkleView(size: 14)
                Text(solutionsRun?.lastActivity ?? "Working…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.npSurface.opacity(0.5), in: Capsule())
        } else {
            ActionButton(title: "Brainstorm solutions", systemImage: "lightbulb.max", tone: .accent,
                         help: "Brainstorm a compared set of solutions for this opportunity with /pm-solutions") {
                showLaunchPopover = true
            }
            .disabled(claudeAvailable == false || solutionsDoc == nil)
            .popover(isPresented: $showLaunchPopover, arrowEdge: .bottom) { launchPopover }
        }
    }

    /// Pre-launch composer (mirrors `SkillRunButton`'s popover): an optional
    /// free-text steer passed to `/pm-solutions`. Run works with the field empty.
    @ViewBuilder
    private var launchPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Brainstorm solutions").font(.headline)
            Text("Optional: add a steer — e.g. focus on cheap-to-ship ideas.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            TextField("Optional comment…", text: $launchComment, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Run") { launchSolutions() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(opportunity?.title ?? prettyDocName(artifact.relativePath))
                            .font(.npDisplay(30))
                            .foregroundStyle(Color.npInk)
                            .textSelection(.enabled)
                        Spacer()
                        solutionsControl
                    }

                    if let o = opportunity {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "tag").font(.caption2)
                                Text(o.theme).font(.caption.weight(.medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.npSurface.opacity(0.6), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.npBorder))

                            OpportunityBadge(text: o.priority, tint: opportunityPriorityTint(o.priority))
                            OpportunityBadge(text: o.provenance, tint: opportunityProvenanceTint(o.provenance))
                            OpportunityBadge(text: o.status, tint: opportunityStatusTint(o.status))
                            if !childSolutions.isEmpty {
                                OpportunityBadge(
                                    text: childSolutions.count == 1 ? "1 solution" : "\(childSolutions.count) solutions",
                                    tint: .npOlive
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

                if !childSolutions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            if solutionsRun?.status == .succeeded {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.npOlive)
                                Text(childSolutions.count == 1 ? "✓ 1 solution ready"
                                                               : "✓ \(childSolutions.count) solutions ready")
                                    .font(.callout.weight(.medium))
                            } else {
                                Text(childSolutions.count == 1 ? "1 candidate solution"
                                                               : "\(childSolutions.count) candidate solutions")
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(Color.npInk)
                            }
                        }
                        CompareCardView(
                            solutions: childSolutions,
                            onOpen: { sol in onOpenArtifact(sol.id) },
                            onSpec: { sol in specSolution(sol) }
                        )
                    }
                } else if solutionsRun?.status == .succeeded {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.npOlive)
                        Text("Solutions ready — reading them in…").font(.callout.weight(.medium))
                    }
                }
                if case .failed(let msg)? = solutionsRun?.status {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(msg).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }

                Divider().overlay(Color.npBorder)

                if let loadError {
                    ContentUnavailableView("Couldn't read file", systemImage: "exclamationmark.triangle",
                                           description: Text(loadError))
                } else if let bodyText {
                    Markdown(bodyText)
                        .markdownTheme(.nanopm)
                        .textSelection(.enabled)
                        .environment(\.openURL, OpenURLAction { url in
                            if url.scheme == nil || url.isFileURL {
                                if let id = resolveInRepoArtifactID(url, from: artifact.relativePath, in: store.artifacts) {
                                    onOpenArtifact(id)
                                    return .handled
                                }
                                return .discarded
                            }
                            return .systemAction
                        })
                } else {
                    SparkleView(size: 18).frame(maxWidth: .infinity).padding(.vertical, 60)
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .task(id: "\(artifact.id)#\(store.generation)#\(runManager.completionTick)") {
            await load()
            await loadChildSolutions()
        }
        .task { claudeAvailable = await ShellRunner.claudeAvailable() }
    }

    private func load() async {
        do {
            let content = try await store.content(of: artifact)
            opportunity = OpportunityParser.parse(content, artifact: artifact)
            bodyText = OpportunityParser.strippedBody(content)
            loadError = nil
        } catch {
            bodyText = nil
            loadError = "\(error)"
        }
    }

    /// Loads the solution artifacts whose `opportunity` frontmatter points at THIS
    /// opportunity's slug — the OST children — sorted by converging status, then
    /// impact.
    private func loadChildSolutions() async {
        let mySlug = slug
        let solutionArtifacts = store.artifacts.filter {
            SolutionFiles.isSolutionFile($0.relativePath) && !SolutionFiles.isReserved($0.relativePath)
        }
        var result: [Solution] = []
        for art in solutionArtifacts {
            let content = (try? await store.content(of: art)) ?? ""
            let parsed = SolutionParser.parse(content, artifact: art)
            if parsed.opportunity == mySlug { result.append(parsed) }
        }
        result.sort {
            if $0.statusOrder != $1.statusOrder { return $0.statusOrder < $1.statusOrder }
            return $0.impactOrder < $1.impactOrder
        }
        childSolutions = result
    }
}

// MARK: - Add sheet (Mode A)

/// Mode A — the PM types one user problem; on Run it launches `/pm-opportunities`
/// with an `add:` hint (the skill dedups it against the existing DB before
/// writing). A sheet sibling of `SkillRunButton`'s pre-launch popover.
struct OpportunityAddSheet: View {
    let projectName: String
    /// Called with the trimmed problem text when the PM hits Run.
    let onRun: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add an opportunity").font(.headline)
            Text("Describe the user problem in a sentence or two — the pain, not the solution. The agent files it in \(projectName), deduped against what's already there.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            TextField("e.g. Users abandon onboarding at the import step because it's unclear what format to upload",
                      text: $text, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Run") {
                    onRun(trimmed)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmed.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420)
        .onAppear { focused = true }
    }
}
