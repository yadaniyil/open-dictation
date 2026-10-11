import SwiftUI

/// One tile: a picture over its words, or beside them when the tile is as wide as the page.
/// Nothing is cut short: a tile grows as tall as its words need.
struct OnboardingTileView: View {
    let tile: OnboardingTile
    /// True for a tile that has the whole row to itself.
    var isWide = false

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if let url = tile.url {
            Link(destination: url) { content }
                .accessibilityHint("Opens in your browser")
        } else {
            content
                .accessibilityElement(children: .combine)
        }
    }

    private var content: some View {
        layout {
            OnboardingPicture(picture: tile.picture, backdrop: fill)
                .foregroundStyle(pictureColor)
                // The pictures grow with the text, but only so far: the words need the room more.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            VStack(alignment: readsFromTheEdge ? .leading : .center, spacing: OnboardingStyle.labelToCaption) {
                Text(tile.label)
                    .font(OnboardingStyle.labelFont)
                if let caption = tile.caption {
                    Text(caption)
                        .font(OnboardingStyle.captionFont)
                }
            }
            .foregroundStyle(isFilled ? OnboardingStyle.onTint : OnboardingStyle.text)
            .multilineTextAlignment(readsFromTheEdge ? .leading : .center)
            // Lets the words take every line they need instead of ending in "…".
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .padding(.horizontal, OnboardingStyle.tileSidePadding)
        .padding(.vertical, OnboardingStyle.tileVerticalPadding)
        .background(shape.fill(fill))
        .overlay(alignment: .topTrailing) {
            if isFilled {
                // The small arrow says the tile opens something outside the app.
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(OnboardingStyle.onTint.opacity(0.8))
                    .padding(OnboardingStyle.tileSidePadding)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(shape)
    }

    /// Picture beside the words in a wide tile, over them everywhere else.
    private var layout: AnyLayout {
        if isWide, !typeSize.isAccessibilitySize {
            AnyLayout(HStackLayout(spacing: OnboardingStyle.pictureToLabel))
        } else {
            AnyLayout(VStackLayout(
                alignment: readsFromTheEdge ? .leading : .center, spacing: OnboardingStyle.pictureToLabel))
        }
    }

    /// Tiles in a row can differ in how many lines they need. Starting every tile from the top
    /// keeps their pictures and labels on the same lines.
    private var alignment: Alignment {
        if readsFromTheEdge { return .topLeading }
        return isWide ? .center : .top
    }

    /// Very large text is easier to follow when every line starts at the same edge.
    private var readsFromTheEdge: Bool { typeSize.isAccessibilitySize }

    private var isFilled: Bool { tile.url != nil }

    private var fill: Color { isFilled ? OnboardingStyle.tint : OnboardingStyle.tile }

    private var pictureColor: Color {
        if isFilled { return OnboardingStyle.onTint }
        return tile.look == .good ? OnboardingStyle.good : OnboardingStyle.tint
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: OnboardingStyle.tileCornerRadius, style: .continuous)
    }
}

/// Draws a tile's picture inside a square. Decoration only: the label says what it means.
private struct OnboardingPicture: View {
    let picture: OnboardingTile.Picture
    /// The colour behind the picture, used for the gap around the crossing line.
    let backdrop: Color

    @ScaledMetric(relativeTo: .title) private var side = OnboardingStyle.pictureSize

    var body: some View {
        ZStack { drawing }
            .font(.system(size: side * 0.76, weight: .semibold))
            .frame(width: side, height: side)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var drawing: some View {
        switch picture {
        case .symbol(let name):
            Image(systemName: name)
        case .crossedOut(let name):
            Image(systemName: name)
            crossingLine
        case .phoneWithButton:
            Image(systemName: "iphone")
                .overlay(alignment: .topLeading) {
                    // The Action Button, high on the left side of the phone.
                    Capsule()
                        .frame(width: side * 0.07, height: side * 0.2)
                        .offset(x: -side * 0.05, y: side * 0.17)
                }
        case .phoneWithWaveform:
            Image(systemName: "iphone")
            Image(systemName: "waveform")
                .font(.system(size: side * 0.24, weight: .bold))
        case .clipboardWithCheck:
            Image(systemName: "clipboard")
            Image(systemName: "checkmark")
                .font(.system(size: side * 0.3, weight: .heavy))
                // The board's middle is a little below the symbol's middle, because of the clip on top.
                .offset(y: side * 0.07)
        }
    }

    /// Drawn the way SF Symbols draws a slash: top left to bottom right, with a thin gap around it.
    private var crossingLine: some View {
        Capsule()
            .frame(width: side * 0.085, height: side * 1.12)
            .background(Capsule().fill(backdrop).padding(-side * 0.055))
            .rotationEffect(.degrees(-45))
    }
}
