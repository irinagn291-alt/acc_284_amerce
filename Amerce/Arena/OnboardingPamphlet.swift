import SwiftUI

/// Role: Arena. Three pages. Skip writes a locked pack. Re-runnable from Settings.
struct OnboardingPamphlet: View {
    var onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 56

    var body: some View {
        VStack(spacing: ParlorInk.Spacing.space(2)) {
            Group {
                switch page {
                case 0:
                    pageBody(
                        art: ParlorArt.onboarding1,
                        title: "Pin a dare",
                        line: "A host spins the wheel. The land pins the next unused dare on that name."
                    )
                case 1:
                    pageBody(
                        art: ParlorArt.onboarding2,
                        title: "Clear when done",
                        line: "That name taps Clear. The forfeit peels. The name stays on the wheel."
                    )
                default:
                    pageBody(
                        art: ParlorArt.onboarding3,
                        title: "Stack the night",
                        line: "A later land on a charged name stacks another forfeit. Lock a new pack when this one is spent."
                    )
                }
            }
            .id(page)
            .frame(maxHeight: .infinity)
            .transition(.opacity)
            VStack(spacing: ParlorInk.Spacing.space(1)) {
                Button {
                    advance()
                } label: {
                    Text(page < 2 ? "Continue" : "Start")
                        .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ParlorPressStyle(kind: .pin))
                Button {
                    onFinish()
                } label: {
                    Text("Skip")
                        .frame(maxWidth: .infinity, minHeight: ParlorInk.Spacing.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ParlorPressStyle(kind: .quiet))
            }
        }
        .padding(ParlorInk.Spacing.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ParlorInk.Color.background.ignoresSafeArea())
    }

    private func advance() {
        if page < 2 {
            if reduceMotion {
                page += 1
            } else {
                withAnimation(ParlorInk.Spacing.motion) { page += 1 }
            }
            return
        }
        onFinish()
    }

    private func pageBody(art: String, title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: ParlorInk.Spacing.space(2)) {
            ParlorArt.cutout(art)
                .frame(maxWidth: .infinity, maxHeight: 280)
            Text(title)
                .font(.system(size: heroSize, weight: .regular))
                .foregroundStyle(ParlorInk.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text(line)
                .font(ParlorInk.Font.body)
                .foregroundStyle(ParlorInk.Color.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    OnboardingPamphlet(onFinish: {})
}
