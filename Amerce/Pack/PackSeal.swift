import SwiftUI
import UIKit

/// Role: Pack. Twist screen. Lock a dare pack. Spin consumes unused Dares. A spent pack stays refused.
struct PackSeal: View {
    var store: ArenaStore

    @Environment(\.dismiss) private var dismiss
    @State private var note: String?
    @State private var lockBusy = false

    var body: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            chrome
            if let error = store.lastWriteError {
                errorState(error)
            } else if store.arena.lockedPack == nil && store.arena.names.isEmpty {
                emptyState
            } else {
                populated
            }
        }
        .padding(ParlorInk.Spacing.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var chrome: some View {
        HStack(spacing: ParlorInk.Spacing.space(1)) {
            Text("Locked pack")
                .font(ParlorInk.Font.title)
                .foregroundStyle(ParlorInk.Color.ink)
                .lineLimit(1)
            Spacer(minLength: ParlorInk.Spacing.space(1))
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .frame(width: ParlorInk.Spacing.tap, height: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .glyph))
            .accessibilityLabel("Close")
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
                ParlorArt.cutout(ParlorArt.twistHero)
                    .frame(maxWidth: .infinity, maxHeight: 220)
                Text("Pack-locked forfeit")
                    .font(ParlorInk.Font.title)
                    .foregroundStyle(ParlorInk.Color.ink)
                Text("Spin writes the next unused dare onto the landed name. Clear peels one forfeit. A later land on a charged name stacks another.")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.muted)
                if let note {
                    Text(note)
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.muted)
                }
                if let pack = store.arena.lockedPack {
                    currentCard(pack)
                }
                ForEach(ParlorPacks.all) { pack in
                    Button {
                        lock(pack)
                    } label: {
                        HStack(spacing: ParlorInk.Spacing.space(1)) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(pack.title)
                                    .font(ParlorInk.Font.body)
                                    .foregroundStyle(ParlorInk.Color.ink)
                                    .lineLimit(1)
                                Text("\(ParlorFigures.count(pack.dares.count)) dares")
                                    .font(ParlorInk.Font.caption)
                                    .foregroundStyle(ParlorInk.Color.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(isCurrent(pack) ? "Locked" : "Lock")
                                .font(ParlorInk.Font.figure)
                                .foregroundStyle(ParlorInk.Color.ink)
                                .layoutPriority(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(ParlorPressStyle(kind: .quiet))
                    .disabled(lockBusy)
                    .accessibilityLabel("Lock pack \(pack.title)")
                }
            }
            .padding(.bottom, ParlorInk.Spacing.space(2))
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, ParlorInk.Spacing.space(2), for: .scrollContent)
    }

    private func currentCard(_ pack: Pack) -> some View {
        let heat = PackHeat.snapshot(for: store.arena)
        return VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            HStack(spacing: ParlorInk.Spacing.space(1)) {
                Text(pack.title)
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: ParlorInk.Spacing.space(1))
                Text(ParlorFigures.percent(heat.fill))
                    .font(ParlorInk.Font.figure)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .layoutPriority(1)
            }
            Text(pack.isSpent ? "Spent. Lock a new pack to spin." : "Next unused dare pins on the next land.")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
            Text("Unused \(ParlorFigures.count(pack.unusedCount)) of \(ParlorFigures.count(pack.dares.count))")
                .font(ParlorInk.Font.figure)
                .foregroundStyle(ParlorInk.Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }

    private var emptyState: some View {
        VStack(spacing: ParlorInk.Spacing.space(2)) {
            ParlorArt.cutout(ParlorArt.twistHero)
                .frame(maxWidth: 240, maxHeight: 240)
            Text("No pack is locked.")
                .font(ParlorInk.Font.title)
                .foregroundStyle(ParlorInk.Color.ink)
                .multilineTextAlignment(.center)
            Text("Lock a dare pack so Spin has a forfeit to pin.")
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.muted)
                .multilineTextAlignment(.center)
            Button {
                lock(ParlorPacks.wax)
            } label: {
                Text("Lock a pack")
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .pin))
            .disabled(lockBusy)
            Spacer(minLength: ParlorInk.Spacing.space(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            Text("The pack could not save.")
                .font(ParlorInk.Font.title)
                .foregroundStyle(ParlorInk.Color.ink)
            Text(error)
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.muted)
            Button {
                Task { await store.flush() }
            } label: {
                Text("Retry")
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .pin))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .parlorCard()
    }

    private func isCurrent(_ pack: Pack) -> Bool {
        store.arena.lockedPack?.title == pack.title
    }

    private func lock(_ pack: Pack) {
        lockBusy = true
        do {
            try store.lockPack(pack)
            note = "\(pack.title) is locked. Spin pins the next unused dare."
            if store.arena.hapticsOn {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } catch ArenaFault.blankPack {
            note = "That pack has no usable dares."
        } catch {
            note = "The pack could not be locked. Try again."
        }
        lockBusy = false
    }
}

#Preview {
    PackSeal(store: ArenaBooth.previewCharged())
}
