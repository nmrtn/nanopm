import SwiftUI
import AppKit

struct ProjectPickerView: View {
    @EnvironmentObject private var recents: RecentsStore
    let onSelect: (Project) -> Void

    @State private var hasNanopm: [String: Bool] = [:]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
                Text("NanoPM Viewer")
                    .font(.largeTitle.bold())
                Text("Browse the artifacts your NanoPM runs produced — without opening Claude Code.")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 44)
            .padding(.bottom, 24)

            Group {
                if recents.recents.isEmpty {
                    ContentUnavailableView(
                        "No recent projects",
                        systemImage: "clock",
                        description: Text("Open a project folder to get started — pick the repo where NanoPM ran.")
                    )
                } else {
                    List {
                        Section("Recent projects") {
                            ForEach(recents.recents) { project in
                                row(project)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)

            Divider()
            HStack {
                Spacer()
                Button("Open Folder…") { openPanel() }
                    .keyboardShortcut("o")
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
            }
            .padding(12)
        }
        .task(id: recents.recents.map(\.path)) { await checkNanopm() }
    }

    private func row(_ project: Project) -> some View {
        Button {
            onSelect(project)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "folder")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name).font(.headline)
                    Text(project.path).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if hasNanopm[project.path] == false {
                    Text("no .nanopm yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove from Recents") { recents.remove(project) }
        }
    }

    private func checkNanopm() async {
        for project in recents.recents {
            let dir = project.nanopmPath
            let result = try? await ShellRunner.runAsync("test -d \(ShellRunner.quote(dir)) && echo yes || echo no")
            hasNanopm[project.path] = (result?.trimmingCharacters(in: .whitespacesAndNewlines) == "yes")
        }
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a project folder — the repo where NanoPM ran."
        panel.prompt = "Open Project"
        if panel.runModal() == .OK, let url = panel.url {
            onSelect(Project(path: url.path))
        }
    }
}
