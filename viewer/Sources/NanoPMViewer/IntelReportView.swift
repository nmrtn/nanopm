import SwiftUI
import MarkdownUI

// MARK: - Model & parser

/// Structured form of a competitor intel report (COMPETITORS.md or a dated
/// INTEL report). Parsed best-effort — the page falls back to raw Markdown
/// when the structure isn't recognized.
struct IntelReport {
    struct PageLink: Identifiable {
        let name: String
        let urlString: String
        let status: String?
        var id: String { name }
        var url: URL? { URL(string: urlString) }
        var failed: Bool { status?.lowercased().contains("fail") ?? false }
    }

    struct Field: Identifiable {
        let label: String
        let text: String
        var id: String { label }
    }

    struct Page: Identifiable {
        let title: String
        let url: URL?
        let body: String
        var id: String { title }
    }

    struct Section: Identifiable {
        let title: String
        var website: URL?
        var meta: String?
        var monitored: [PageLink] = []
        var fields: [Field] = []
        var pages: [Page] = []
        var leftover: String = ""
        var id: String { title }

        /// Fields + leftover re-joined as markdown (used when a section is
        /// rendered standalone, e.g. Strategic implications at page top).
        var combinedBody: String {
            var parts = fields.map { "**\($0.label):** \($0.text)" }
            if !leftover.isEmpty { parts.append(leftover) }
            return parts.joined(separator: "\n\n")
        }
    }

    var sections: [Section] = []
    var summaryBody: String?
    var action: String?
}

enum IntelReportParser {
    static func parse(_ markdown: String) -> IntelReport? {
        let lines = markdown.components(separatedBy: "\n").filter {
            let trimmed = $0.trimmingCharacters(in: .whitespaces)
            return !trimmed.hasPrefix("*Run /pm-competitors-intel")
                && !trimmed.hasPrefix("*Sources:")
        }

        var rawSections: [(title: String, lines: [String])] = []
        var current: (title: String, lines: [String])?
        for line in lines {
            if line.hasPrefix("## ") {
                if let c = current { rawSections.append(c) }
                current = (String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces), [])
            } else if current != nil {
                current?.lines.append(line)
            }
        }
        if let c = current { rawSections.append(c) }
        guard !rawSections.isEmpty else { return nil }

        var report = IntelReport()
        for raw in rawSections {
            if raw.title.lowercased() == "summary" {
                let text = clean(raw.lines).joined(separator: "\n")
                if let range = text.range(of: "**Action:**") {
                    report.summaryBody = String(text[..<range.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    report.action = String(text[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    report.summaryBody = text
                }
            } else {
                report.sections.append(parseSection(title: raw.title, rawLines: raw.lines))
            }
        }
        return report
    }

    private static func parseSection(title: String, rawLines: [String]) -> IntelReport.Section {
        var section = IntelReport.Section(title: title)

        // Split off "### Page — url" subsections (dated INTEL report format).
        var mainLines: [String] = []
        var pageChunks: [(title: String, lines: [String])] = []
        var currentPage: (title: String, lines: [String])?
        for line in rawLines {
            if line.hasPrefix("### ") {
                if let p = currentPage { pageChunks.append(p) }
                currentPage = (String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces), [])
            } else if currentPage != nil {
                currentPage?.lines.append(line)
            } else {
                mainLines.append(line)
            }
        }
        if let p = currentPage { pageChunks.append(p) }
        section.pages = pageChunks.map { chunk in
            let parts = chunk.title.components(separatedBy: " — ")
            return IntelReport.Page(
                title: parts[0].trimmingCharacters(in: .whitespaces),
                url: parts.count > 1 ? URL(string: parts[1].trimmingCharacters(in: .whitespaces)) : nil,
                body: clean(chunk.lines).joined(separator: "\n")
            )
        }

        var cleaned = clean(mainLines)

        // Leading single italic line → meta (e.g. "*Last checked: … | Pages: …*")
        if let first = cleaned.first {
            let t = first.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("*"), !t.hasPrefix("**"), t.hasSuffix("*"), t.count > 2 {
                section.meta = String(t.dropFirst().dropLast())
                cleaned.removeFirst()
            }
        }

        // Walk line by line: a "**Label:** …" line starts a field; following
        // lines (incl. bullets) belong to it until a blank line or new field.
        var rawFields: [(label: String, lines: [String])] = []
        var currentField: (label: String, lines: [String])?
        var leftovers: [String] = []
        for line in cleaned {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("**"),
               let labelEnd = trimmed.range(of: ":**"),
               trimmed.distance(from: trimmed.startIndex, to: labelEnd.lowerBound) <= 42 {
                if let field = currentField { rawFields.append(field) }
                let label = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 2)..<labelEnd.lowerBound])
                let rest = String(trimmed[labelEnd.upperBound...]).trimmingCharacters(in: .whitespaces)
                currentField = (label, rest.isEmpty ? [] : [rest])
            } else if trimmed.isEmpty {
                if let field = currentField { rawFields.append(field); currentField = nil }
                else { leftovers.append("") }
            } else if currentField != nil {
                currentField?.lines.append(line)
            } else {
                leftovers.append(line)
            }
        }
        if let field = currentField { rawFields.append(field) }

        for field in rawFields {
            switch field.label.lowercased() {
            case "website":
                section.website = field.lines.first.flatMap { URL(string: $0) }
            case "monitored pages":
                section.monitored = parseMonitored(field.lines[...])
            default:
                let content = field.lines.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                section.fields.append(IntelReport.Field(label: field.label, text: content))
            }
        }
        section.leftover = leftovers.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return section
    }

    /// "- Changelog: https://… *(fetched 2026-06-10)*"
    private static func parseMonitored(_ lines: ArraySlice<String>) -> [IntelReport.PageLink] {
        lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- ") else { return nil }
            var rest = String(trimmed.dropFirst(2))
            var status: String?
            if let open = rest.range(of: "*("),
               let close = rest.range(of: ")*", range: open.upperBound..<rest.endIndex) {
                status = String(rest[open.upperBound..<close.lowerBound])
                rest = String(rest[..<open.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            guard let colon = rest.range(of: ": ") else { return nil }
            return IntelReport.PageLink(
                name: String(rest[..<colon.lowerBound]).trimmingCharacters(in: .whitespaces),
                urlString: String(rest[colon.upperBound...]).trimmingCharacters(in: .whitespaces),
                status: status
            )
        }
    }

    /// Drop leading/trailing blank and "---" lines.
    private static func clean(_ lines: [String]) -> [String] {
        var result = lines
        func isNoise(_ s: String) -> Bool {
            let t = s.trimmingCharacters(in: .whitespaces)
            return t.isEmpty || t == "---"
        }
        while let f = result.first, isNoise(f) { result.removeFirst() }
        while let l = result.last, isNoise(l) { result.removeLast() }
        return result
    }
}

// MARK: - Views

/// Typography-first rendering of an intel report: labeled blocks and
/// dividers, no decorative boxes — optimized for reading and scanning.
struct IntelReportView: View {
    let report: IntelReport
    /// Section ids to omit (e.g. shown separately by the page).
    var skipSectionIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let summary = report.summaryBody, !summary.isEmpty {
                LabeledBlock(label: "Summary", text: summary)
            }
            if let action = report.action, !action.isEmpty {
                LabeledBlock(label: "Action", text: action)
            }
            ForEach(report.sections.filter { !skipSectionIDs.contains($0.id) }) { section in
                sectionView(section)
            }
        }
    }

    private func sectionView(_ section: IntelReport.Section) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(section.title)
                    .font(.npDisplay(22))
                    .foregroundStyle(Color.npInk)
                if let website = section.website {
                    Link(destination: website) {
                        Image(systemName: "globe")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .help(website.absoluteString)
                }
            }
            if let meta = section.meta {
                Text(meta)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(section.fields) { field in
                LabeledBlock(label: displayLabel(field.label), text: field.text)
            }
            ForEach(section.pages) { page in
                pageDisclosure(page)
            }
            if !section.leftover.isEmpty {
                Markdown(section.leftover)
                    .markdownTheme(.nanopm)
                    .textSelection(.enabled)
            }
        }
    }

    private func displayLabel(_ label: String) -> String {
        label.lowercased() == "latest notable change" ? "Latest change" : label
    }

    private func pageDisclosure(_ page: IntelReport.Page) -> some View {
        DisclosureGroup {
            Markdown(page.body)
                .markdownTheme(.nanopm)
                .textSelection(.enabled)
                .padding(.top, 6)
        } label: {
            HStack(spacing: 8) {
                Text(page.title).fontWeight(.medium)
                if let hint = pageHint(page) {
                    Text(hint.text)
                        .font(.caption)
                        .foregroundStyle(hint.color)
                }
                Spacer()
                if let url = page.url {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
            }
        }
    }

    private func pageHint(_ page: IntelReport.Page) -> (text: String, color: Color)? {
        guard let first = page.body.components(separatedBy: "\n").first?
            .trimmingCharacters(in: .whitespaces),
              first.hasPrefix("*"), first.hasSuffix("*") else { return nil }
        let inner = first.lowercased()
        if inner.contains("fail") { return ("Fetch failed", .npRust) }
        if inner.contains("baseline") { return ("Baseline", .secondary) }
        if inner.contains("diff") || inner.contains("change") { return ("Changed", .npAmber) }
        return nil
    }
}

/// Small-caps secondary label above markdown body — the page's basic unit.
struct LabeledBlock: View {
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.weight(.semibold))
                .kerning(0.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Markdown(text)
                .markdownTheme(.nanopm)
                .textSelection(.enabled)
        }
    }
}
