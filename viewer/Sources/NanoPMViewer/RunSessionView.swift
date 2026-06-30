import SwiftUI
import MarkdownUI

/// Detail pane for a skill run: live status, the model's messages, and —
/// when the model is waiting — an interactive question form whose answers
/// resume the session.
struct RunSessionView: View {
    @EnvironmentObject private var runManager: RunManager
    let run: RunManager.SkillRun
    /// Called with an artifact id (relative path) to open it once produced.
    let onOpenArtifact: (String) -> Void

    /// A synthetic tracking key (`solutions:<slug>` / `prd:<slug>`) — a per-entity
    /// run that doesn't produce an artifact at its key, so the "Open" affordance
    /// and the `.nanopm/<path>` subtitle don't apply.
    private var isSyntheticKey: Bool { run.expectedRelPath.contains(":") }
    private var prettyTarget: String {
        String(run.expectedRelPath.split(separator: ":").last ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(run.transcript) { entry in
                            transcriptBubble(entry)
                        }
                        statusFooter
                            .id("footer")
                    }
                    .padding(24)
                    .frame(maxWidth: 760, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: run.transcript) { _, _ in
                    proxy.scrollTo("footer", anchor: .bottom)
                }
            }
            .background(Color.npPaper)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            statusChip
            VStack(alignment: .leading, spacing: 1) {
                Text(run.skillCommand).font(.headline)
                Text(isSyntheticKey
                     ? "\(prettyTarget) · started \(Text(run.startedAt, style: .relative)) ago"
                     : "→ .nanopm/\(run.expectedRelPath) · started \(Text(run.startedAt, style: .relative)) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if run.isActive {
                Button("Cancel", role: .destructive) {
                    runManager.cancel(run.id)
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var statusChip: some View {
        switch run.status {
        case .running:
            SparkleView(size: 13)
        case .waitingForInput:
            Image(systemName: "questionmark.bubble.fill").foregroundStyle(Color.npAmber)
        case .succeeded:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.npOlive)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.npRust)
        case .interrupted:
            Image(systemName: "bolt.slash.fill").foregroundStyle(Color.npAmber)
        }
    }

    @ViewBuilder
    private func transcriptBubble(_ entry: RunManager.TranscriptEntry) -> some View {
        switch entry.role {
        case .model:
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text("Claude").font(.caption.bold())
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
                Text(entry.text)
                    .textSelection(.enabled)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.npNight.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private var statusFooter: some View {
        switch run.status {
        case .running:
            VStack(alignment: .leading, spacing: 6) {
                ThinkingIndicator(startedAt: run.startedAt)
                if let activity = run.lastActivity {
                    Text(activity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text("You can keep browsing — a notification fires when the model needs you or the document is ready. Open the Activity Monitor (toolbar) to follow the live console.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        case .waitingForInput(let questions):
            QuestionForm(questions: questions) { answer in
                runManager.submitAnswers(run.id, answer)
            }
            .id(questions.map(\.question).joined())
        case .succeeded:
            VStack(alignment: .leading, spacing: 8) {
                if isSyntheticKey {
                    // Per-entity runs (solutions:<slug> / prd:<slug>) don't land at
                    // their tracking key, so there's no artifact to "Open" here —
                    // the result surfaces on the originating entity page instead.
                    Label("\(run.skillCommand) finished", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color.npOlive)
                } else {
                    Label("\(run.expectedRelPath) is ready", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color.npOlive)
                    Button("Open \(run.expectedRelPath)") {
                        onOpenArtifact(run.expectedRelPath)
                    }
                }
            }
            .padding(.top, 4)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 6) {
                Label("Run failed", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.npRust)
                Text(message)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(.top, 4)
        case .interrupted:
            VStack(alignment: .leading, spacing: 6) {
                Label("Run interrupted", systemImage: "bolt.slash.fill")
                    .font(.headline)
                    .foregroundStyle(Color.npAmber)
                Text("The app quit while this run was in progress, so it was stopped before finishing. Its work may be incomplete — re-run the skill to produce a clean result.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }
}

/// Native form for a `nanopm-question` block: option buttons (single or
/// multi-select) plus a free-text field per question.
struct QuestionForm: View {
    let questions: [UserQuestion]
    let onSubmit: (String) -> Void

    @State private var selected: [String: Set<String>] = [:]
    @State private var freeText: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Claude needs your input", systemImage: "questionmark.bubble.fill")
                .font(.headline)
                .foregroundStyle(Color.npAmber)

            ForEach(questions) { question in
                questionSection(question)
            }

            HStack {
                Spacer()
                Button("Send answers") {
                    onSubmit(composedAnswer())
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isComplete)
            }
        }
        .padding(16)
        .background(Color.npAmber.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.npAmber.opacity(0.3)))
    }

    @ViewBuilder
    private func questionSection(_ question: UserQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.question)
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            ForEach(question.choices, id: \.label) { option in
                optionRow(question, option)
            }

            TextField(question.choices.isEmpty ? "Your answer" : "Other / details (optional)",
                      text: binding(for: question),
                      axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
        }
    }

    private func optionRow(_ question: UserQuestion, _ option: UserQuestion.Option) -> some View {
        let isSelected = selected[question.id, default: []].contains(option.label)
        return Button {
            toggle(question, option)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isSelected
                      ? (question.isMultiSelect ? "checkmark.square.fill" : "checkmark.circle.fill")
                      : (question.isMultiSelect ? "square" : "circle"))
                    .foregroundStyle(isSelected ? Color.npNight : Color.secondary)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 1) {
                    Text(option.label).fontWeight(.medium)
                    if let description = option.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.npNight.opacity(0.10) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ question: UserQuestion, _ option: UserQuestion.Option) {
        var current = selected[question.id, default: []]
        if question.isMultiSelect {
            if current.contains(option.label) { current.remove(option.label) }
            else { current.insert(option.label) }
        } else {
            current = current.contains(option.label) ? [] : [option.label]
        }
        selected[question.id] = current
    }

    private func binding(for question: UserQuestion) -> Binding<String> {
        Binding(
            get: { freeText[question.id] ?? "" },
            set: { freeText[question.id] = $0 }
        )
    }

    /// Every question needs at least one selection or some free text.
    private var isComplete: Bool {
        questions.allSatisfy { question in
            !selected[question.id, default: []].isEmpty
                || !(freeText[question.id] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func composedAnswer() -> String {
        questions.map { question in
            let labels = selected[question.id, default: []].sorted().joined(separator: ", ")
            let extra = (freeText[question.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            var answer = labels
            if !extra.isEmpty {
                answer = answer.isEmpty ? extra : "\(answer) — \(extra)"
            }
            return "Q: \(question.question)\nA: \(answer)"
        }
        .joined(separator: "\n\n")
    }
}
