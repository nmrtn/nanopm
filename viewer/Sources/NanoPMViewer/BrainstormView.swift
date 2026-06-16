import SwiftUI
import MarkdownUI

/// The Brainstorm surface: lands on a fresh chat by default, with past
/// conversations one click away (resumed via the host's native session resume).
/// A free-form jam with the virtual CPO — no gate, no artifact.
struct BrainstormView: View {
    @EnvironmentObject private var runManager: RunManager
    @StateObject private var store: BrainstormStore
    let projectPath: String

    @State private var draft = ""
    @State private var activeRunID: UUID?
    @State private var claudeAvailable: Bool?

    init(projectPath: String) {
        self.projectPath = projectPath
        _store = StateObject(wrappedValue: BrainstormStore(projectPath: projectPath))
    }

    private var activeRun: RunManager.SkillRun? {
        guard let activeRunID else { return nil }
        return runManager.runs.first { $0.id == activeRunID }
    }

    private var isBusy: Bool { activeRun?.isActive ?? false }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            conversation
            Divider()
            composer
        }
        .background(Color.npPaper)
        .task { claudeAvailable = await ShellRunner.claudeAvailable() }
        // Persist the host session id the moment this jam captures one, so it
        // shows up (and resumes) in the history later — including after relaunch.
        .onChange(of: activeRun?.sessionID) { _, sid in
            if let sid { store.remember(sid) }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .foregroundStyle(Color.npCoral)
            VStack(alignment: .leading, spacing: 1) {
                Text(activeRun?.title ?? "Brainstorm").font(.headline)
                Text(activeRun == nil
                     ? "Jam with a virtual CPO — informal, context-loaded"
                     : "Resumes via your host's session picker")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            historyMenu
            Button {
                newConversation()
            } label: {
                Label("New", systemImage: "square.and.pencil")
            }
            .help("Start a fresh brainstorm")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var historyMenu: some View {
        if store.sessions.isEmpty {
            EmptyView()
        } else {
            Menu {
                ForEach(store.sessions) { session in
                    Button {
                        resume(session)
                    } label: {
                        Text(session.title)
                        Text(session.lastActivity, format: .relative(presentation: .named))
                    }
                }
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Resume a past brainstorm")
        }
    }

    // MARK: - Conversation

    @ViewBuilder
    private var conversation: some View {
        if let run = activeRun {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if run.transcript.isEmpty {
                            resumeNote
                        }
                        ForEach(run.transcript) { entry in
                            bubble(entry)
                        }
                        if isBusy {
                            ThinkingIndicator(startedAt: run.startedAt)
                                .id("footer")
                        } else if case .failed(let message) = run.status {
                            failureNote(message).id("footer")
                        } else {
                            Color.clear.frame(height: 1).id("footer")
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 760, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: run.transcript) { _, _ in
                    withAnimation { proxy.scrollTo("footer", anchor: .bottom) }
                }
                .onChange(of: isBusy) { _, _ in
                    withAnimation { proxy.scrollTo("footer", anchor: .bottom) }
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 38))
                .foregroundStyle(Color.npCoral.opacity(0.7))
            Text("Start a brainstorm")
                .font(.npDisplay(24))
                .foregroundStyle(Color.npInk)
            Text("Think out loud with a virtual CPO that already knows this project's\nmission, personas, and objectives. No gate, no PRD — just jam.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !store.sessions.isEmpty {
                Text("Or pick up a past conversation from History above.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resumeNote: some View {
        Label("Continuing an earlier jam — your previous context is loaded. Send a message to pick up where you left off.",
              systemImage: "clock.arrow.circlepath")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.npSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func bubble(_ entry: RunManager.TranscriptEntry) -> some View {
        switch entry.role {
        case .model:
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text("CPO").font(.caption.bold())
                } icon: {
                    Text("✻").font(.caption.weight(.medium)).foregroundStyle(Color.npCoral)
                }
                .foregroundStyle(.secondary)
                Markdown(entry.text)
                    .markdownTheme(.nanopm)
                    .textSelection(.enabled)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.npSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.npBorder))
        case .user:
            VStack(alignment: .leading, spacing: 4) {
                Label("You", systemImage: "person.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(entry.text).textSelection(.enabled)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.npNight.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func failureNote(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("That turn failed", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.npRust)
            Text(message)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Text("Send another message to retry.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if claudeAvailable == false {
                Label("The `claude` CLI isn't on the app's PATH — brainstorming needs Claude Code installed and authenticated.",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Color.npRust)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField(activeRun == nil ? "What's on your mind?" : "Reply…",
                          text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .padding(10)
                    .background(Color.npSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.npBorder))
                    .disabled(isBusy || claudeAvailable == false)
                    .onSubmit(send)
                Button(action: send) {
                    if isBusy {
                        SparkleView(size: 13)
                    } else {
                        Image(systemName: "arrow.up.circle.fill").font(.title2)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .help("Send (⏎)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var canSend: Bool {
        !isBusy && claudeAvailable != false
            && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func send() {
        guard canSend else { return }
        let text = draft
        draft = ""
        if let id = activeRunID {
            runManager.sendMessage(id, text)
        } else {
            activeRunID = runManager.startBrainstorm(in: projectPath, firstMessage: text)
        }
    }

    private func newConversation() {
        activeRunID = nil
        draft = ""
        store.reload()
    }

    private func resume(_ session: BrainstormSession) {
        activeRunID = runManager.resumeBrainstorm(in: projectPath,
                                                  sessionID: session.id,
                                                  title: session.title)
    }
}
