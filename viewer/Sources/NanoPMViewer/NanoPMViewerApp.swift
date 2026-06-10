import SwiftUI

@main
struct NanoPMViewerApp: App {
    @StateObject private var recents = RecentsStore()
    @StateObject private var runManager = RunManager()

    init() {
        SmokeTest.runIfRequested()
    }

    var body: some Scene {
        WindowGroup("NanoPM Viewer") {
            ContentView()
                .environmentObject(recents)
                .environmentObject(runManager)
                .frame(minWidth: 900, minHeight: 580)
        }
        .defaultSize(width: 1100, height: 720)
    }
}

struct ContentView: View {
    @EnvironmentObject private var recents: RecentsStore
    @State private var currentProject: Project?

    var body: some View {
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
