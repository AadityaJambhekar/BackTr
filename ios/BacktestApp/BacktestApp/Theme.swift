// Theme.swift
// Backtr design system — colors, typography, and hex initializer.

import SwiftUI
import UIKit

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

extension Color {
    static let backtrBg     = Color(hex: "0a0a0f")
    static let backtrCard   = Color(hex: "141418")
    static let backtrBorder = Color(hex: "222222")
    static let backtrAccent = Color(hex: "4F8EF7")
    static let backtrGreen  = Color(hex: "34d17a")
    static let backtrRed    = Color(hex: "ff453a")
    static let backtrMuted  = Color(hex: "555560")
    static let backtrSub    = Color(hex: "888890")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xff) / 255
        let g = Double((int >>  8) & 0xff) / 255
        let b = Double((int      ) & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// Card modifier
struct BacktrCard: ViewModifier {
    var radius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(Color.backtrCard)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Color.backtrBorder, lineWidth: 0.5))
    }
}

extension View {
    func backtrCard(radius: CGFloat = 16) -> some View { modifier(BacktrCard(radius: radius)) }
}

/// The small caps section header used above input groups (TICKER, STRATEGY, etc).
/// One definition so the whole app's micro-labels move together.
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.backtrMuted)
            .tracking(0.6)
    }
}

extension Font {
    /// Rounded design gives the wordmark and hero numbers a friendlier, less
    /// generic-sans feel than plain .system, while staying native SF.
    static func backtrDisplay(_ size: CGFloat, weight: Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Pill-shaped primary action. Capsule (not the 14pt rounded-rect cards use)
/// keeps buttons visually distinct from containers, with a tactile press state.
struct BacktrPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.backtrAccent)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Pill-shaped secondary action — tinted outline, same press feedback as primary.
struct BacktrSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.backtrCard)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.backtrBorder, lineWidth: 0.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Tinted pill for secondary CTAs that need accent color (e.g. "Compare All Strategies").
struct BacktrTintedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.backtrAccent.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.backtrAccent.opacity(0.3), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
