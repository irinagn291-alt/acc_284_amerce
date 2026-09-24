import SwiftUI
import UIKit

/// Role: Arena. Root stage. The wheel never leaves. History, Settings, and Pack arrive as sheets.
@MainActor
struct ArenaStage: View {
    var store: ArenaStore
    var handlesLaunch: Bool

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 56
    @State private var parlorSheet: ParlorSheet?
    @State private var showOnboarding = false
    @State private var reviewConsumed = false
    @State private var nightStamp = NightStamp.from(Date(), calendar: .current)
    @State private var wheelDegrees = 0.0
    @State private var coasting = false
    @State private var pendingLandID: UUID?
    @State private var note: String?
    @State private var showSpinner = false
    @State private var flashSuccess = false
    @State private var hapticTask: Task<Void, Never>?

    init(store: ArenaStore, handlesLaunch: Bool = true) {
        self.store = store
        self.handlesLaunch = handlesLaunch
    }

    var body: some View {
        stage
            .background {
                LinearGradient(
                    colors: [
                        ParlorInk.Color.accent.opacity(0.10),
                        ParlorInk.Color.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .sheet(item: $parlorSheet) { sheet in
                sheetBody(sheet)
                    .parlorPresentedSheet(detents: sheet == .history ? [.medium, .large] : [.large])
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingPamphlet {
                    finishOnboarding()
                }
            }
            .task {
                guard handlesLaunch else { return }
                await bootstrap()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    nightStamp = NightStamp.from(Date(), calendar: .current)
                }
                guard handlesLaunch else { return }
                if phase == .inactive || phase == .background {
                    Task { await store.flush() }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                nightStamp = NightStamp.from(Date(), calendar: .current)
            }
            .onChange(of: store.arena.onboardingComplete) { _, complete in
                guard handlesLaunch, !complete else { return }
                showOnboarding = true
            }
            .onDisappear {
                hapticTask?.cancel()
            }
    }

    private var stage: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            chrome
            if let warning = store.warning {
                banner(text: warningCopy(warning), action: "Reload") {
                    Task { await store.load() }
                }
            } else if let error = store.lastWriteError {
                banner(text: "The parlor did not save. \(error)", action: "Retry") {
                    Task { await store.flush() }
                }
            }
            if store.arena.names.isEmpty {
                emptyPage
            } else {
                wheelPage
            }
        }
        .overlay {
            if showSpinner {
                ProgressView()
                    .tint(ParlorInk.Color.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
            if flashSuccess {
                ParlorArt.cutout(ParlorArt.successMark)
                    .frame(width: 96, height: 96)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : ParlorInk.Spacing.motion, value: flashSuccess)
    }

    private var chrome: some View {
        HStack(alignment: .center, spacing: ParlorInk.Spacing.space(1)) {
            Button {
                parlorSheet = .history
            } label: {
                Image(systemName: "book.closed")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .frame(width: ParlorInk.Spacing.tap, height: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .glyph))
            .accessibilityLabel("History")
            Spacer(minLength: ParlorInk.Spacing.space(1))
            Text("Amerce")
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.ink)
                .lineLimit(1)
            Spacer(minLength: ParlorInk.Spacing.space(1))
            Button {
                parlorSheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .frame(width: ParlorInk.Spacing.tap, height: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .glyph))
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, ParlorInk.Spacing.space(2))
        .padding(.top, ParlorInk.Spacing.space(1))
    }

    private var wheelPage: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            masthead
            PackHeatStrip(arena: store.arena) {
                parlorSheet = .pack
            }
            .padding(.horizontal, ParlorInk.Spacing.space(2))
            if let note {
                Text(note)
                    .font(ParlorInk.Font.caption)
                    .foregroundStyle(ParlorInk.Color.muted)
                    .padding(.horizontal, ParlorInk.Spacing.space(3))
            }
            if isRegularWidth {
                splitBoard
            } else {
                phoneBoard
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            Text("Forfeit")
                .font(.system(size: heroSize, weight: .regular))
                .foregroundStyle(ParlorInk.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text(ParlorFigures.nightHeading(nightStamp.rawValue))
                .font(ParlorInk.Font.figure)
                .foregroundStyle(ParlorInk.Color.ink)
                .contentTransition(reduceMotion ? .opacity : .numericText())
                .animation(reduceMotion ? nil : ParlorInk.Spacing.motion, value: nightStamp.rawValue)
                .accessibilityLabel("Night \(ParlorFigures.nightHeading(nightStamp.rawValue))")
            Text(statusLine)
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.muted)
                .lineLimit(3)
        }
        .padding(.horizontal, ParlorInk.Spacing.space(3))
    }

    private var phoneBoard: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            wheel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .padding(.horizontal, ParlorInk.Spacing.space(2))
            Rectangle()
                .fill(ParlorInk.Color.muted.opacity(0.35))
                .frame(height: ParlorInk.Spacing.rule)
                .padding(.horizontal, ParlorInk.Spacing.space(3))
            ScrollView {
                rail
            }
            .frame(maxHeight: ParlorInk.Spacing.space(18))
            .padding(.horizontal, ParlorInk.Spacing.space(2))
            spinControl
                .padding(.horizontal, ParlorInk.Spacing.space(2))
                .padding(.bottom, ParlorInk.Spacing.space(2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var splitBoard: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: ParlorInk.Spacing.space(3)) {
                VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
                    wheel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                    spinControl
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                ScrollView {
                    VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
                        rail
                        seatedBoard
                        remainingPack
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .padding(.horizontal, ParlorInk.Spacing.space(3))
        .padding(.bottom, ParlorInk.Spacing.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var seatedBoard: some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
            Text("On the wheel")
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.muted)
            ForEach(store.arena.names) { guest in
                HStack(spacing: ParlorInk.Spacing.space(1)) {
                    Text(guest.plate)
                        .font(ParlorInk.Font.body)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .lineLimit(1)
                    Spacer(minLength: ParlorInk.Spacing.space(1))
                    Text(guest.charge.isCharged ? ParlorFigures.landed(guest.charge.depth) : "Idle")
                        .font(ParlorInk.Font.figure)
                        .foregroundStyle(ParlorInk.Color.muted)
                        .layoutPriority(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var remainingPack: some View {
        Button {
            parlorSheet = .pack
        } label: {
            VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(1)) {
                Text(store.arena.lockedPack?.title ?? "No pack locked")
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .lineLimit(2)
                if leftoverDares.isEmpty {
                    Text("The pack has no unused dares.")
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.muted)
                } else {
                    ForEach(leftoverDares) { dare in
                        Text(ParlorFigures.spokenDare(dare.line))
                            .font(ParlorInk.Font.caption)
                            .foregroundStyle(ParlorInk.Color.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .parlorCard()
        }
        .buttonStyle(QuietHeatStyle())
        .accessibilityLabel("Open the locked pack")
    }

    private var leftoverDares: [Dare] {
        guard let pack = store.arena.lockedPack else { return [] }
        return Array(pack.dares.dropFirst(pack.nextIndex))
    }

    private var wheel: some View {
        WheelChart(
            names: store.arena.names,
            degrees: wheelDegrees,
            hubTitle: hubTitle,
            hubLine: hubLine,
            hubCaption: hubCaption
        )
    }

    private var rail: some View {
        ForfeitRail(
            names: store.arena.names,
            enabled: !coasting,
            hiding: pendingLandID,
            onClear: clear
        )
    }

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private var emptyPage: some View {
        VStack(spacing: ParlorInk.Spacing.space(2)) {
            ParlorArt.cutout(ParlorArt.emptyHome)
                .frame(maxWidth: 240, maxHeight: 240)
            Text("The wheel is empty.")
                .font(ParlorInk.Font.title)
                .foregroundStyle(ParlorInk.Color.ink)
                .multilineTextAlignment(.center)
            Text("Seat names so a land can pin a forfeit.")
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: ParlorInk.Spacing.space(2))
            Button {
                parlorSheet = .settings
            } label: {
                Text("Add names")
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .pin))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, ParlorInk.Spacing.space(3))
        .padding(.bottom, ParlorInk.Spacing.space(2))
    }

    private var spinControl: some View {
        VStack(spacing: ParlorInk.Spacing.space(1)) {
            Button {
                spin()
            } label: {
                Text("Spin")
                    .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .pin, isLoading: coasting))
            .disabled(!store.canPin || coasting)
            .accessibilityLabel("Spin the wheel. Pins the next dare.")
            if spent {
                Button {
                    parlorSheet = .pack
                } label: {
                    Text("Lock pack")
                        .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ParlorPressStyle(kind: .pin))
            }
        }
    }

    private var spent: Bool {
        store.arena.lockedPack?.isSpent == true
    }

    private var statusLine: String {
        if coasting {
            return "The wheel is turning."
        }
        if spent {
            return "The pack is spent. Lock a new pack to spin."
        }
        if store.canPin {
            return "Spin pins the next unused dare on a name. Tap Spin."
        }
        if store.arena.lockedPack == nil {
            return "Lock a pack in Settings, then tap Spin."
        }
        return "Spin pins the next unused dare on a name. Tap Spin."
    }

    private var pendingSlip: Forfeit? {
        store.arena.names.compactMap { $0.charge.slips.last }.first
    }

    private var hubTitle: String {
        if let slip = pendingSlip {
            return slip.plate
        }
        if store.arena.lockedPack == nil {
            return "Pack"
        }
        if spent {
            return "Spent"
        }
        return "Next"
    }

    private var hubLine: String {
        if let slip = pendingSlip {
            return ParlorFigures.spokenDare(slip.dare.line)
        }
        if let dare = store.arena.lockedPack?.nextDare() {
            return ParlorFigures.spokenDare(dare.line)
        }
        if spent {
            return "Lock a pack"
        }
        return "No pack"
    }

    private var hubCaption: String {
        if pendingSlip != nil {
            return "Tap Clear when it is done."
        }
        return ParlorFigures.unusedDares(store.arena.lockedPack?.unusedCount ?? 0)
    }

    private func banner(text: String, action: String, work: @escaping () -> Void) -> some View {
        HStack(alignment: .center, spacing: ParlorInk.Spacing.space(1)) {
            Text(text)
                .font(ParlorInk.Font.caption)
                .foregroundStyle(ParlorInk.Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: work) {
                Text(action)
                    .font(ParlorInk.Font.body)
                    .frame(minHeight: ParlorInk.Spacing.tap)
                    .padding(.horizontal, ParlorInk.Spacing.space(1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(ParlorPressStyle(kind: .quiet))
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, ParlorInk.Spacing.space(2))
        .parlorCard()
        .padding(.horizontal, ParlorInk.Spacing.space(2))
    }

    @ViewBuilder
    private func sheetBody(_ sheet: ParlorSheet) -> some View {
        switch sheet {
        case .history:
            NightHistory(store: store)
        case .settings:
            ParlorSettings(store: store, onRerunOnboarding: rerunOnboarding)
        case .pack:
            PackSeal(store: store)
        }
    }

    private func warningCopy(_ warning: ArenaWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            "The parlor restored a backup copy."
        case .startedEmpty:
            "The saved parlor could not be read. Starting empty."
        }
    }

    private func spin() {
        guard !coasting else { return }
        note = nil
        do {
            let fold = try store.pinForfeit()
            pendingLandID = fold.land.forfeit.id
            coast(fold.land.turn, stacked: fold.land.stacked, plate: fold.land.plate)
        } catch let fault as ArenaFault {
            note = faultCopy(fault)
        } catch {
            note = "Spin could not pin a forfeit. Try again."
        }
    }

    private func coast(_ turn: WheelTurn, stacked: Bool, plate: String) {
        coasting = true
        hapticTask?.cancel()
        let target = WheelTurn.pegRotation(landCenterDegrees: turn.landCenterDegrees)
        let from = WheelTurn.normalize(wheelDegrees)
        let delta = WheelTurn.clockwiseDistance(from: from, to: target)
        let travel = Double(turn.extraTurns) * 360 + delta
        if reduceMotion {
            wheelDegrees = target
            if store.arena.hapticsOn {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            finishLand(stacked: stacked, plate: plate)
            return
        }
        withAnimation(.easeOut(duration: turn.duration)) {
            wheelDegrees += travel
        }
        hapticTask = Task { @MainActor in
            if store.arena.hapticsOn {
                await pulse(turn)
            } else {
                try? await Task.sleep(nanoseconds: UInt64(turn.duration * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            if store.arena.hapticsOn {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            finishLand(stacked: stacked, plate: plate)
        }
    }

    private func finishLand(stacked: Bool, plate: String) {
        coasting = false
        pendingLandID = nil
        flashSuccess = true
        if stacked {
            note = "\(plate) stacked another forfeit. Tap Clear when it is done."
        } else {
            note = "\(plate) holds a forfeit. Tap Clear when it is done."
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            flashSuccess = false
        }
    }

    private func clear(nameID: UUID) {
        do {
            let fold = try store.clearForfeit(nameID: nameID)
            if store.arena.hapticsOn {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            if store.arena.name(id: nameID)?.charge.isIdle == true {
                note = "\(fold.peeled.plate) is clear."
            } else {
                note = "One forfeit peeled from \(fold.peeled.plate)."
            }
        } catch ArenaFault.idleClear {
            note = "That name has no forfeit to clear."
        } catch {
            note = "Clear could not peel a forfeit. Try again."
        }
    }

    private func faultCopy(_ fault: ArenaFault) -> String {
        switch fault {
        case .bare:
            "The wheel is empty. Seat names first."
        case .spent:
            "The pack is spent. Lock a new pack to spin."
        case .idleClear:
            "That name has no forfeit to clear."
        case .blankPlate:
            "A name plate cannot be blank."
        case .unknownName:
            "That name is not on the wheel."
        case .blankPack:
            "That pack has no usable dares."
        case .badPick:
            "The wheel could not land. Try Spin again."
        }
    }

    private func pulse(_ turn: WheelTurn) async {
        let start = Date()
        var fired: Set<Int> = []
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(start)
            for (index, time) in turn.pulseTimes.enumerated() where elapsed >= time && !fired.contains(index) {
                fired.insert(index)
                let style: UIImpactFeedbackGenerator.FeedbackStyle
                if index < 2 {
                    style = .light
                } else if index < 4 {
                    style = .medium
                } else {
                    style = .heavy
                }
                UIImpactFeedbackGenerator(style: style).impactOccurred()
            }
            if elapsed >= turn.duration { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    private func bootstrap() async {
        let delay = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled {
                showSpinner = true
            }
        }
        await store.load()
        await store.seedDemoIfNeeded()
        delay.cancel()
        showSpinner = false
        if store.arena.onboardingComplete {
            applyReview()
        } else {
            showOnboarding = true
        }
    }

    private func finishOnboarding() {
        if store.arena.lockedPack == nil {
            try? store.lockPack(ParlorPacks.wax)
        }
        store.markOnboardingComplete()
        showOnboarding = false
        applyReview()
    }

    private func rerunOnboarding() {
        parlorSheet = nil
        store.reopenOnboarding()
        showOnboarding = true
    }

    private func applyReview() {
        guard let stage = ReviewStage.consumeLive(
            onboardingComplete: store.arena.onboardingComplete,
            consumed: &reviewConsumed
        ) else { return }
        parlorSheet = ParlorSheet.from(stage: stage)
    }
}

#Preview("Charged") {
    ArenaStage(store: ArenaBooth.previewCharged(), handlesLaunch: false)
}

#Preview("Empty") {
    ArenaStage(store: ArenaBooth.previewEmpty(), handlesLaunch: false)
}
