import Charts
import SwiftUI

/// Role: Arena. The only Charts surface. One SectorMark per Name. Rotation seats the land on slice centre.
struct WheelChart: View {
    var names: [Name]
    var degrees: Double
    var hubTitle: String
    var hubLine: String
    var hubCaption: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                chart
                    .frame(width: side, height: side)
                    .rotationEffect(.degrees(degrees))
                    .clipShape(Circle())
                hub
                    .frame(width: side * 0.52, height: side * 0.52)
                peg
                    .offset(y: -(side / 2) + ParlorInk.Spacing.space(2))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary)
    }

    private var slices: [WheelSlice] {
        names.enumerated().map { index, name in
            WheelSlice(
                id: name.id,
                plate: name.plate,
                charged: name.charge.isCharged,
                depth: name.charge.depth,
                ordinal: index
            )
        }
    }

    private var chart: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Share", 1),
                innerRadius: .ratio(0.56),
                angularInset: ParlorInk.Spacing.rule
            )
            .foregroundStyle(fill(slice))
            .annotation(position: .overlay) {
                VStack(spacing: 0) {
                    Text(slice.plate)
                        .font(ParlorInk.Font.caption)
                        .foregroundStyle(ParlorInk.Color.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    if slice.charged {
                        Text(ParlorFigures.count(slice.depth))
                            .font(ParlorInk.Font.figure)
                            .foregroundStyle(ParlorInk.Color.ink)
                    }
                }
                .padding(.horizontal, ParlorInk.Spacing.space(1))
            }
        }
        .chartLegend(.hidden)
        .chartBackground { _ in
            Color.clear
        }
    }

    private var hub: some View {
        ZStack {
            Color.clear
                .background(.regularMaterial)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .fill(ParlorInk.Color.accent.opacity(0.10))
                }
            VStack(spacing: 0) {
                Text(hubTitle)
                    .font(ParlorInk.Font.caption)
                    .foregroundStyle(ParlorInk.Color.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(hubLine)
                    .font(ParlorInk.Font.body)
                    .foregroundStyle(ParlorInk.Color.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .animation(reduceMotion ? nil : ParlorInk.Spacing.motion, value: hubLine)
                Text(hubCaption)
                    .font(ParlorInk.Font.caption)
                    .foregroundStyle(ParlorInk.Color.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, ParlorInk.Spacing.space(1))
            .padding(.vertical, 0)
        }
        .accessibilityHidden(true)
    }

    private var peg: some View {
        Image(systemName: "arrowtriangle.down.fill")
            .font(ParlorInk.Font.body)
            .foregroundStyle(ParlorInk.Color.ink)
            .accessibilityHidden(true)
    }

    private var summary: String {
        let plates = names.map(\.plate).joined(separator: ", ")
        if plates.isEmpty {
            return "Empty parlor wheel"
        }
        return "Parlor wheel with \(ParlorFigures.count(names.count)) names. \(plates)"
    }

    private func fill(_ slice: WheelSlice) -> Color {
        if slice.charged {
            return ParlorInk.Color.accent.opacity(0.38)
        }
        if slice.ordinal % 2 == 0 {
            return ParlorInk.Color.surface
        }
        return ParlorInk.Color.ink.opacity(0.08)
    }
}

struct WheelSlice: Identifiable, Equatable, Sendable {
    var id: UUID
    var plate: String
    var charged: Bool
    var depth: Int
    var ordinal: Int
}
