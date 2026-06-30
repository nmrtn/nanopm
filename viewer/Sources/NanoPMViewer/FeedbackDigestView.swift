import SwiftUI

/// The "+ Add feedback" experience inside the Activity Monitor: a paste-box that
/// launches `/pm-add-feedback` headlessly through `RunManager`, and the digest
/// that parses the skill's stable run-summary once the run finishes.
///
/// Why it lives here and not on the Raw-feedback page: the Activity Monitor is
/// the one window that owns `RunManager` and watches every run live, so the
/// paste → run → digest loop stays in one place. The composer launches into the
/// project of the most recent run (the project the user is working in); the
/// digest renders in that run's console when it succeeds.

// MARK: - Run summary model + parsing

/// The machine-readable run-summary `/pm-add-feedback` emits (SKILL.md Phase 8).
/// Parsed from the run's final output (preferred) or, as a fallback, the latest
/// matching `pm-add-feedback` line in `.nanopm/raw/events.jsonl`. Never derived
/// from racy file-mtime diffing.
struct FeedbackSummary: Equatable {
    var rawSource: String = ""
    var rawID: String = ""
    var created: [String] = []           // Pass 2 — new opportunities
    var updated: [String] = []           // Pass 1 — grounded opportunities
    /// "slug: old→new" provenance flips, one per entry.
    var transitions: [String] = []
    var themes: [String] = []
    var lowConfidence: [String] = []
    var droppedOffStrategy: Int = 0
    /// "batched-confirm" | "write-then-review".
    var mode: String = ""

    var isWriteThenReview: Bool { mode == "write-then-review" }

    /// Nothing landed — the run archived the source but wrote no opportunities.
    var isEmpty: Bool {
        created.isEmpty && updated.isEmpty && transitions.isEmpty && themes.isEmpty
    }

    private static let fenceStart = "===PM-ADD-FEEDBACK-SUMMARY==="
    private static let fenceEnd = "===END-SUMMARY==="

    /// Parse the fenced run-summary block from the skill's final output text.
    /// Returns nil when the block isn't present (the run hasn't reached Phase 8).
    static func parse(fromOutput text: String) -> FeedbackSummary? {
        guard let start = text.range(of: fenceStart) else { return nil }
        let afterStart = text[start.upperBound...]
        let body = afterStart.range(of: fenceEnd).map { String(afterStart[..<$0.lowerBound]) }
            ?? String(afterStart)

        var summary = FeedbackSummary()
        var sawAny = false
        for rawLine in body.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces).lowercased()
            // Strip any trailing "# comment" the skill's template carries.
            var value = String(line[line.index(after: colon)...])
            if let hash = value.range(of: " #") { value = String(value[..<hash.lowerBound]) }
            value = value.trimmingCharacters(in: .whitespaces)
            sawAny = true
            switch key {
            case "raw_source": summary.rawSource = value
            case "raw_id": summary.rawID = value
            case "opportunities_created": summary.created = splitList(value)
            case "opportunities_updated": summary.updated = splitList(value)
            case "provenance_transitions": summary.transitions = splitList(value)
            case "themes": summary.themes = splitList(value)
            case "low_confidence": summary.lowConfidence = splitList(value)
            case "dropped_off_strategy": summary.droppedOffStrategy = Int(value) ?? 0
            case "mode": summary.mode = value
            default: break
            }
        }
        return sawAny ? summary : nil
    }

    /// Fallback: read the latest `pm-add-feedback` entry from
    /// `.nanopm/raw/events.jsonl` (SKILL.md persists the same `outputs` there via
    /// `nanopm_context_append`). Used when the final-output block didn't parse.
    static func parse(fromEventsJSONL contents: String) -> FeedbackSummary? {
        var latest: [String: Any]?
        for line in contents.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8),
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  (obj["skill"] as? String) == "pm-add-feedback"
            else { continue }
            latest = obj   // newest matching line wins (append-only log, last is latest)
        }
        guard let obj = latest,
              let outputs = obj["outputs"] as? [String: Any] else { return nil }

        func str(_ k: String) -> String { (outputs[k] as? String) ?? "" }
        var summary = FeedbackSummary()
        summary.rawSource = str("raw_source")
        summary.rawID = str("raw_id")
        summary.created = splitList(str("opportunities_created"))
        summary.updated = splitList(str("opportunities_updated"))
        summary.transitions = splitList(str("provenance_transitions"))
        summary.themes = splitList(str("themes"))
        // events.jsonl carries no low_confidence/dropped keys — leave them empty.
        summary.mode = str("mode")
        return summary
    }

    private static func splitList(_ value: String) -> [String] {
        value.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Digest view

/// Renders a finished `/pm-add-feedback` run: what was created/updated, the
/// provenance transitions, the themes, and the write-then-review review note.
/// Opportunity slugs are clickable when an `onOpenOpportunity` handler is wired
/// (the Activity Monitor is a standalone window, so by default they're inert).
struct FeedbackDigestView: View {
    let summary: FeedbackSummary
    /// Open an opportunity by its bare slug; nil disables the links.
    var onOpenOpportunity: ((String) -> Void)? = nil
    /// Whether a slug resolves to an opportunity page; chips that fail this stay
    /// greyed/disabled even when a handler is wired (slug may have no page yet).
    /// Defaults to "all resolvable" so callers that don't know just enable them.
    var canOpenOpportunity: (String) -> Bool = { _ in true }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if summary.isWriteThenReview {
                reviewNote
            }

            if !summary.updated.isEmpty {
                section(title: summary.updated.count == 1 ? "1 opportunity grounded"
                                                          : "\(summary.updated.count) opportunities grounded",
                        icon: "arrow.up.circle", tint: .npOlive,
                        slugs: summary.updated)
            }
            if !summary.created.isEmpty {
                section(title: summary.created.count == 1 ? "1 new opportunity"
                                                          : "\(summary.created.count) new opportunities",
                        icon: "plus.circle", tint: .npCoral,
                        slugs: summary.created)
            }
            if !summary.transitions.isEmpty {
                transitionsSection
            }
            if !summary.themes.isEmpty {
                themesSection
            }
            if summary.updated.isEmpty && summary.created.isEmpty {
                Text(summary.droppedOffStrategy > 0
                     ? "No opportunities written — \(summary.droppedOffStrategy) off-strategy signal(s) dropped. The source is still archived."
                     : "No opportunities written — the source is archived for the record.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !summary.rawSource.isEmpty {
                Divider().overlay(Color.npBorder)
                Label(".nanopm/\(summary.rawSource)", systemImage: "tray.full")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.npSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.npBorder))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down").foregroundStyle(Color.npCoral)
            Text("Feedback ingested").font(.headline).foregroundStyle(Color.npInk)
            Spacer()
            let total = summary.created.count + summary.updated.count
            if total > 0 {
                Text(total == 1 ? "1 opportunity touched" : "\(total) opportunities touched")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var reviewNote: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.npAmber)
            VStack(alignment: .leading, spacing: 2) {
                Text("Written in review mode").font(.callout.weight(.medium)).foregroundStyle(Color.npInk)
                Text(summary.lowConfidence.isEmpty
                     ? "Headless runs write without a confirm — review the grounded and new opportunities below."
                     : "Headless write-then-review. \(summary.lowConfidence.count) item(s) flagged ⚠ low-confidence need your review: \(summary.lowConfidence.joined(separator: ", ")).")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.npAmber.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func section(title: String, icon: String, tint: Color, slugs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title).foregroundStyle(Color.npInk)
            } icon: {
                Image(systemName: icon).foregroundStyle(tint)
            }
            .font(.callout.weight(.medium))
            // Clickable only when a handler is wired AND the slug resolves to a
            // page; a slug with no opportunity page stays greyed/disabled.
            FlowChips(items: slugs,
                      lowConfidence: Set(summary.lowConfidence),
                      canOpen: canOpenOpportunity,
                      onTap: onOpenOpportunity)
        }
    }

    private var transitionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Provenance upgrades", systemImage: "checkmark.seal")
                .font(.callout.weight(.medium)).foregroundStyle(Color.npInk)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(summary.transitions, id: \.self) { t in
                    Text(t)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Themes", systemImage: "tag")
                .font(.callout.weight(.medium)).foregroundStyle(Color.npInk)
            FlowChips(items: summary.themes, lowConfidence: [], onTap: nil)
        }
    }
}

/// A simple wrapping row of pill chips. When `onTap` is non-nil each chip is a
/// button (clickable slug); otherwise the chips are plain labels (themes).
private struct FlowChips: View {
    let items: [String]
    let lowConfidence: Set<String>
    /// Whether a given item is openable; a non-openable item renders as a plain
    /// (greyed) label even when `onTap` is wired. Themes pass the default.
    var canOpen: (String) -> Bool = { _ in true }
    var onTap: ((String) -> Void)?

    var body: some View {
        // Wrapping is approximated by a lazy grid of adaptive columns — keeps the
        // layout dependency-free and good enough for short slug/theme lists.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 240), spacing: 6, alignment: .leading)],
                  alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                chip(item)
            }
        }
    }

    @ViewBuilder
    private func chip(_ item: String) -> some View {
        let flagged = lowConfidence.contains(item)
        // A chip is interactive only when a handler is wired AND the slug resolves
        // to a page. When a handler is wired but the slug doesn't resolve, the chip
        // is greyed (it had a page to link, but there isn't one) rather than tinted.
        let openable = onTap != nil && canOpen(item)
        let unresolved = onTap != nil && !canOpen(item)
        let tint = flagged ? Color.npAmber : Color.npOlive
        let label = HStack(spacing: 4) {
            if flagged { Image(systemName: "exclamationmark.triangle").font(.caption2) }
            Text(item).font(.caption.weight(.medium)).lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((unresolved ? Color.secondary : tint).opacity(unresolved ? 0.10 : 0.14),
                    in: Capsule())
        .foregroundStyle(unresolved ? Color.secondary : tint)

        if openable, let onTap {
            Button { onTap(item) } label: { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }
}

// MARK: - "+ Add feedback" composer

/// The paste-box that launches `/pm-add-feedback`. Bound to a project path; when
/// none is known (no run yet to infer one from) it shows a hint instead of a
/// dead Run button.
struct AddFeedbackComposer: View {
    /// The project to launch into; nil disables launching.
    let projectPath: String?
    @EnvironmentObject private var runManager: RunManager
    @State private var text = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canRun: Bool { projectPath != nil && !trimmed.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "tray.and.arrow.down").foregroundStyle(Color.npCoral)
                Text("Add feedback").font(.headline).foregroundStyle(Color.npInk)
                Spacer()
            }
            TextEditor(text: $text)
                .font(.callout)
                .frame(minHeight: 54, maxHeight: 110)
                .focused($focused)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Color.npPaper, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.npBorder))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Paste an interview note, an SMS, a Slack thread, a raw quote…")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
            HStack {
                if let name = projectPath.map({ ($0 as NSString).lastPathComponent }) {
                    Label(name, systemImage: "folder")
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                } else {
                    Text("Open a project and run a skill first.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    run()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.npCoral)
                .disabled(!canRun)
            }
        }
        .padding(12)
        .background(Color.npSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.npBorder))
        .padding(.horizontal, 10)
        .padding(.top, 10)
    }

    private func run() {
        guard let projectPath, let doc = SkillCatalog.addFeedback, canRun else { return }
        // Mirror SkillRunButton: the pasted blob is the launch context. The
        // `--paste` argument tells the skill which intake form this is, while the
        // context line carries the bytes (SKILL.md Phase 1 reads both).
        runManager.launch(doc, in: projectPath, userContext: trimmed, argument: "--paste")
        text = ""
        focused = false
    }
}
