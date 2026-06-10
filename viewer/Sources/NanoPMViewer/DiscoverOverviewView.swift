import SwiftUI

/// Recap page for the Discover phase: every canonical discovery document,
/// its status (generated / running / missing), and run actions.
struct DiscoverOverviewView: View {
    @ObservedObject var store: ArtifactStore
    @EnvironmentObject private var runManager: RunManager
    /// Called with an artifact id to open it in the detail pane.
    let onOpen: (String) -> Void

    @State private var claudeAvailable: Bool?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Discover", systemImage: "magnifyingglass")
                        .font(.largeTitle.bold())
                    Text("Signal, research & audits — what's true about your users and your product, before you plan.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if claudeAvailable == false {
                    Label("The `claude` CLI was not found in your shell PATH — run actions are disabled.",
                          systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }

                ForEach(DiscoverCatalog.docs) { doc in
                    row(doc)
                }

                Text("Runs execute the skill headlessly (`claude -p`) in the project folder — keep the app open while a run is in flight. You can keep browsing; a notification fires when the document is ready.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .task { await checkClaude() }
    }

    @ViewBuilder
    private func row(_ doc: DiscoverDoc) -> some View {
        let artifact = store.artifacts.first { $0.relativePath == doc.relativePath }
        let run = runManager.latestRun(for: doc.relativePath, in: store.project.path)
        let isRunning = run?.status == .running

        HStack(alignment: .top, spacing: 14) {
            Image(systemName: doc.icon)
                .font(.title3)
                .frame(width: 34, height: 34)
                .background(.quinary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title).font(.headline)
                Text(doc.blurb)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let artifact {
                    HStack(spacing: 6) {
                        Button {
                            onOpen(artifact.id)
                        } label: {
                            Label(artifact.fileName, systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.link)
                        Text("· updated \(artifact.modifiedAt, format: .relative(presentation: .named))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if isRunning, let run {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Generating — started \(Text(run.startedAt, style: .relative)) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if case .failed(let message)? = run?.status {
                    Label(String(message.prefix(120)), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("Not generated yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 12)

            if doc.skillCommand != nil {
                if isRunning {
                    Button {} label: {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Running…")
                        }
                    }
                    .disabled(true)
                } else {
                    Button(artifact == nil ? "Run" : "Re-run") {
                        runManager.launch(doc, in: store.project.path)
                    }
                    .disabled(claudeAvailable == false)
                    .help("Runs \(doc.skillCommand ?? "") headlessly in \(store.project.name)")
                }
            }
        }
        .padding(14)
        .background(.quinary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func checkClaude() async {
        let result = try? await ShellRunner.runAsync("zsh -lc 'command -v claude' 2>/dev/null")
        claudeAvailable = !(result ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Detail pane for an in-flight or failed run (the placeholder sidebar rows).
struct RunStatusView: View {
    let run: RunManager.SkillRun

    var body: some View {
        VStack(spacing: 14) {
            switch run.status {
            case .running:
                ProgressView().controlSize(.large)
                Text("\(run.skillCommand) is running")
                    .font(.title2.bold())
                Text("Started \(Text(run.startedAt, style: .relative)) ago.")
                    .foregroundStyle(.secondary)
                Text("You can keep browsing — a notification fires when \(run.expectedRelPath) is ready. Keep the app open.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
                Text("\(run.skillCommand) failed")
                    .font(.title2.bold())
                Text(message)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            case .succeeded:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                Text("\(run.expectedRelPath) is ready")
                    .font(.title2.bold())
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }
}
