import SwiftUI

/// Role: Arena. One press language. Pin is tinted glass. Peel and reset never wear accent.
struct ParlorPressStyle: ButtonStyle {
    enum Kind {
        case pin
        case quiet
        case peel
        case danger
        case glyph
    }

    var kind: Kind = .quiet
    var isLoading: Bool = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: ParlorInk.Spacing.space(1)) {
            if isLoading {
                ProgressView()
                    .tint(ink)
            }
            configuration.label
        }
        .font(ParlorInk.Font.body)
        .foregroundStyle(ink)
        .frame(minWidth: ParlorInk.Spacing.tap, minHeight: ParlorInk.Spacing.tap)
        .padding(.horizontal, kind == .glyph ? 0 : ParlorInk.Spacing.space(2))
        .background(lift)
        .overlay { tint(pressed: configuration.isPressed) }
        .clipShape(shape)
        .contentShape(shape)
        .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1)
        .opacity(isEnabled ? 1 : 0.48)
        .animation(ParlorInk.Spacing.motion, value: configuration.isPressed)
        .animation(ParlorInk.Spacing.motion, value: isLoading)
    }

    private var radius: CGFloat {
        switch kind {
        case .pin, .peel, .danger:
            ParlorInk.Spacing.card
        case .quiet, .glyph:
            ParlorInk.Spacing.chip
        }
    }

    private var ink: Color {
        if !isEnabled {
            return ParlorInk.Color.muted
        }
        return ParlorInk.Color.ink
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    /// 7.4: Material is the only lift. Glyphs use thin. Pin tints the frost.
    private var lift: Material {
        kind == .glyph ? .thinMaterial : .regularMaterial
    }

    @ViewBuilder
    private func tint(pressed: Bool) -> some View {
        switch kind {
        case .pin:
            ParlorInk.Color.accent.opacity(pinOpacity(pressed: pressed))
        case .quiet, .glyph:
            if pressed {
                ParlorInk.Color.ink.opacity(0.06)
            }
        case .peel:
            if pressed {
                ParlorInk.Color.ink.opacity(0.06)
            }
        case .danger:
            ParlorInk.Color.ink.opacity(pressed ? 0.10 : 0.04)
        }
    }

    private func pinOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.06 }
        return pressed ? 0.28 : 0.16
    }
}
