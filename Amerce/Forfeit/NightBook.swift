import SwiftUI

/// Role: Forfeit. Night ledger as a sheet. Lands by name, a run of nights, empty lines.
struct NightBook: View {
    var store: ArenaStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            chrome
            if let error = store.lastWriteError {
                errorState(error)
            } else if store.arena.nights.isEmpty && store.arena.names.isEmpty {
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
            Text("History")
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
                landBoard
                ForEach(nightRun, id: \.self) { key in
                    nightBlock(key)
                }
            }
            .padding(.bottom, ParlorInk.Spacing.space(2))
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, ParlorInk.Spacing.space(2), for: .scrollContent)
    }

    private var landBoard: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            Text("Lands by name")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
            if store.arena.names.isEmpty {
                Text("No names are seated.")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.muted)
            } else {
                ForEach(store.arena.names) { guest in
                    HStack(spacing: ParlorInk.Spacing.space(1)) {
                        Text(guest.plate)
                            .font(ParlorInk.Font.body)
                            .foregroundStyle(ParlorInk.Color.ink)
                            .lineLimit(1)
                        Spacer(minLength: ParlorInk.Spacing.space(1))
                        Text(ParlorFigures.landed(lands(for: guest)))
                            .font(ParlorInk.Font.figure)
                            .foregroundStyle(ParlorInk.Color.ink)
                            .layoutPriority(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }

    private func nightBlock(_ key: Int) -> some View {
        let slips = store.arena.nights.first(where: { $0.key == key })?.forfeits ?? []
        return VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            HStack {
                Text(ParlorFigures.nightTitle(key))
                    .font(ParlorInk.Font.caption)
                    .foregroundStyle(ParlorInk.Color.muted)
                    .lineLimit(1)
                Spacer(minLength: ParlorInk.Spacing.space(1))
                Text(ParlorFigures.landed(slips.count))
                    .font(ParlorInk.Font.figure)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .layoutPriority(1)
            }
            if slips.isEmpty {
                Text("No lands this night.")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(slips) { slip in
                    HStack(alignment: .firstTextBaseline, spacing: ParlorInk.Spacing.space(1)) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(slip.plate)
                                .font(ParlorInk.Font.body)
                                .foregroundStyle(ParlorInk.Color.ink)
                                .lineLimit(1)
                            Text(ParlorFigures.spokenDare(slip.dare.line))
                                .font(ParlorInk.Font.caption)
                                .foregroundStyle(ParlorInk.Color.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(ParlorFigures.clock(slip.pinnedAt))
                            .font(ParlorInk.Font.figure)
                            .foregroundStyle(ParlorInk.Color.ink)
                            .layoutPriority(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .parlorCard()
    }

    private var nightRun: [Int] {
        var keys: [Int] = []
        var seen = Set<Int>()
        let now = Date()
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let key = NightStamp.from(day, calendar: calendar).rawValue
            if seen.insert(key).inserted {
                keys.append(key)
            }
        }
        for key in store.arena.nights.map(\.key).sorted().reversed() where seen.insert(key).inserted {
            keys.append(key)
        }
        return keys
    }

    private func lands(for guest: Name) -> Int {
        store.arena.nights.reduce(0) { total, night in
            total + night.forfeits.filter { $0.nameID == guest.id }.count
        }
    }

    private var emptyState: some View {
        VStack(spacing: ParlorInk.Spacing.space(2)) {
            ParlorArt.cutout(ParlorArt.emptyList)
                .frame(maxWidth: 240, maxHeight: 240)
            Text("The night has no forfeits yet.")
                .font(ParlorInk.Font.title)
                .foregroundStyle(ParlorInk.Color.ink)
                .multilineTextAlignment(.center)
            Text("Spin on the arena to pin the first dare.")
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: ParlorInk.Spacing.space(2))
            Button {
                dismiss()
            } label: {
                Text("Back to the wheel")
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .pin))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, ParlorInk.Spacing.space(1))
    }

    private func errorState(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            Text("History did not save.")
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
}

/// Role: Forfeit. Named History screen for the live driver. The night ledger body is NightBook.
struct NightHistory: View {
    var store: ArenaStore

    var body: some View {
        NightBook(store: store)
    }
}

#Preview {
    NightHistory(store: ArenaBooth.previewCharged())
}
