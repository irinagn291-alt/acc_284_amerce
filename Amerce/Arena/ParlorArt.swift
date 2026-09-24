import SwiftUI

/// Role: Arena. Named catalog art from section 13. Cutouts stay decorative for VoiceOver.
enum ParlorArt {
    static let emptyHome = "amc_EmptyHome"
    static let emptyList = "amc_EmptyList"
    static let onboarding1 = "amc_Onboarding1"
    static let onboarding2 = "amc_Onboarding2"
    static let onboarding3 = "amc_Onboarding3"
    static let cardBackdrop = "amc_CardBackdrop"
    static let controlFace = "amc_ControlFace"
    static let twistHero = "amc_TwistHero"
    static let successMark = "amc_SuccessMark"
    static let headerDecor = "amc_HeaderDecor"

    static func cutout(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    static func fill(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .clipped()
            .accessibilityHidden(true)
    }
}
