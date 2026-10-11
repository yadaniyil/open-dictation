import SwiftUI

/// The one layout every first-launch page uses: an optional drawing, the title, the tiles, and
/// the main button held at the bottom. The page scrolls, so the largest text sizes still fit.
struct OnboardingPageView: View {
    let page: OnboardingPage
    /// True while the button's work is under way, so it cannot be tapped twice.
    let isBusy: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let description = page.heroDescription {
                    OnboardingHero(description: description)
                        .padding(.bottom, OnboardingStyle.heroToTitle)
                }

                Text(page.title)
                    .font(OnboardingStyle.titleFont)
                    .tracking(OnboardingStyle.titleTracking)
                    .foregroundStyle(OnboardingStyle.text)
                    .multilineTextAlignment(.center)
                    // A title may be broken into lines by hand. VoiceOver reads it in one go.
                    .accessibilityLabel(String(localized: page.title).replacing("\n", with: " "))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, OnboardingStyle.titleToTiles)

                VStack(spacing: OnboardingStyle.tileSpacing) {
                    tileLayout {
                        ForEach(page.tiles) { OnboardingTileView(tile: $0) }
                    }
                    if let tile = page.wideTile {
                        OnboardingTileView(tile: tile, isWide: true)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, OnboardingStyle.sideMargin)
            .padding(.top, OnboardingStyle.topMargin)
            .padding(.bottom, OnboardingStyle.bottomMargin)
        }
        // A page that needs less than the screen sits a little above the middle.
        .defaultScrollAnchor(UnitPoint(x: 0.5, y: OnboardingStyle.verticalAnchor), for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { bar }
    }

    /// Very large text gets one tile per row, each as tall as its own words, so no word is broken.
    private var tileLayout: AnyLayout {
        if typeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(spacing: OnboardingStyle.tileSpacing))
        } else {
            AnyLayout(EqualTiles(columns: page.columns, spacing: OnboardingStyle.tileSpacing))
        }
    }

    private var bar: some View {
        VStack(spacing: OnboardingStyle.buttonToLink) {
            Button(action: action) {
                Text(page.buttonTitle)
            }
            .buttonStyle(OnboardingButtonStyle())
            .disabled(isBusy)
            .accessibilityIdentifier("onboarding.\(page.id).button")

            if let link = page.link {
                Link(destination: link.url) {
                    Text(link.title)
                        .font(OnboardingStyle.linkFont)
                        .frame(maxWidth: .infinity, minHeight: OnboardingStyle.linkHeight)
                }
                .tint(OnboardingStyle.tint)
            }
        }
        .padding(.horizontal, OnboardingStyle.sideMargin)
        .padding(.bottom, OnboardingStyle.barBottomMargin)
        // Solid, so nothing shows through behind the link when the tiles scroll under it.
        .background(OnboardingStyle.background)
        .overlay(alignment: .top) { fade }
    }

    /// Tiles that scroll down to the button fade out just above it instead of being cut off.
    private var fade: some View {
        LinearGradient(
            colors: [OnboardingStyle.background.opacity(0), OnboardingStyle.background],
            startPoint: .top, endPoint: .bottom)
            .frame(height: OnboardingStyle.barFade)
            .offset(y: -OnboardingStyle.barFade)
            .allowsHitTesting(false)
    }
}

/// The big filled button. Its height is a minimum, so larger text makes it taller.
private struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: OnboardingStyle.buttonCornerRadius, style: .continuous)
        configuration.label
            .font(OnboardingStyle.buttonFont)
            .foregroundStyle(OnboardingStyle.onTint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, OnboardingStyle.buttonSidePadding)
            .padding(.vertical, OnboardingStyle.buttonVerticalPadding)
            .frame(maxWidth: .infinity, minHeight: OnboardingStyle.buttonHeight)
            .background(shape.fill(OnboardingStyle.tint))
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#Preview("Talk") {
    OnboardingPageView(page: .talk, isBusy: false) {}
        .background(OnboardingStyle.background)
}

#Preview("Consent, large text") {
    OnboardingPageView(page: .consent, isBusy: false) {}
        .background(OnboardingStyle.background)
        .dynamicTypeSize(.accessibility3)
}
