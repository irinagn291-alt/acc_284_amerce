import SwiftUI

/// Role: Arena. The only Color, Font, and Spacing accessors. Named catalog colours. Hex lives here and in Assets.
enum ParlorInk {
    /// SF Pro via Font.system. Six steps. No Font.custom and no second family.
    enum Font {
        static let face = "SF Pro"
        static let hero = SwiftUI.Font.system(size: 56, weight: .regular)
        static let title = SwiftUI.Font.system(size: 22, weight: .regular)
        static let body = SwiftUI.Font.system(size: 17, weight: .regular)
        static let figure = SwiftUI.Font.system(size: 17, weight: .regular).monospacedDigit()
        static let caption = SwiftUI.Font.system(size: 13, weight: .regular)
        static let footnote = SwiftUI.Font.system(size: 11, weight: .regular)
    }

    enum Color {
        /// Screen background #FCFCFC
        static let background = SwiftUI.Color("background")
        /// Pie slices and generated-art backing #F5F5F5. Cards lift with Material, not this tint.
        static let surface = SwiftUI.Color("surface")
        /// Primary text and icons #121212
        static let ink = SwiftUI.Color("ink")
        /// Primary action #27A586
        static let accent = SwiftUI.Color("amc_accent")
        /// Secondary text, dividers, disabled #575757
        static let muted = SwiftUI.Color("muted")
    }

    enum Spacing {
        static let unit: CGFloat = 8
        static let tap: CGFloat = 44
        static let card: CGFloat = 24
        static let chip: CGFloat = 10
        static let motion: Animation = .easeOut(duration: 0.18)
        /// Type-move divider between pie and stack. Not card elevation.
        static let rule: CGFloat = 1
        static let material: Material = .regularMaterial
        static let thin: Material = .thinMaterial

        static func space(_ units: Int) -> CGFloat {
            unit * CGFloat(units)
        }
    }
}
