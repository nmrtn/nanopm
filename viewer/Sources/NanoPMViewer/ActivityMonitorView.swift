import SwiftUI

/// Live activity monitor: every skill run across the session in a sidebar,
/// with a live console for the selected one. Built to follow several parallel
/// conversations at once. Opened in its own window.
struct ActivityMonitorView: View {
    @EnvironmentObject private var runManager: RunManager
    @State private var selection: UUID?

    /// Newest run first.
    private var runs: [RunManager.SkillRun] {
        runManager.runs.sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(runs) { run in
                    runRow(run).tag(run.id)
                }
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
            .overlay {
                if runs.isEmpty {
                    ContentUnavailableView(
                        "No runs yet",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Launch a skill from a project's Discover page to watch it here, live.")
                    )
                }
            }
        } detail: {
            if let run = runs.first(where: { $0.id == selection }) ?? runs.first {
                RunConsoleView(run: run)
                    .id(run.id)
            } else {
                ContentUnavailableView("Select a run", systemImage: "sidebar.right",
                                       description: Text("Pick a run to follow its live console."))
            }
        }
        .navigationTitle("Activity Monitor")
        .onChange(of: runManager.runs.count) { _, _ in
            if selection == nil { selection = runs.first?.id }
        }
        .onAppear { if selection == nil { selection = runs.first?.id } }
    }

    private func runRow(_ run: RunManager.SkillRun) -> some View {
        HStack(spacing: 10) {
            StatusDot(status: run.status)
            VStack(alignment: .leading, spacing: 2) {
                Text(run.skillCommand).font(.headline)
                Text("\(run.projectName) · \(run.startedAt, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if run.isActive, let activity = run.lastActivity {
                    Text(activity)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text("\(run.events.count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

/// Colored status indicator shared by the monitor and toolbar.
struct StatusDot: View {
    let status: RunManager.SkillRun.Status

    var body: some View {
        Group {
            switch status {
            case .running:
                SparkleView(size: 12)
            case .waitingForInput:
                Image(systemName: "questionmark.circle.fill").foregroundStyle(Color.npAmber)
            case .succeeded:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.npOlive)
            case .failed:
                Image(systemName: "xmark.circle.fill").foregroundStyle(Color.npRust)
            }
        }
        .frame(width: 18, height: 18)
    }
}

/// Scrolling, auto-following console of a single run's streamed events.
struct RunConsoleView: View {
    let run: RunManager.SkillRun
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(run.events) { event in
                            EventRow(event: event, showTurn: run.turnCount > 1)
                            Divider().opacity(0.4)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: run.events.count) { _, _ in
                    if autoScroll { withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
                }
                .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            StatusDot(status: run.status)
            VStack(alignment: .leading, spacing: 1) {
                Text(run.skillCommand).font(.headline)
                Text("\(run.projectName) · → .nanopm/\(run.expectedRelPath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("Follow", isOn: $autoScroll)
                .toggleStyle(.switch)
                .controlSize(.mini)
            if case .failed = run.status {} else if !run.isActive {} else {
                EmptyView()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

/// One console line — icon, title, timestamp, and an expandable monospaced body.
struct EventRow: View {
    let event: RunManager.LogEvent
    let showTurn: Bool
    @State private var expanded = false

    private var tint: Color {
        switch event.kind {
        case .toolUse: return .secondary
        case .toolResult: return .npOlive
        case .error: return .npRust
        case .assistant: return .npCoral
        case .result: return .secondary
        default: return .secondary
        }
    }

    private var bodyIsLong: Bool { (event.detail?.count ?? 0) > 160 }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: event.icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                    .frame(width: 16)
                Text(event.title)
                    .font(.callout.weight(.medium))
                if showTurn {
                    Text("T\(event.turn)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text(event.at, format: .dateTime.hour().minute().second())
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            if let detail = event.detail, !detail.isEmpty {
                Text(expanded || !bodyIsLong ? detail : String(detail.prefix(160)) + "…")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding(.leading, 24)
                    .lineLimit(expanded ? nil : 6)
                if bodyIsLong {
                    Button(expanded ? "Show less" : "Show more") { expanded.toggle() }
                        .buttonStyle(.link)
                        .font(.caption2)
                        .padding(.leading, 24)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
