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
    }

    var sections: [Section] = []
    var summaryBody: String?
    var action: String?
}

enum IntelReportParser {
    static func parse(_ markdown: String) -> IntelReport? {
        let lines = markdown.components(separatedBy: "\n").filter {
            !$0.trimmingCharacters(in: .whitespaces).hasPrefix("*Run /pm-competitors-intel")
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

/// Designed rendering of an intel report: summary & action callouts, then
/// one card per competitor with status chips and labeled blocks.
struct IntelReportView: View {
    let report: IntelReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let summary = report.summaryBody, !summary.isEmpty {
                summaryCard(summary)
            }
            if let action = report.action, !action.isEmpty {
                actionCallout(action)
            }
            ForEach(report.sections) { section in
                sectionCard(section)
            }
        }
    }

    private func summaryCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Summary", systemImage: "sparkles")
                .font(.headline)
            Markdown(text)
                .markdownTheme(.gitHub)
                .textSelection(.enabled)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.accentColor.opacity(0.25)))
    }

    private func actionCallout(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Action").font(.headline)
                Markdown(text)
                    .markdownTheme(.gitHub)
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.orange.opacity(0.25)))
    }

    private func sectionCard(_ section: IntelReport.Section) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label(section.title, systemImage: "building.2")
                    .font(.title3.bold())
                Spacer()
                if let website = section.website {
                    Link(destination: website) {
                        Label("Website", systemImage: "arrow.up.right")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quinary, in: Capsule())
                }
            }

            if let meta = section.meta {
                Text(meta)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !section.monitored.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8, alignment: .leading)],
                          alignment: .leading, spacing: 8) {
                    ForEach(section.monitored) { page in
                        monitoredChip(page)
                    }
                }
            }

            ForEach(section.fields) { field in
                fieldBlock(field)
            }

            ForEach(section.pages) { page in
                pageDisclosure(page)
            }

            if !section.leftover.isEmpty {
                Markdown(section.leftover)
                    .markdownTheme(.gitHub)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quinary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func monitoredChip(_ page: IntelReport.PageLink) -> some View {
        let label = HStack(spacing: 5) {
            Circle()
                .fill(page.failed ? Color.red : Color.green)
                .frame(width: 6, height: 6)
            Text(page.name)
                .font(.caption)
                .lineLimit(1)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.quinary, in: Capsule())

        if let url = page.url {
            Link(destination: url) { label }
                .buttonStyle(.plain)
                .help(page.status.map { "\(page.urlString) — \($0)" } ?? page.urlString)
        } else {
            label.help(page.status ?? "")
        }
    }

    @ViewBuilder
    private func fieldBlock(_ field: IntelReport.Field) -> some View {
        switch field.label.lowercased() {
        case "strategic note":
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Strategic note")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Markdown(field.text)
                        .markdownTheme(.gitHub)
                        .textSelection(.enabled)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        case "latest notable change":
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Latest change")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Markdown(field.text)
                        .markdownTheme(.gitHub)
                        .textSelection(.enabled)
                }
            }
        default:
            VStack(alignment: .leading, spacing: 3) {
                Text(field.label)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Markdown(field.text)
                    .markdownTheme(.gitHub)
                    .textSelection(.enabled)
            }
        }
    }

    private func pageDisclosure(_ page: IntelReport.Page) -> some View {
        DisclosureGroup {
            Markdown(page.body)
                .markdownTheme(.gitHub)
                .textSelection(.enabled)
                .padding(.top, 6)
        } label: {
            HStack(spacing: 8) {
                Text(page.title).fontWeight(.medium)
                if let hint = pageHint(page) {
                    Text(hint.text)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(hint.color.opacity(0.12), in: Capsule())
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
        if inner.contains("fail") { return ("Fetch failed", .red) }
        if inner.contains("baseline") { return ("Baseline", .secondary) }
        if inner.contains("diff") || inner.contains("change") { return ("Changed", .orange) }
        return nil
    }
}
