import SwiftUI

/// Role: Forfeit. Open Charge stack on the Arena. One row per Charged Name. Clear peels the top Forfeit.
struct ForfeitRail: View {
    var names: [Name]
    var enabled: Bool
    var hiding: UUID?
    var onClear: (UUID) -> Void

    var body: some View {
        if tops.isEmpty {
            emptyCard
        } else {
            VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
                ForEach(tops) { slip in
                    row(slip)
                }
            }
        }
    }

    private var tops: [Forfeit] {
        names.compactMap { name in
            var slips = name.charge.slips
            if let hiding {
                slips.removeAll { $0.id == hiding }
            }
            return slips.last
        }
    }

    private var emptyCard: some View {
        Text("Open forfeits sit here after a land.")
            .font(ParlorInk.Font.caption)
            .foregroundStyle(ParlorInk.Color.muted)
            .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap, alignment: .leading)
            .parlorCard()
    }

    private func row(_ slip: Forfeit) -> some View {
        var slips = names.first(where: { $0.id == slip.nameID })?.charge.slips ?? []
        if let hiding {
            slips.removeAll { $0.id == hiding }
        }
        let shownDepth = slips.count
        return HStack(alignment: .center, spacing: ParlorInk.Spacing.space(1)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: ParlorInk.Spacing.space(1)) {
                    Text(slip.plate)
                        .font(ParlorInk.Font.body)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if shownDepth > 1 {
                        Text(ParlorFigures.count(shownDepth))
                            .font(ParlorInk.Font.figure)
                            .foregroundStyle(ParlorInk.Color.ink)
                            .parlorChip()
                            .layoutPriority(1)
                            .accessibilityLabel("Stack depth \(ParlorFigures.count(shownDepth))")
                    }
                }
                Text(ParlorFigures.spokenDare(slip.dare.line))
                    .font(ParlorInk.Font.caption)
                    .foregroundStyle(ParlorInk.Color.muted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onClear(slip.nameID)
            } label: {
                Text("Clear")
                    .font(ParlorInk.Font.body)
                    .frame(minWidth: ParlorInk.Spacing.space(8), minHeight: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .peel))
            .fixedSize(horizontal: true, vertical: false)
            .disabled(!enabled)
            .accessibilityLabel("Clear \(slip.plate)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }
}
