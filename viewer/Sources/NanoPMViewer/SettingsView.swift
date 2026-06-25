import SwiftUI

/// Keys for values persisted in UserDefaults via @AppStorage. Centralized so the
/// Settings UI and the views that read a setting can't drift on the raw string.
enum AppSettings {
    /// Show the wiki entity pages grouped under each phase in the sidebar.
    static let displayEntities = "displayEntities"
}

/// The app's Settings window (⌘,, under the NanoPM Viewer menu). One pane for now —
/// navigation display options. Values persist in UserDefaults via @AppStorage, so the
/// sidebar (ProjectView) reads the same keys and updates live when a toggle changes.
struct SettingsView: View {
    @AppStorage(AppSettings.displayEntities) private var displayEntities = true

    var body: some View {
        Form {
            Section("Navigation") {
                Toggle("Display entities", isOn: $displayEntities)
                Text("Show the wiki entity pages (personas, competitors, features, …) grouped under each phase in the sidebar. Turn off to hide them and keep the navigation on the briefs and documents.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .scenePadding()
    }
}
