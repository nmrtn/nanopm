import SwiftUI
import MarkdownUI

// MARK: - Model

/// One solution, parsed from its `.nanopm/wiki/entities/solutions/<slug>.md`
/// frontmatter (the schema `/pm-solutions` writes). Drives both the filterable
/// table and the per-solution detail header. A solution has exactly one parent
/// opportunity (`opportunity: <slug>`) — the OST tree edge.
struct Solution: Identifiable {
    let artifact: Artifact
    let title: String
    let opportunity: String   // parent opportunity slug
    let lens: String          // eng | design | business | ""
    let appetite: String      // small-bet | big-bet | ""
    let impact: String        // high | med | low | ""
    let status: String        // proposed | shortlisted | chosen | speccing | ""
    let summary: String       // first line of the pitch / problem section
    let riskiestAssumption: String   // first prose line under "## Riskiest assumption"
    let cheapestTest: String         // first prose line under "## Cheapest test"

    var id: String { artifact.id }
    var lastUpdated: Date { artifact.modifiedAt }

    /// Sort key so chosen ranks above shortlisted above proposed (unknown last) —
    /// the order the founder converges through.
    var statusOrder: Int {
        ["speccing": 0, "chosen": 1, "shortlisted": 2, "proposed": 3][status] ?? 4
    }

    /// Sort key so high impact ranks above med above low (unknown last).
    var impactOrder: Int { ["high": 0, "med": 1, "medium": 1, "low": 2][impact] ?? 3 }
}

enum SolutionParser {
    /// Parses the YAML-ish frontmatter + the one-line pitch/summary. Mirrors
    /// `OpportunityParser` (same minimal frontmatter handling: quotes, inline
    /// comments).
    static func parse(_ content: String, artifact: Artifact) -> Solution {
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
        // The first prose line under a heading: skip blanks, sub-headings, and raw
        // HTML; empty when the heading is absent.
        func firstLine(under headingPattern: String) -> String {
            guard let r = content.range(of: headingPattern, options: .regularExpression) else { return "" }
            for line in content[r.upperBound...].components(separatedBy: "\n") {
                let s = line.trimmingCharacters(in: .whitespaces)
                if s.isEmpty || s.hasPrefix("#") || s.hasPrefix("<") { continue }
                return s
            }
            return ""
        }
        // The one-line pitch: the first prose line under a "Pitch" heading, falling
        // back to the first prose line under "Problem" / "Summary", else empty.
        let summary = firstLine(under: #"(?m)^##\s*(?:\d+\.\s*)?(?:Pitch|Problem summary|Summary)\s*$"#)
        let riskiest = firstLine(under: #"(?m)^##\s*(?:\d+\.\s*)?Riskiest assumption\s*$"#)
        let cheapest = firstLine(under: #"(?m)^##\s*(?:\d+\.\s*)?Cheapest test\s*$"#)
        return Solution(
            artifact: artifact,
            title: fm["title"] ?? prettyDocName(artifact.relativePath),
            opportunity: (fm["opportunity"] ?? "").lowercased(),
            lens: (fm["lens"] ?? "").lowercased(),
            appetite: (fm["appetite"] ?? "").lowercased(),
            impact: (fm["impact"] ?? "").lowercased(),
            status: (fm["status"] ?? "").lowercased(),
            summary: summary,
            riskiestAssumption: riskiest,
            cheapestTest: cheapest
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

// MARK: - Parent resolution

/// Resolves a solution's `opportunity: <slug>` to the parent opportunity
/// artifact id, by matching the slug against each opportunity file's basename
/// (the `<slug>.md` filename, the convention `/pm-opportunities` writes). Nil
/// when no such opportunity is on disk (an orphan solution).
func parentOpportunityArtifactID(forSlug slug: String, in artifacts: [Artifact]) -> String? {
    let s = slug.lowercased()
    guard !s.isEmpty else { return nil }
    return artifacts.first { art in
        guard OpportunityFiles.isOpportunityFile(art.relativePath),
              !OpportunityFiles.isReserved(art.relativePath) else { return false }
        let stem = ((art.relativePath as NSString).lastPathComponent as NSString)
            .deletingPathExtension.lowercased()
        return stem == s
    }?.id
}

/// A solution's `opportunity` slug rendered as a human-friendly label by
/// humanizing the slug (`payment-retries` → `Payment Retries`). Display only —
/// navigation uses `parentOpportunityArtifactID`. We don't read the parent's
/// authored title here because that needs an async content load the synchronous
/// table rows don't have; the humanized slug is the honest cheap approximation.
func parentOpportunityTitle(forSlug slug: String) -> String {
    let s = slug.lowercased()
    guard !s.isEmpty else { return "—" }
    return s.split(separator: "-")
        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        .joined(separator: " ")
}

// MARK: - Badges

func solutionStatusTint(_ v: String) -> Color {
    switch v {
    case "chosen", "speccing": return .npOlive
    case "shortlisted": return .npAmber
    case "proposed": return .secondary
    default: return .secondary
    }
}
func solutionLensTint(_ v: String) -> Color {
    switch v {
    case "eng": return .npOlive
    case "design": return .npCoral
    case "business": return .npAmber
    default: return .secondary
    }
}
func solutionAppetiteTint(_ v: String) -> Color {
    // The schema writes hyphenated values (small-bet / big-bet); tolerate the
    // space-separated spelling defensively, like impact tolerates med/medium.
    switch v {
    case "big-bet", "big bet": return .npCoral
    case "small-bet", "small bet": return .npOlive
    default: return .secondary
    }
}
func solutionImpactTint(_ v: String) -> Color {
    switch v { case "high": return .npOlive; case "med", "medium": return .npAmber; case "low": return .secondary; default: return .secondary }
}

// MARK: - Filterable table

/// The "Solutions" landing: a filterable table of every solution (the OST node
/// between an opportunity and a PRD). Columns: title, parent opportunity, lens,
/// appetite, impact, status. Filterable by status (and lens). Clicking a row
/// opens that solution's detail; clicking a parent opportunity navigates to it.
struct SolutionsOverviewView: View {
    @ObservedObject var store: ArtifactStore
    let onOpen: (String) -> Void

    @State private var solutions: [Solution] = []
    @State private var loaded = false
    @State private var selection: Solution.ID?
    @State private var statusFilter: String = "all"
    @State private var lensFilter: String = "all"
    @State private var sortOrder = [
        KeyPathComparator(\Solution.statusOrder, order: .forward),
        KeyPathComparator(\Solution.impactOrder, order: .forward),
    ]

    private var solutionArtifacts: [Artifact] {
        store.artifacts.filter {
            SolutionFiles.isSolutionFile($0.relativePath) && !SolutionFiles.isReserved($0.relativePath)
        }
    }

    /// Live status values present in the loaded set, for the status filter.
    private var statusOptions: [String] {
        var seen = Set<String>(); var out: [String] = []
        for s in solutions where !s.status.isEmpty {
            if seen.insert(s.status).inserted { out.append(s.status) }
        }
        return out.sorted { lhsOrder($0) < lhsOrder($1) }
    }

    /// Live lens values present in the loaded set, for the lens filter.
    private var lensOptions: [String] {
        var seen = Set<String>(); var out: [String] = []
        for s in solutions where !s.lens.isEmpty {
            if seen.insert(s.lens).inserted { out.append(s.lens) }
        }
        return out.sorted()
    }

    private func lhsOrder(_ status: String) -> Int {
        ["speccing": 0, "chosen": 1, "shortlisted": 2, "proposed": 3][status] ?? 4
    }

    private var rows: [Solution] {
        let base = loaded ? solutions : solutionArtifacts.map {
            Solution(artifact: $0, title: prettyDocName($0.relativePath),
                     opportunity: "", lens: "", appetite: "", impact: "", status: "", summary: "",
                     riskiestAssumption: "", cheapestTest: "")
        }
        return base
            .filter { statusFilter == "all" || $0.status == statusFilter }
            .filter { lensFilter == "all" || $0.lens == lensFilter }
            .sorted(using: sortOrder)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text("Solutions").foregroundStyle(Color.npInk)
                } icon: {
                    Image(systemName: "lightbulb.max").foregroundStyle(Color.npCoral)
                }
                .font(.npDisplay(30))
                Text(solutionArtifacts.count == 1 ? "1 candidate solution. Click a row to open it."
                                                  : "\(solutionArtifacts.count) candidate solutions across your opportunities. Click a row to open one.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            if solutionArtifacts.isEmpty {
                ContentUnavailableView(
                    "No solutions yet",
                    systemImage: "lightbulb.max",
                    description: Text("Run /pm-solutions <opportunity-slug> in your agent to brainstorm a compared set — they land in .nanopm/wiki/entities/solutions/.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                filterBar
                Table(rows, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Solution", value: \.title) { s in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title).font(.headline).foregroundStyle(Color.npInk).lineLimit(2)
                            if !s.summary.isEmpty {
                                Text(s.summary).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TableColumn("Opportunity", value: \.opportunity) { s in
                        if let parentID = parentOpportunityArtifactID(forSlug: s.opportunity, in: store.artifacts) {
                            Button {
                                onOpen(parentID)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right").font(.caption2)
                                    Text(parentOpportunityTitle(forSlug: s.opportunity))
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.link)
                            .help("Open the parent opportunity")
                        } else {
                            Text(s.opportunity.isEmpty ? "—" : parentOpportunityTitle(forSlug: s.opportunity))
                                .font(.callout)
                                .foregroundStyle(s.opportunity.isEmpty ? .tertiary : .secondary)
                                .lineLimit(1)
                        }
                    }
                    TableColumn("Lens", value: \.lens) { s in
                        OpportunityBadge(text: s.lens, tint: solutionLensTint(s.lens))
                    }.width(96)
                    TableColumn("Appetite", value: \.appetite) { s in
                        OpportunityBadge(text: s.appetite, tint: solutionAppetiteTint(s.appetite))
                    }.width(96)
                    TableColumn("Impact", value: \.impactOrder) { s in
                        OpportunityBadge(text: s.impact, tint: solutionImpactTint(s.impact))
                    }.width(78)
                    TableColumn("Status", value: \.statusOrder) { s in
                        OpportunityBadge(text: s.status, tint: solutionStatusTint(s.status))
                    }.width(112)
                    TableColumn("Updated", value: \.lastUpdated) { s in
                        Text(s.lastUpdated, format: .dateTime.day().month(.abbreviated))
                            .font(.caption).foregroundStyle(.secondary)
                    }.width(74)
                }
                .onChange(of: selection) { _, id in if let id { onOpen(id) } }
            }
        }
        .background(Color.npPaper)
        .task(id: "\(solutionArtifacts.map(\.id).joined())#\(store.generation)") {
            await load()
        }
    }

    /// Filter controls — status (always shown once loaded) + lens. "All" resets
    /// the dimension. Kept minimal; the table header still drives sorting.
    @ViewBuilder
    private var filterBar: some View {
        HStack(spacing: 16) {
            Picker("Status", selection: $statusFilter) {
                Text("All statuses").tag("all")
                ForEach(statusOptions, id: \.self) { s in
                    Text(s.capitalized).tag(s)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            if !lensOptions.isEmpty {
                Picker("Lens", selection: $lensFilter) {
                    Text("All lenses").tag("all")
                    ForEach(lensOptions, id: \.self) { l in
                        Text(l.capitalized).tag(l)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }

            Spacer(minLength: 0)

            Text(rows.count == 1 ? "1 shown" : "\(rows.count) shown")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 10)
    }

    private func load() async {
        var result: [Solution] = []
        for art in solutionArtifacts {
            let content = (try? await store.content(of: art)) ?? ""
            result.append(SolutionParser.parse(content, artifact: art))
        }
        solutions = result
        loaded = true
    }
}

// MARK: - Detail

/// A single solution: title + metadata chips (lens / appetite / impact / status)
/// and a link back to its parent opportunity, then the body with the raw
/// frontmatter stripped (it's surfaced as chips instead). The back-link closes
/// the bidirectional opportunity↔solution navigation.
struct SolutionDetailView: View {
    @ObservedObject var store: ArtifactStore
    let artifact: Artifact
    var onOpenArtifact: (String) -> Void = { _ in }

    @State private var solution: Solution?
    @State private var bodyText: String?
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(solution?.title ?? prettyDocName(artifact.relativePath))
                        .font(.npDisplay(30))
                        .foregroundStyle(Color.npInk)
                        .textSelection(.enabled)

                    if let s = solution {
                        // Back-link to the parent opportunity — the other half of the
                        // bidirectional OST navigation (the table links forward).
                        if !s.opportunity.isEmpty {
                            let parentID = parentOpportunityArtifactID(forSlug: s.opportunity, in: store.artifacts)
                            Button {
                                if let parentID { onOpenArtifact(parentID) }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left").font(.caption2)
                                    Text("Opportunity: \(parentOpportunityTitle(forSlug: s.opportunity))")
                                        .font(.caption.weight(.medium))
                                }
                            }
                            .buttonStyle(.link)
                            .disabled(parentID == nil)
                            .help(parentID == nil
                                  ? "Parent opportunity “\(s.opportunity)” isn't on disk (orphan solution)"
                                  : "Open the parent opportunity")
                        }

                        HStack(spacing: 8) {
                            OpportunityBadge(text: s.lens, tint: solutionLensTint(s.lens))
                            OpportunityBadge(text: s.appetite, tint: solutionAppetiteTint(s.appetite))
                            OpportunityBadge(text: s.impact, tint: solutionImpactTint(s.impact))
                            OpportunityBadge(text: s.status, tint: solutionStatusTint(s.status))
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
        .task(id: "\(artifact.id)#\(store.generation)") {
            await load()
        }
    }

    private func load() async {
        do {
            let content = try await store.content(of: artifact)
            solution = SolutionParser.parse(content, artifact: artifact)
            bodyText = SolutionParser.strippedBody(content)
            loadError = nil
        } catch {
            bodyText = nil
            loadError = "\(error)"
        }
    }
}
