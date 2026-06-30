import SwiftUI
import MarkdownUI

// MARK: - Model

/// One archived raw source under `.nanopm/raw/<type>/<id>.<ext>` (schema §2.1):
/// a feedback dump or an interview transcript, stored verbatim and
/// content-addressed. `type` is the raw subdir ("interviews" | "feedback"),
/// `id` the 12-hex content hash that names the file. The browser is read-only —
/// the archive is immutable.
struct RawSource: Identifiable {
    /// Path relative to `.nanopm/`, e.g. `raw/interviews/1a2b3c4d5e6f.md`.
    let relativePath: String
    let type: String        // interviews | feedback
    let id: String          // the content-hash stem (filename without extension)
    let ext: String         // file extension, lowercased, for the content view
    let modifiedAt: Date
    /// Source→opportunity links read from the sibling `<id>.manifest.jsonl`, if any.
    let links: [RawManifestLink]

    var fileName: String { (relativePath as NSString).lastPathComponent }
    /// Distinct opportunity slugs this source fed (the "fed N opportunities" link).
    var fedOpportunities: [String] {
        var seen = Set<String>(); var out: [String] = []
        for l in links where !l.opportunitySlug.isEmpty {
            if seen.insert(l.opportunitySlug).inserted { out.append(l.opportunitySlug) }
        }
        return out.sorted()
    }
}

/// One line of a `<id>.manifest.jsonl`: a single source→opportunity link
/// (schema §2.1). The browser surfaces the slug + the claim it backed.
struct RawManifestLink: Identifiable {
    let opportunitySlug: String   // entities/opportunities/<slug>
    let claim: String             // the wiki-side assertion this source supports
    let rawLine: String           // the verbatim line / locator it came from
    let ts: String                // ISO-8601 write time

    var id: String { opportunitySlug + "|" + claim + "|" + rawLine }
}

/// Reads the raw interview/feedback archive directly off disk (any extension —
/// the artifact scanner only keeps md/json/jsonl, but a transcript may be .txt),
/// pairing each source with its `.manifest.jsonl` sibling. Mirrors how
/// `ArtifactScanner` enumerates via shell so the viewer never touches an API.
enum RawSourceScanner {
    /// The two raw subdirs the "Raw feedback" browser surfaces (schema §2.1).
    static let types = ["interviews", "feedback"]

    static func scan(nanopmPath: String) async -> [RawSource] {
        var sources: [RawSource] = []
        for type in types {
            let dir = nanopmPath + "/raw/" + type
            // `%m|%N` (epoch|path) per file, like ArtifactScanner; tolerate a
            // missing dir so an un-ingested project just yields nothing.
            let command = "cd \(ShellRunner.quote(dir)) 2>/dev/null && find . -type f -exec stat -f '%m|%N' {} \\; 2>/dev/null || true"
            let output = (try? await ShellRunner.runAsync(command)) ?? ""

            // First pass: collect manifests so each source can be paired with its sibling.
            var manifestPaths: [String: String] = [:]   // stem -> manifest abs path
            var fileLines: [(epoch: String, name: String)] = []
            for line in output.split(separator: "\n") {
                guard let sep = line.firstIndex(of: "|") else { continue }
                let epoch = String(line[..<sep])
                var name = String(line[line.index(after: sep)...])
                if name.hasPrefix("./") { name.removeFirst(2) }
                if name.hasSuffix(".manifest.jsonl") {
                    let stem = String(name.dropLast(".manifest.jsonl".count))
                    manifestPaths[stem] = dir + "/" + name
                } else {
                    fileLines.append((epoch, name))
                }
            }

            for (epoch, name) in fileLines {
                let stem = (name as NSString).deletingPathExtension
                let ext = (name as NSString).pathExtension.lowercased()
                var links: [RawManifestLink] = []
                if let manifest = manifestPaths[stem] {
                    links = await readManifest(absolutePath: manifest)
                }
                sources.append(RawSource(
                    relativePath: "raw/\(type)/\(name)",
                    type: type,
                    id: stem,
                    ext: ext,
                    modifiedAt: Date(timeIntervalSince1970: TimeInterval(epoch) ?? 0),
                    links: links
                ))
            }
        }
        // Newest first — the most recently archived source is the most interesting.
        return sources.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    private static func readManifest(absolutePath: String) async -> [RawManifestLink] {
        guard let raw = try? await ShellRunner.runAsync("cat \(ShellRunner.quote(absolutePath)) 2>/dev/null")
        else { return [] }
        var links: [RawManifestLink] = []
        for line in raw.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8),
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            else { continue }
            links.append(RawManifestLink(
                opportunitySlug: (obj["opportunity_slug"] as? String) ?? "",
                claim: (obj["claim"] as? String) ?? "",
                rawLine: (obj["raw_line"] as? String) ?? "",
                ts: (obj["ts"] as? String) ?? ""
            ))
        }
        return links
    }
}

func rawTypeLabel(_ type: String) -> String {
    switch type {
    case "interviews": return "Interview"
    case "feedback": return "Feedback"
    default: return type.prefix(1).uppercased() + type.dropFirst()
    }
}

func rawTypeIcon(_ type: String) -> String {
    switch type {
    case "interviews": return "quote.bubble"
    case "feedback": return "bubble.left.and.bubble.right"
    default: return "doc.plaintext"
    }
}

// MARK: - Overview

/// The "Raw feedback" landing: a table of every archived interview/feedback
/// source (type, id, modified date, opportunities fed). Read-only — clicking a
/// row opens that source's content. Mirrors `OpportunitiesOverviewView`.
struct RawFeedbackOverviewView: View {
    @ObservedObject var store: ArtifactStore
    let onOpen: (String) -> Void

    @State private var sources: [RawSource] = []
    @State private var loaded = false
    @State private var selection: RawSource.ID?
    @State private var sortOrder = [
        KeyPathComparator(\RawSource.modifiedAt, order: .reverse),
    ]

    private var rows: [RawSource] { sources.sorted(using: sortOrder) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text("Raw feedback").foregroundStyle(Color.npInk)
                } icon: {
                    Image(systemName: "tray.full").foregroundStyle(Color.npCoral)
                }
                .font(.npDisplay(30))
                Text(sources.count == 1 ? "1 archived source. Click it to read it verbatim."
                                        : "\(sources.count) archived sources — interviews and feedback, stored verbatim. Click a row to read one.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            if loaded && sources.isEmpty {
                ContentUnavailableView(
                    "No raw feedback yet",
                    systemImage: "tray",
                    description: Text("Archived interviews and feedback land in .nanopm/raw/interviews/ and .nanopm/raw/feedback/. Run /pm-add-feedback in your agent to fill this in.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !loaded {
                SparkleView(size: 18).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(rows, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Source") { src in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(src.id).font(.headline.monospaced()).foregroundStyle(Color.npInk).lineLimit(1)
                            let fed = src.fedOpportunities
                            if !fed.isEmpty {
                                Text(fed.count == 1 ? "fed 1 opportunity" : "fed \(fed.count) opportunities")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color.npOlive)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TableColumn("Type", value: \.type) { src in
                        HStack(spacing: 4) {
                            Image(systemName: rawTypeIcon(src.type)).font(.caption2)
                            Text(rawTypeLabel(src.type)).font(.callout)
                        }
                        .foregroundStyle(Color.npInk)
                    }.width(120)
                    TableColumn("Updated", value: \.modifiedAt) { src in
                        Text(src.modifiedAt, format: .dateTime.day().month(.abbreviated))
                            .font(.caption).foregroundStyle(.secondary)
                    }.width(90)
                }
                .onChange(of: selection) { _, id in if let id { onOpen(id) } }
            }
        }
        .background(Color.npPaper)
        .task(id: "raw#\(store.generation)") { await load() }
    }

    private func load() async {
        sources = await RawSourceScanner.scan(nanopmPath: store.project.nanopmPath)
        loaded = true
    }
}

// MARK: - Detail

/// A single archived source: header (type + id + date), the "fed N
/// opportunities" links read from its manifest, then the verbatim content. The
/// id passed in is the source's `relativePath` (so ProjectView can route to it).
struct RawSourceDetailView: View {
    @ObservedObject var store: ArtifactStore
    /// The source's `relativePath` under `.nanopm/` (the row's id).
    let relativePath: String
    /// Open an opportunity page when a manifest slug is clicked.
    var onOpenArtifact: (String) -> Void = { _ in }

    @State private var source: RawSource?
    @State private var bodyText: String?
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: rawTypeIcon(source?.type ?? ""))
                            .foregroundStyle(Color.npCoral)
                        Text(source.map { "\(rawTypeLabel($0.type)) · \($0.id)" }
                                ?? (relativePath as NSString).lastPathComponent)
                            .font(.npDisplay(26))
                            .foregroundStyle(Color.npInk)
                            .textSelection(.enabled)
                    }

                    HStack(spacing: 6) {
                        Text(".nanopm/" + relativePath)
                            .font(.system(.footnote, design: .monospaced))
                        if let src = source {
                            Text("·")
                            Text("archived \(src.modifiedAt, format: .relative(presentation: .named))")
                                .font(.footnote)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                if let src = source, !src.links.isEmpty {
                    manifestSection(src)
                }

                Divider().overlay(Color.npBorder)

                if let loadError {
                    ContentUnavailableView("Couldn't read source", systemImage: "exclamationmark.triangle",
                                           description: Text(loadError))
                } else if let bodyText {
                    // The archive is verbatim text, not authored markdown — render it
                    // in a code block so spacing and line breaks survive intact.
                    Markdown("```\n\(bodyText)\n```")
                        .markdownTheme(.nanopm)
                        .textSelection(.enabled)
                } else {
                    SparkleView(size: 18).frame(maxWidth: .infinity).padding(.vertical, 60)
                }
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .task(id: "\(relativePath)#\(store.generation)") { await load() }
    }

    /// "Fed N opportunities" — the bidirectional source→opportunity links from the
    /// manifest (schema §2.1). Read-only: each slug links to its opportunity page;
    /// the claim it backed is shown beneath.
    @ViewBuilder
    private func manifestSection(_ src: RawSource) -> some View {
        let fed = src.fedOpportunities
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch").foregroundStyle(Color.npOlive)
                Text(fed.count == 1 ? "Fed 1 opportunity" : "Fed \(fed.count) opportunities")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.npInk)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(src.links) { link in
                    VStack(alignment: .leading, spacing: 2) {
                        Button {
                            if let id = opportunityArtifactID(for: link.opportunitySlug) {
                                onOpenArtifact(id)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb").font(.caption2)
                                Text(link.opportunitySlug).font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(opportunityArtifactID(for: link.opportunitySlug) == nil
                                             ? Color.secondary : Color.npOlive)
                        }
                        .buttonStyle(.plain)
                        .disabled(opportunityArtifactID(for: link.opportunitySlug) == nil)
                        if !link.claim.isEmpty {
                            Text(link.claim).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.npSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.npBorder))
        }
    }

    /// Resolve a manifest slug (e.g. `entities/opportunities/foo` or bare `foo`)
    /// to a scanned opportunity artifact id, so the link navigates in-app. Nil when
    /// no matching opportunity page exists.
    private func opportunityArtifactID(for slug: String) -> String? {
        let bare = (slug as NSString).lastPathComponent.lowercased()
        guard !bare.isEmpty else { return nil }
        return store.artifacts.first { art in
            guard OpportunityFiles.isOpportunityFile(art.relativePath),
                  !OpportunityFiles.isReserved(art.relativePath) else { return false }
            let stem = ((art.relativePath as NSString).lastPathComponent as NSString)
                .deletingPathExtension.lowercased()
            return stem == bare
        }?.id
    }

    private func load() async {
        // Pull this source's metadata (incl. its manifest links) from a fresh scan,
        // then read the verbatim content off disk.
        let all = await RawSourceScanner.scan(nanopmPath: store.project.nanopmPath)
        source = all.first { $0.relativePath == relativePath }
        do {
            let file = store.project.nanopmPath + "/" + relativePath
            bodyText = try await ShellRunner.runAsync("cat \(ShellRunner.quote(file))")
            loadError = nil
        } catch {
            bodyText = nil
            loadError = "\(error)"
        }
    }
}
