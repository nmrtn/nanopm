import SwiftUI

/// Shared chrome for the viewer's primary actions — **Run**, **Refresh**,
/// **Reasoning** — so the same action reads the same way on every screen:
/// an SF Symbol icon + a text label, the brand palette, and hover/press
/// feedback. Three tones tell the eye what kind of action it is.
///
/// Used three ways, all sharing this one implementation:
/// - `ActionButton` — the common icon + label button (Run, Refresh, Reasoning).
/// - `.buttonStyle(ActionButtonStyle(...))` on a bare `Button` — for custom
///   labels like Run's "Running…" spinner, or icon-only controls.
/// - `.menuStyle(.button).buttonStyle(ActionButtonStyle(...))` on a `Menu` —
///   for the multi-option variants (Competitors Run, History).
struct ActionButtonStyle: ButtonStyle {
    enum Tone {
        /// Default secondary action — Refresh, Reasoning, History.
        case neutral
        /// Primary call-to-action — Run.
        case accent
        /// Waiting on the human — Answer….
        case waiting

        var fg: Color {
            switch self {
            case .neutral: return Color(nsColor: .secondaryLabelColor)
            case .accent:  return .npCoral
            case .waiting: return .npAmber
            }
        }

        var tint: Color {
            switch self {
            case .neutral: return .npNight
            case .accent:  return .npCoral
            case .waiting: return .npAmber
            }
        }
    }

    var tone: Tone = .neutral
    /// Filled, high-emphasis treatment (white label on the tint) — used for the
    /// active/primary state of an action.
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        Chrome(tone: tone, prominent: prominent, configuration: configuration)
    }

    private struct Chrome: View {
        static let cornerRadius: CGFloat = 7
        let tone: Tone
        let prominent: Bool
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 12, weight: .medium))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(prominent ? Color.white : tone.fg)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(background, in: RoundedRectangle(cornerRadius: Self.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Self.cornerRadius).strokeBorder(borderColor)
                )
                .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
                .onHover { hovering = $0 && isEnabled }
                .animation(.easeOut(duration: 0.12), value: hovering)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }

        private var background: Color {
            if prominent {
                return tone.tint.opacity(hovering ? 0.88 : 1)
            }
            return tone.tint.opacity(hovering ? 0.16 : 0.09)
        }

        private var borderColor: Color {
            prominent ? .clear : tone.tint.opacity(hovering ? 0.45 : 0.22)
        }
    }
}

/// The common case: an icon + label button with the shared chrome.
struct ActionButton: View {
    let title: String
    let systemImage: String
    var tone: ActionButtonStyle.Tone = .neutral
    var prominent: Bool = false
    var help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(ActionButtonStyle(tone: tone, prominent: prominent))
        .modifier(OptionalHelp(text: help))
    }
}

/// Attaches `.help` only when help text is present, so a button without a
/// tooltip doesn't get an empty-string one.
private struct OptionalHelp: ViewModifier {
    let text: String?
    func body(content: Content) -> some View {
        if let text, !text.isEmpty {
            content.help(text)
        } else {
            content
        }
    }
}
