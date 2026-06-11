import SwiftUI
import AppKit

struct ProjectPickerView: View {
    @EnvironmentObject private var recents: RecentsStore
    let onSelect: (Project) -> Void

    @State private var hasNanopm: [String: Bool] = [:]
    @State private var hoveredPath: String?

    /// The Nano blob mascot (transparent PNG bundled in Resources).
    private static let mascot: NSImage? = Bundle.module
        .url(forResource: "mascot", withExtension: "png")
        .flatMap { NSImage(contentsOf: $0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    if let mascot = Self.mascot {
                        Image(nsImage: mascot)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 76)
                            .padding(.bottom, 4)
                            .accessibilityHidden(true)
                    } else {
                        Text("✻")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(Color.npCoral)
                    }
                    Text("NanoPM Viewer")
                        .font(.npDisplay(32))
                        .foregroundStyle(Color.npInk)
                    Text("Browse the artifacts your NanoPM runs produced — without opening Claude Code.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 52)
                .padding(.bottom, 28)

                recentsCard
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 40)

                Button("Open Folder…") { openPanel() }
                    .keyboardShortcut("o")
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.npPaper)
        .task(id: recents.recents.map(\.path)) { await checkNanopm() }
    }

    /// The recents list, centered in a warm card.
    private var recentsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent projects")
                .font(.caption.weight(.semibold))
                .kerning(0.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider().overlay(Color.npBorder)

            if recents.recents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No recent projects")
                        .font(.headline)
                    Text("Open a project folder to get started — pick the repo where NanoPM ran.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(recents.recents) { project in
                        row(project)
                        if project.id != recents.recents.last?.id {
                            Divider()
                                .overlay(Color.npBorder.opacity(0.6))
                                .padding(.leading, 42)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(Color.npSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.npBorder))
    }

    private func row(_ project: Project) -> some View {
        Button {
            onSelect(project)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "folder")
                    .foregroundStyle(Color.npCoral)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name).font(.headline)
                    Text(project.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
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
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
            .background(hoveredPath == project.path ? Color.npNight.opacity(0.08) : .clear)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside {
                hoveredPath = project.path
            } else if hoveredPath == project.path {
                hoveredPath = nil
            }
        }
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
