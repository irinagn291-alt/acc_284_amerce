import SwiftUI
import UIKit

/// Role: Arena. Settings sheet. Lock a Pack, seat Names, contact, reset, re-run onboarding.
struct ParlorDesk: View {
    var store: ArenaStore
    var onRerunOnboarding: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var plateFocused: Bool
    @State private var plate = ""
    @State private var confirmReset = false
    @State private var dropTarget: Name?
    @State private var resetBusy = false
    @State private var note: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
                chrome
                if let error = store.lastWriteError {
                    errorState(error)
                } else if store.arena.names.isEmpty && store.arena.lockedPack == nil {
                    emptyState
                } else {
                    populated
                }
            }
            .padding(ParlorInk.Spacing.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(minHeight: horizontalSizeClass == .regular ? ParlorInk.Spacing.space(90) : 0)
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        plateFocused = false
                    }
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .frame(minHeight: ParlorInk.Spacing.tap)
                }
            }
            .confirmationDialog(
                "Erase names, the locked pack, and every night?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset all data", role: .destructive) {
                    Task { await resetAll() }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                dropCopy,
                isPresented: Binding(
                    get: { dropTarget != nil },
                    set: { if !$0 { dropTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove name", role: .destructive) {
                    if let dropTarget {
                        unseat(dropTarget.id)
                    }
                }
                Button("Keep", role: .cancel) { dropTarget = nil }
            }
        }
    }

    private var dropCopy: String {
        if let plate = dropTarget?.plate {
            return "Remove \(plate) from the wheel?"
        }
        return "Remove this name from the wheel?"
    }

    private var chrome: some View {
        HStack(spacing: ParlorInk.Spacing.space(1)) {
            Text("Settings")
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
                if let note {
                    Text(note)
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .parlorCard()
                }
                namesCard
                packCard
                hapticsCard
                parlorActionsCard
            }
            .padding(.bottom, ParlorInk.Spacing.space(3))
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, ParlorInk.Spacing.space(2), for: .scrollContent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var namesCard: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            Text("Names")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
            seatField
            ForEach(store.arena.names) { guest in
                HStack(spacing: ParlorInk.Spacing.space(1)) {
                    Text(guest.plate)
                        .font(ParlorInk.Font.body)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: ParlorInk.Spacing.space(1))
                    Text(guest.charge.isCharged ? ParlorFigures.count(guest.charge.depth) : "Idle")
                        .font(ParlorInk.Font.figure)
                        .foregroundStyle(ParlorInk.Color.muted)
                        .layoutPriority(1)
                    Button {
                        dropTarget = guest
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(ParlorInk.Font.body)
                            .foregroundStyle(ParlorInk.Color.ink)
                            .frame(width: ParlorInk.Spacing.tap, height: ParlorInk.Spacing.tap)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(guest.plate)")
                }
                .frame(minHeight: ParlorInk.Spacing.tap)
            }
            Text("\(ParlorFigures.count(store.arena.names.count)) seated. Names stay on the wheel after a land.")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }

    private var packCard: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            Text("Pack")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
            ForEach(ParlorPacks.all) { pack in
                packRow(pack)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }

    private func packRow(_ pack: Pack) -> some View {
        let current = store.arena.lockedPack?.title == pack.title
        let unused = current ? (store.arena.lockedPack?.unusedCount ?? pack.dares.count) : pack.dares.count
        return Button {
            lock(pack)
        } label: {
            HStack(alignment: .center, spacing: ParlorInk.Spacing.space(1)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(pack.title)
                        .font(ParlorInk.Font.body)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .lineLimit(1)
                    Text(ParlorFigures.unusedDares(unused))
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.muted)
                        .lineLimit(1)
                    Text(current ? "Spin pins from this pack." : "Lock to pin from this pack.")
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.muted)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(current ? "Locked" : "Lock")
                    .font(ParlorInk.Font.figure)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(ParlorPressStyle(kind: .quiet))
        .accessibilityLabel(current ? "\(pack.title) is locked" : "Lock pack \(pack.title)")
    }

    private var hapticsCard: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            Text("Haptics")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
            Button {
                store.setHaptics(!store.arena.hapticsOn)
            } label: {
                HStack {
                    Text(store.arena.hapticsOn ? "Landing climax on" : "Landing climax off")
                        .font(ParlorInk.Font.body)
                        .foregroundStyle(ParlorInk.Color.ink)
                    Spacer()
                    Text(store.arena.hapticsOn ? "On" : "Off")
                        .font(ParlorInk.Font.figure)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .quiet))
            .accessibilityLabel("Haptics")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }

    private var parlorActionsCard: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            Text("Parlor")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
            Button {
                onRerunOnboarding()
            } label: {
                Text("Re-run onboarding")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .quiet))
            Button {
                openURL(CardRunner.contactURL)
            } label: {
                Text("Contact Amerce")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .quiet))
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .quiet))
            .disabled(resetBusy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }

    private var seatField: some View {
        HStack(spacing: ParlorInk.Spacing.space(1)) {
            TextField("Name plate", text: $plate)
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.ink)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .focused($plateFocused)
                .submitLabel(.done)
                .onSubmit { seat() }
                .frame(minHeight: ParlorInk.Spacing.tap)
            Button {
                seat()
            } label: {
                Text("Seat")
                    .font(ParlorInk.Font.body)
                    .frame(minWidth: ParlorInk.Spacing.space(8), minHeight: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .pin))
            .disabled(plate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var emptyState: some View {
        VStack(spacing: ParlorInk.Spacing.space(2)) {
            ParlorArt.cutout(ParlorArt.emptyHome)
                .frame(maxWidth: 240, maxHeight: 240)
            Text("No names are seated.")
                .font(ParlorInk.Font.title)
                .foregroundStyle(ParlorInk.Color.ink)
                .multilineTextAlignment(.center)
            Text("Seat a name, then lock a pack so Spin can pin a forfeit.")
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.muted)
                .multilineTextAlignment(.center)
            seatField
            Spacer(minLength: ParlorInk.Spacing.space(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            Text("Settings could not save.")
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

    private func seat() {
        let trimmed = plate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try store.seat(trimmed)
            plate = ""
            plateFocused = false
            note = nil
        } catch ArenaFault.blankPlate {
            note = "A name plate cannot be blank."
        } catch {
            note = "That name could not be seated. Try again."
        }
    }

    private func lock(_ pack: Pack) {
        do {
            try store.lockPack(pack)
            note = "\(pack.title) is locked."
            if store.arena.hapticsOn {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } catch ArenaFault.blankPack {
            note = "That pack has no usable dares."
        } catch {
            note = "The pack could not be locked. Try again."
        }
    }

    private func unseat(_ id: UUID) {
        do {
            try store.unseat(id)
            note = nil
        } catch {
            note = "That name could not be removed. Try again."
        }
        dropTarget = nil
    }

    private func resetAll() async {
        resetBusy = true
        await store.resetAllData()
        resetBusy = false
        dismiss()
    }
}

/// Role: Arena. Named Settings screen for the live driver. The desk body is ParlorDesk.
struct ParlorSettings: View {
    var store: ArenaStore
    var onRerunOnboarding: () -> Void

    var body: some View {
        ParlorDesk(store: store, onRerunOnboarding: onRerunOnboarding)
    }
}

#Preview {
    ParlorSettings(store: ArenaBooth.previewCharged(), onRerunOnboarding: {})
}
