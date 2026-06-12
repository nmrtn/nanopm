import SwiftUI
import AppKit
import MarkdownUI

// MARK: - Palette
//
// The Nano brand palette (see BRAND.md at the repo root), adapted for macOS
// light & dark appearances: coral orange carries the identity, deep navy is
// the ink and control accent, and dark mode lives on bleu-nuit paper.
// Olive / amber / rust are functional states tuned to sit on both papers.

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    /// Appearance-adaptive color from a light/dark hex pair.
    static func np(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(hex: dark)
                : NSColor(hex: light)
        })
    }

    /// Reading background — brand off-white in light, deep navy in dark.
    static let npPaper = np(light: 0xF7F6F4, dark: 0x0B1330)
    /// Raised surfaces: cards, bubbles, code blocks.
    static let npSurface = np(light: 0xEFEDE8, dark: 0x161F45)
    /// Hairline borders on paper.
    static let npBorder = np(light: 0xE5E2DA, dark: 0x252F5C)
    /// Coral Orange #FF5A3C — the brand accent: mascot, loaders, icons, links.
    static let npCoral = np(light: 0xFF5A3C, dark: 0xFF5A3C)
    /// Deep Navy #0B1330 — control accent: selections, hovers, interactive
    /// chrome. Mirrors the AccentColor asset compiled into the app bundle;
    /// lightened in dark mode to stay visible on the navy paper.
    static let npNight = np(light: 0x0B1330, dark: 0x9FB0E8)
    /// Deep Navy #0B1330, fixed across appearances — the sidebar selection
    /// highlight (set as the nav List tint), kept brand-navy in both modes.
    static let npSelection = Color(nsColor: NSColor(hex: 0x0B1330))
    /// Ink for display titles — the wordmark navy on light paper.
    static let npInk = np(light: 0x0B1330, dark: 0xEDEFF6)
    /// Success / done.
    static let npOlive = np(light: 0x5E714B, dark: 0x9DB07D)
    /// Waiting on the human.
    static let npAmber = np(light: 0x9A6A07, dark: 0xD9A85C)
    /// Failure.
    static let npRust = np(light: 0xB3442E, dark: 0xE0705A)
}

// MARK: - Type

extension Font {
    /// Display serif (New York) — the editorial voice for titles.
    static func npDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

// MARK: - Markdown

extension MarkdownUI.Theme {
    /// GitHub structure on nanopm paper: serif headings, crail links,
    /// transparent background so the warm canvas shows through.
    static let nanopm = MarkdownUI.Theme.gitHub
        .text {
            FontSize(15)
        }
        .link {
            ForegroundColor(Color.npCoral)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
            BackgroundColor(Color.npSurface)
        }
        .heading1 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontFamily(.system(.serif))
                        FontWeight(.semibold)
                        FontSize(.em(1.9))
                    }
                Divider().overlay(Color.npBorder)
            }
        }
        .heading2 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontFamily(.system(.serif))
                        FontWeight(.semibold)
                        FontSize(.em(1.45))
                    }
                Divider().overlay(Color.npBorder)
            }
        }
        .heading3 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontFamily(.system(.serif))
                    FontWeight(.semibold)
                    FontSize(.em(1.2))
                }
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.npCoral.opacity(0.45))
                    .relativeFrame(width: .em(0.2))
                configuration.label
                    .markdownTextStyle { ForegroundColor(.secondary) }
                    .relativePadding(.horizontal, length: .em(1))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .codeBlock { configuration in
            ScrollView(.horizontal) {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.225))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(14)
            }
            .background(Color.npSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .markdownMargin(top: 0, bottom: 16)
        }
}
