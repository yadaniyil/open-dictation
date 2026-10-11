import SwiftUI

/// Every colour, font and distance of the main screen and the set-up guides, so a restyle happens
/// in one place. The fonts are text styles, so they follow the user's text size.
enum HomeStyle {
    // MARK: Colours

    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let tint = Color.accentColor
    /// Text and pictures that sit on the accent colour.
    static let onTint = Color.white
    /// Behind a step's number and the microphone of "Try it here". A little stronger in dark
    /// mode, where a faint tint on a black page all but disappears.
    static let softTint = Color(UIColor { traits in
        UIColor.tintColor.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.3 : 0.14)
    })
    static let good = Color.green
    static let warning = Color.orange
    /// The round button while the app listens.
    static let recording = Color.red
    static let text = Color.primary
    static let secondaryText = Color.secondary

    // MARK: Fonts

    static let nameFont = Font.headline.weight(.bold)
    static let titleFont = Font.largeTitle.weight(.heavy)
    static let titleTracking: CGFloat = -0.5
    static let sectionFont = Font.footnote.weight(.semibold)
    static let stepFont = Font.headline
    static let badgeFont = Font.subheadline.weight(.bold)
    static let rowFont = Font.callout.weight(.semibold)
    static let detailFont = Font.subheadline
    static let bodyFont = Font.callout
    static let captionFont = Font.footnote
    static let buttonFont = Font.headline

    // MARK: Page

    static let sideMargin: CGFloat = 20
    static let topMargin: CGFloat = 8
    static let bottomMargin: CGFloat = 28
    static let barToTitle: CGFloat = 12
    static let titleToContent: CGFloat = 16
    /// Between the big parts of the page: the steps, "Try it here" and the recent texts.
    static let sectionSpacing: CGFloat = 22
    static let tileSpacing: CGFloat = 12
    /// Nothing that can be tapped is smaller than this.
    static let touchTarget: CGFloat = 44

    // MARK: Pictures

    /// The square a guide's small picture is drawn in.
    static let glyphSize: CGFloat = 30

    // MARK: Rows and cards

    static let rowCornerRadius: CGFloat = 20
    static let rowHeight: CGFloat = 60
    static let rowPadding: CGFloat = 14
    static let rowSpacing: CGFloat = 12
    static let roundButtonSize: CGFloat = 36
    static let textCardCornerRadius: CGFloat = 18
    static let textCardPadding: CGFloat = 16
    static let textCardSpacing: CGFloat = 10

    // MARK: Steps

    static let stepCornerRadius: CGFloat = 22
    static let stepPadding: CGFloat = 14
    static let stepPictureToWords: CGFloat = 16
    static let badgeSize: CGFloat = 26
    static let badgeToWords: CGFloat = 8
    static let stepWordsToScreenshot: CGFloat = 12
    static let screenshotCornerRadius: CGFloat = 14
    /// The frame around what to tap in a screenshot.
    static let screenshotFrameWidth: CGFloat = 3
    static let pillHeight: CGFloat = 44
    static let pillSidePadding: CGFloat = 18
    static let smallPillHeight: CGFloat = 34
    static let smallPillSidePadding: CGFloat = 14

    // MARK: Guide

    static let resultHeight: CGFloat = 56
    static let resultCornerRadius: CGFloat = 18
    static let resultToButton: CGFloat = 14
    static let buttonHeight: CGFloat = 56
    static let buttonCornerRadius: CGFloat = 16
    static let barBottomMargin: CGFloat = 12
    /// How far above the bottom bar the scrolling steps start to fade.
    static let barFade: CGFloat = 14
}
