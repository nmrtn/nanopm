import SwiftUI
import AppKit

@main
struct NanoPMViewerApp: App {
    @StateObject private var recents = RecentsStore()
    @StateObject private var runManager = RunManager()
    @StateObject private var updateChecker = UpdateChecker()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
                // Hand the delegate the shared RunManager so it can guard the quit
                // path (confirm + graceful SIGTERM) — see applicationShouldTerminate.
                // Set from the view (not App.init) so the StateObject is installed.
                .task { appDelegate.runManager = runManager }
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

/// Guards the quit path. A viewer-launched run is a child `claude` process; if the
/// app just exits, that child dies uncleanly (SIGPIPE when our pipes close) and its
/// in-progress work is lost with no warning. On quit we (1) confirm with the user
/// when a run is in flight, and (2) gracefully SIGTERM every child so it can flush,
/// marking the runs `interrupted`. This is the minimal safe fix — not session resume.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The shared RunManager, injected from the root scene once it's installed.
    weak var runManager: RunManager?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let runManager, runManager.hasActiveRuns else { return .terminateNow }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "A skill run is in progress — quit anyway?"
        alert.informativeText = "In-progress work may be lost. The running skill will be stopped."
        alert.addButton(withTitle: "Quit Anyway")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            // Confirmed: gracefully stop children (SIGTERM, not silent SIGPIPE)
            // and mark the runs interrupted before the process exits.
            runManager.terminateAllForQuit()
            return .terminateNow
        }
        return .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Belt-and-suspenders: any other termination route (force quit via the
        // menu, logout) still tears children down gracefully rather than on SIGPIPE.
        runManager?.terminateAllForQuit()
    }
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
