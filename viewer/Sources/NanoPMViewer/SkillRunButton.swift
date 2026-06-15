import SwiftUI

/// The Run action for a single skill, with its three states — **Run** (with the
/// optional pre-launch context popover), **Answer…** (the model is waiting on
/// the human), and **Running…** — built on the shared `ActionButton` chrome.
///
/// One component so launching a skill looks and behaves identically wherever its
/// output is visible: the phase overview rows and the document's own detail
/// header. Each instance owns its popover state, so several can coexist on a page.
struct SkillRunButton: View {
    let doc: SkillDoc
    @ObservedObject var store: ArtifactStore
    /// Whether the `claude` CLI was found; nil while still probing. Run is
    /// disabled when it's explicitly false.
    let claudeAvailable: Bool?
    /// Navigate to the live run session when the model is waiting for input.
    let onAnswer: (String) -> Void

    @EnvironmentObject private var runManager: RunManager
    @State private var launchOpen = false
    @State private var launchContext = ""
    @FocusState private var launchContextFocused: Bool

    var body: some View {
        let run = runManager.latestRun(for: doc.trackingPath, in: store.project.path)
        let isRunning = run?.status == .running
        let isWaiting = run?.pendingQuestions.isEmpty == false

        if isWaiting {
            ActionButton(title: "Answer…", systemImage: "questionmark.bubble.fill",
                         tone: .waiting,
                         help: "\(doc.skillCommand ?? "") needs your input — answer to continue") {
                onAnswer(doc.trackingPath)
            }
        } else if isRunning {
            Button {} label: {
                HStack(spacing: 6) {
                    SparkleView(size: 11)
                    Text("Running…")
                }
            }
            .buttonStyle(ActionButtonStyle(tone: .accent))
            .disabled(true)
        } else {
            Button { launchOpen = true } label: {
                Label("Run", systemImage: "play.fill")
            }
            .buttonStyle(ActionButtonStyle(tone: .accent, prominent: true))
            .disabled(claudeAvailable == false)
            .help("Runs \(doc.skillCommand ?? "") headlessly in \(store.project.name)")
            .popover(isPresented: $launchOpen, arrowEdge: .bottom) { launchPopover }
        }
    }

    /// Pre-launch step: an optional free-text note passed to the model with the
    /// skill command — the topic, scope, or anything it should know.
    @ViewBuilder
    private var launchPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Run \(doc.skillCommand ?? doc.title)")
                .font(.headline)
            Text("Add context for the model — the topic, the scope, a decision already made… Optional; leave empty to just run.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            TextField("e.g. Focus on the new Define section",
                      text: $launchContext, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)
                .focused($launchContextFocused)
                .onSubmit { launchNow() }
            HStack {
                Spacer()
                Button("Cancel") {
                    launchOpen = false
                    launchContext = ""
                }
                Button(launchContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                       ? "Run" : "Run with context") {
                    launchNow()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 340)
        .onAppear { launchContextFocused = true }
    }

    private func launchNow() {
        runManager.launch(doc, in: store.project.path, userContext: launchContext)
        launchOpen = false
        launchContext = ""
    }
}
