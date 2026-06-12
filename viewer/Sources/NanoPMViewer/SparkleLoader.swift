import SwiftUI

/// The Claude-style activity mark: a coral asterisk that morphs through
/// spangled glyphs while work is in flight. Replaces ProgressView wherever
/// a run (not the app) is doing the waiting.
struct SparkleView: View {
    var size: CGFloat = 13
    var color: Color = .npCoral

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Forward-and-back through the asterisk family, like the CLI spinner.
    private static let frames = ["✢", "✳\u{FE0E}", "✶", "✻", "✽", "✻", "✶", "✳\u{FE0E}"]
    private static let frameDuration = 0.3

    var body: some View {
        if reduceMotion {
            glyph("✻")
        } else {
            TimelineView(.periodic(from: .now, by: Self.frameDuration)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate / Self.frameDuration)
                glyph(Self.frames[tick % Self.frames.count])
            }
        }
    }

    private func glyph(_ symbol: String) -> some View {
        Text(symbol)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size + 4, height: size + 4)
    }
}

/// Sparkle + a cycling PM-flavored gerund ("Mapping the terrain…"), with an
/// optional live elapsed-time suffix — the "Pondering…" moment, tuned for
/// product work.
struct ThinkingIndicator: View {
    /// Fixed label; nil cycles through the phrase deck.
    var phrase: String? = nil
    var startedAt: Date? = nil
    /// Caption-sized variant for status lines and sidebars.
    var compact = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let phrases = [
        "Pondering",
        "Mapping the terrain",
        "Distilling signal",
        "Reading the repo",
        "Connecting dots",
        "Weighing trade-offs",
        "Sharpening the wedge",
        "Sequencing bets",
        "Naming the risk",
        "Trimming scope",
        "Polishing prose",
    ]
    private static let phraseDuration = 2.8

    var body: some View {
        HStack(spacing: 7) {
            SparkleView(size: compact ? 11 : 13)
            if let phrase {
                label(phrase)
            } else if reduceMotion {
                label("Working")
            } else {
                TimelineView(.periodic(from: .now, by: Self.phraseDuration)) { context in
                    let tick = Int(context.date.timeIntervalSinceReferenceDate / Self.phraseDuration)
                    label(Self.phrases[tick % Self.phrases.count])
                }
            }
            if let startedAt {
                Text(startedAt, style: .relative)
                    .font((compact ? Font.caption2 : .caption).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text("\(text)…")
            .font(compact ? .caption : .callout)
            .foregroundStyle(Color.npCoral)
    }
}
