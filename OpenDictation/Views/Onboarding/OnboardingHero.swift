import SwiftUI

/// The drawing on the first page: an iPhone from the front while the app listens. Its Dynamic
/// Island is stretched and shows the microphone, the sound and the time, and the Action Button
/// on its left edge is in the accent colour. It is a picture, so its sizes are fixed and
/// VoiceOver reads one sentence for it.
struct OnboardingHero: View {
    let description: LocalizedStringResource

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Every size below is the design's, times this: a little smaller, so the phone and its
    /// side buttons also fit the narrowest iPhone.
    private let scale: CGFloat = 0.92
    /// How much of the page's height the title, the tiles and the margins need at the usual
    /// text size. The phone gets what is left, and its lower part runs off the picture.
    private let restOfPage: CGFloat = 262
    private let heights: ClosedRange<CGFloat> = 200...440
    /// Heights of the little sound bars in the island.
    private let soundBars: [CGFloat] = [8, 20, 12, 26, 14, 22, 10, 18]
    /// The message bubbles on the screen: how wide each is, and whether it is the user's own.
    private let bubbles: [(width: CGFloat, isOwn: Bool)] = [(0.62, false), (0.78, false), (0.54, true), (0.7, false)]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 18 * scale) {
                sideButton(height: 34, color: OnboardingStyle.tint)
                sideButton(height: 54, color: Self.button)
                sideButton(height: 54, color: Self.button)
            }
            .padding(.top, 96 * scale)
            phone
            sideButton(height: 86, color: Self.button)
                .scaleEffect(x: -1)
                .padding(.top, 168 * scale)
        }
        .containerRelativeFrame(.vertical, alignment: .top) { height, _ in
            // Very large text needs the room more than the picture does.
            if typeSize.isAccessibilitySize { return heights.lowerBound }
            return min(max(height - restOfPage, heights.lowerBound), heights.upperBound)
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(description))
        .accessibilityAddTraits(.isImage)
    }

    private var phone: some View {
        let body = RoundedRectangle(cornerRadius: 58 * scale, style: .continuous)
        return VStack(spacing: 46 * scale) {
            island
            VStack(alignment: .leading, spacing: 14 * scale) {
                ForEach(bubbles.indices, id: \.self) { index in
                    Capsule()
                        .fill(bubbles[index].isOwn ? OnboardingStyle.tint.opacity(0.16) : Color.primary.opacity(0.08))
                        .frame(width: 220 * scale * bubbles[index].width, height: 34 * scale)
                        .frame(maxWidth: .infinity, alignment: bubbles[index].isOwn ? .trailing : .leading)
                }
            }
            .frame(width: 220 * scale)
        }
        .padding(.top, 15 * scale)
        .frame(width: 264 * scale, height: 538 * scale, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 47 * scale, style: .continuous).fill(OnboardingStyle.tile))
        .padding(11 * scale)
        .background(body.fill(Self.frame))
        // The phone is black in both modes, so in dark mode only this line shows where it ends.
        .overlay(body.strokeBorder(.white.opacity(0.16)))
    }

    private var island: some View {
        HStack(spacing: 12 * scale) {
            Image(systemName: "mic.fill")
                .font(.system(size: 19 * scale, weight: .semibold))
            HStack(spacing: 4 * scale) {
                ForEach(soundBars.indices, id: \.self) { index in
                    Capsule().frame(width: 4 * scale, height: soundBars[index] * scale)
                }
            }
            Spacer(minLength: 0)
            Text(verbatim: "0:07")
                .font(.system(size: 17 * scale, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
        }
        .foregroundStyle(.red)
        .padding(.horizontal, 18 * scale)
        .frame(width: 220 * scale, height: 50 * scale)
        .background(Capsule().fill(.black))
        .overlay(Capsule().strokeBorder(.white.opacity(0.16)))
    }

    /// A button on the phone's left edge: round on the outside, flat where it meets the phone.
    private func sideButton(height: CGFloat, color: Color) -> some View {
        UnevenRoundedRectangle(topLeadingRadius: 4 * scale, bottomLeadingRadius: 4 * scale)
            .fill(color)
            .frame(width: 7 * scale, height: height * scale)
    }

    private static let frame = Color(red: 0.043, green: 0.043, blue: 0.059)
    /// The buttons that are not the Action Button: dark, and a lighter grey in dark mode so
    /// they still show against the page.
    private static let button = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.36, alpha: 1)
            : UIColor(red: 0.227, green: 0.227, blue: 0.259, alpha: 1)
    })
}

#Preview {
    ScrollView {
        OnboardingHero(description: "Preview")
            .padding(.top, 40)
            .frame(maxWidth: .infinity)
    }
    .background(OnboardingStyle.background)
}
