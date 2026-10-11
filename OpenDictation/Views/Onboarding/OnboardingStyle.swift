import SwiftUI

/// Every colour, font and distance of the first-launch screens, so a restyle happens in one place.
/// The fonts are text styles, so they follow the user's text size.
enum OnboardingStyle {
    // MARK: Colours

    static let background = Color(.systemGroupedBackground)
    static let tile = Color(.secondarySystemGroupedBackground)
    static let tint = Color.accentColor
    /// Text and pictures that sit on the accent colour.
    static let onTint = Color.white
    /// The check marks, and the shield on the consent page.
    static let good = Color.green
    static let text = Color.primary
    static let dot = Color.primary.opacity(0.18)

    // MARK: Fonts

    static let titleFont = Font.largeTitle.weight(.heavy)
    static let titleTracking: CGFloat = -0.5
    static let labelFont = Font.callout.weight(.semibold)
    static let captionFont = Font.subheadline
    static let buttonFont = Font.headline
    static let linkFont = Font.subheadline.weight(.medium)

    // MARK: Page

    static let sideMargin: CGFloat = 16
    static let topMargin: CGFloat = 16
    static let bottomMargin: CGFloat = 20
    static let heroToTitle: CGFloat = 30
    static let titleToTiles: CGFloat = 22
    /// Where the page sits in the room it has, when it needs less: 0 is the top, 1 the bottom.
    static let verticalAnchor: CGFloat = 0.45

    // MARK: Tiles

    static let tileCornerRadius: CGFloat = 22
    /// Small on purpose: the words are centred, and a narrow phone needs the width for them.
    static let tileSidePadding: CGFloat = 10
    static let tileVerticalPadding: CGFloat = 20
    static let tileSpacing: CGFloat = 12
    /// The square a tile's picture is drawn in. It grows a little with the text size.
    static let pictureSize: CGFloat = 44
    static let pictureToLabel: CGFloat = 10
    static let labelToCaption: CGFloat = 4

    // MARK: Button, link and dots

    static let buttonHeight: CGFloat = 56
    static let buttonCornerRadius: CGFloat = 16
    static let buttonSidePadding: CGFloat = 16
    /// Only matters for very large text, when the words are taller than the button's own height.
    static let buttonVerticalPadding: CGFloat = 10
    static let buttonToLink: CGFloat = 4
    /// Tall enough to tap, however small the words are.
    static let linkHeight: CGFloat = 44
    static let barBottomMargin: CGFloat = 12
    /// How far above the button the scrolling tiles start to fade.
    static let barFade: CGFloat = 24
    static let dotSize: CGFloat = 8
    static let currentDotWidth: CGFloat = 22
    static let dotSpacing: CGFloat = 7
    static let dotsBottomMargin: CGFloat = 8
}
