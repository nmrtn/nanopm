import SwiftUI
import AppKit

/// Custom Lucide-style glyph for a phase, loaded from the bundled PhaseIcons
/// resources. Rendered as a template image so it follows the current
/// foreground style (sidebar selection, dark mode, crail headers). Falls back
/// to the phase's SF Symbol if the asset is missing.
struct PhaseIcon: View {
    let phase: Phase
    var size: CGFloat = 15

    var body: some View {
        if let nsImage = Self.image(for: phase) {
            Image(nsImage: nsImage)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: phase.icon)
        }
    }

    private static var cache: [Phase: NSImage] = [:]

    private static func image(for phase: Phase) -> NSImage? {
        if let cached = cache[phase] { return cached }
        guard let url = Bundle.module.url(forResource: phase.rawValue.lowercased(),
                                          withExtension: "png",
                                          subdirectory: "PhaseIcons"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        cache[phase] = image
        return image
    }
}
