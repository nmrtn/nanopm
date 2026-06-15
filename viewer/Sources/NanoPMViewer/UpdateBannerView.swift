import SwiftUI

/// A passive, dismissible bar across the top of the window announcing a newer
/// nanopm and offering a one-click update — Claude-Code style. Driven entirely
/// by `UpdateChecker.phase`; only on screen when `showBanner` is true.
struct UpdateBannerView: View {
    @EnvironmentObject private var checker: UpdateChecker

    var body: some View {
        HStack(spacing: 12) {
            leading
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.npInk)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            actions
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.npSurface)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.npBorder)
        }
    }

    // MARK: - Per-phase content

    @ViewBuilder
    private var leading: some View {
        switch checker.phase {
        case .updating:
            SparkleView(size: 14)
        case .updated:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.npOlive)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.npRust)
        case .blockedDevInstall:
            Image(systemName: "hammer.fill").foregroundStyle(Color.npAmber)
        default:
            Image(systemName: "arrow.down.circle.fill").foregroundStyle(Color.npCoral)
        }
    }

    private var title: String {
        switch checker.phase {
        case .updating:           return "Updating to v\(checker.remoteVersion)…"
        case .updated:            return "Updated to v\(checker.remoteVersion)"
        case .failed:             return "Update failed"
        case .blockedDevInstall:  return "Dev install detected"
        default:                  return "nanopm v\(checker.remoteVersion) available"
        }
    }

    private var subtitle: String? {
        switch checker.phase {
        case .available:
            return "You have v\(checker.localVersion)"
        case .updated:
            return "You're on the latest skills."
        case let .failed(message):
            return message
        case let .blockedDevInstall(path):
            return "Update from the terminal so you don't overwrite local work — \(path)"
        default:
            return nil
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch checker.phase {
        case .available:
            Button("Update now") { Task { await checker.update() } }
                .buttonStyle(.borderedProminent)
                .tint(Color.npCoral)
            dismissButton
        case .updating:
            EmptyView()
        case .failed:
            Button("Retry") { Task { await checker.update() } }
                .buttonStyle(.bordered)
            dismissButton
        case .updated, .blockedDevInstall:
            dismissButton
        default:
            EmptyView()
        }
    }

    private var dismissButton: some View {
        Button {
            checker.dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help("Dismiss until next launch")
    }
}
