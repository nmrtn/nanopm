import SwiftUI

@main
struct NanoPMViewerApp: App {
    @StateObject private var recents = RecentsStore()
    @StateObject private var runManager = RunManager()
    @StateObject private var updateChecker = UpdateChecker()

    init() {
        SmokeTest.runIfRequested()
    }

    var body: some Scene {
        WindowGroup("NanoPM Viewer") {
            ContentView()
                .environmentObject(recents)
                .environmentObject(runManager)
                .environmentObject(updateChecker)
                .frame(minWidth: 900, minHeight: 580)
        }
        .defaultSize(width: 1100, height: 720)
        .windowStyle(.hiddenTitleBar)

        Window("Activity Monitor", id: Self.activityWindowID) {
            ActivityMonitorView()
                .environmentObject(runManager)
                .frame(minWidth: 640, minHeight: 420)
        }
        .defaultSize(width: 900, height: 640)

        // One window per reasoning sidecar (re-opening the same sidecar
        // focuses the existing window), so a doc and its reasoning can be
        // read side by side.
        WindowGroup("Reasoning", id: Self.reasoningWindowID, for: ReasoningWindowContext.self) { $context in
            if let context {
                ReasoningWindowView(context: context)
                    .frame(minWidth: 460, minHeight: 420)
            }
        }
        .defaultSize(width: 620, height: 760)

        // Native macOS Settings window (⌘, , under the NanoPM Viewer menu).
        Settings {
            SettingsView()
        }
    }

    static let activityWindowID = "activity-monitor"
    static let reasoningWindowID = "reasoning"
}

struct ContentView: View {
    @EnvironmentObject private var recents: RecentsStore
    @EnvironmentObject private var updateChecker: UpdateChecker
    @State private var currentProject: Project?

    var body: some View {
        VStack(spacing: 0) {
            if updateChecker.showBanner {
                UpdateBannerView()
            }
            content
        }
        .task { await updateChecker.check() }
    }

    @ViewBuilder
    private var content: some View {
        if let project = currentProject {
            ProjectView(project: project) {
                currentProject = nil
            }
            .id(project.path)
        } else {
            ProjectPickerView { project in
                recents.touch(project)
                currentProject = project
            }
        }
    }
}
