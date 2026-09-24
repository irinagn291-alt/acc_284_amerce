import SwiftUI

/// Role: Arena. 7.4 elevation. `.regularMaterial` on cards, `.thinMaterial` on chips.
/// Surfaces sit above the page by frost. A flat surface tint is not this app's lift.
struct ParlorCard: ViewModifier {
    var padded: Bool = true

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: ParlorInk.Spacing.card, style: .continuous)
        content
            .padding(padded ? ParlorInk.Spacing.space(2) : 0)
            .background(.regularMaterial)
            .clipShape(shape)
            .contentShape(shape)
    }
}

/// Role: Arena. Chip lift is `.thinMaterial` at the chip radius.
struct ParlorChip: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: ParlorInk.Spacing.chip, style: .continuous)
        content
            .padding(.horizontal, ParlorInk.Spacing.space(1))
            .frame(minHeight: ParlorInk.Spacing.tap)
            .background(.thinMaterial)
            .clipShape(shape)
            .contentShape(shape)
    }
}

extension View {
    func parlorCard(padded: Bool = true) -> some View {
        modifier(ParlorCard(padded: padded))
    }

    func parlorChip() -> some View {
        modifier(ParlorChip())
    }

    func parlorPresentedSheet(detents: Set<PresentationDetent> = [.large]) -> some View {
        modifier(ParlorSheetLift(detents: detents))
    }
}

/// Role: Arena. Sheets size to a tall card and scroll. History starts medium and can grow.
struct ParlorSheetLift: ViewModifier {
    var detents: Set<PresentationDetent> = [.large]

    func body(content: Content) -> some View {
        content
            .presentationCornerRadius(ParlorInk.Spacing.card)
            .presentationBackground(.regularMaterial)
            .presentationDragIndicator(.visible)
            .presentationDetents(detents)
            .presentationContentInteraction(.scrolls)
    }
}
