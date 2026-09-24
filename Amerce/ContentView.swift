import SwiftUI

/// Role: Arena. Window root. Arena-locked chrome lives in ArenaStage.
@MainActor
struct ContentView: View {
    @State private var store: ArenaStore

    init(store: ArenaStore) {
        _store = State(initialValue: store)
    }

    init() {
        _store = State(initialValue: ArenaBooth.live())
    }

    var body: some View {
        ArenaStage(store: store)
            .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView(store: ArenaBooth.previewCharged())
}
