import SwiftUI
import MarkdownUI

/// Identifies one reasoning sidecar for the standalone window scene —
/// passed through `openWindow(id:value:)`, so it must be Codable & Hashable.
struct ReasoningWindowContext: Codable, Hashable {
    /// Absolute path to the sidecar file on disk.
    let absolutePath: String
    /// Display name of the clean doc this reasoning accompanies.
    let docName: String
}

/// Standalone window rendering a reasoning sidecar, so the clean doc and
/// its reasoning can be read side by side (same pattern as the Activity
/// Monitor window).
struct ReasoningWindowView: View {
    let context: ReasoningWindowContext

    @State private var content: String?
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reasoning — \(context.docName)")
                        .font(.npDisplay(26))
                        .foregroundStyle(Color.npInk)
                        .textSelection(.enabled)
                    Text(context.absolutePath)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Divider().overlay(Color.npBorder)

                if let loadError {
                    ContentUnavailableView(
                        "Couldn't read reasoning",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if let content {
                    Markdown(content)
                        .markdownTheme(.nanopm)
                        .textSelection(.enabled)
                } else {
                    SparkleView(size: 18)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                }
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .navigationTitle("Reasoning — \(context.docName)")
        .task(id: context.absolutePath) {
            await load()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await load() }
        }
    }

    private func load() async {
        do {
            let raw = try await ShellRunner.runAsync("cat \(ShellRunner.quote(context.absolutePath))")
            // Wiki-canonical: the source is the doc page — show just its
            // "## Provenance & assumptions" section. Legacy sidecar (no such heading):
            // show the whole file. Either way the window reads the rationale, not the
            // clean body twice.
            content = ReasoningFiles.extractProvenance(raw) ?? raw
            loadError = nil
        } catch {
            content = nil
            loadError = "\(error)"
        }
    }
}
