import SwiftUI

/// Role: Pack. Home surface for pack-locked fill. One strip, not three equal cards. Opens the pack seal.
struct PackHeatStrip: View {
    var arena: Arena
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let heat = PackHeat.snapshot(for: arena)
        let unused = arena.lockedPack?.unusedCount ?? 0
        let title = arena.lockedPack?.title ?? "No pack locked"
        Button(action: action) {
            HStack(alignment: .center, spacing: ParlorInk.Spacing.space(2)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(ParlorFigures.percent(heat.fill))
                        .font(ParlorInk.Font.figure)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .lineLimit(1)
                        .contentTransition(reduceMotion ? .opacity : .numericText())
                    Text(title)
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.muted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(ParlorFigures.count(unused))
                        .font(ParlorInk.Font.figure)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .layoutPriority(1)
                        .contentTransition(reduceMotion ? .opacity : .numericText())
                    Text("Unused dares")
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.muted)
                        .lineLimit(1)
                }
            }
            .padding(ParlorInk.Spacing.space(2))
            .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
            .overlay(alignment: .bottomLeading) {
                GeometryReader { geo in
                    ParlorInk.Color.accent.opacity(0.35)
                        .frame(
                            width: geo.size.width * PackHeat.clip(heat.fill),
                            height: ParlorInk.Spacing.space(1)
                        )
                }
                .frame(height: ParlorInk.Spacing.space(1))
            }
            .parlorCard(padded: false)
            .animation(reduceMotion ? nil : ParlorInk.Spacing.motion, value: unused)
            .animation(reduceMotion ? nil : ParlorInk.Spacing.motion, value: heat.fill)
        }
        .buttonStyle(QuietHeatStyle())
        .accessibilityLabel(accessLabel(heat: heat, unused: unused, title: title))
    }

    private func accessLabel(heat: PackHeat.Snapshot, unused: Int, title: String) -> String {
        "Locked pack \(title). Fill \(ParlorFigures.percent(heat.fill)). Unused dares \(ParlorFigures.count(unused))."
    }
}

struct QuietHeatStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(ParlorInk.Spacing.motion, value: configuration.isPressed)
    }
}
