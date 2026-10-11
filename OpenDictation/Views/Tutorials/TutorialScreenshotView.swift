import SwiftUI

/// A real iOS screen, cropped to the part a step is about, with a frame around what to tap.
struct TutorialScreenshotView: View {
    let screenshot: TutorialScreenshot
    /// What VoiceOver says for it.
    let description: LocalizedStringResource

    var body: some View {
        Image(screenshot.asset)
            .resizable()
            .aspectRatio(screenshot.aspect, contentMode: .fit)
            .overlay {
                GeometryReader { area in
                    let width = screenshot.target.width * area.size.width
                    let height = screenshot.target.height * area.size.height
                    RoundedRectangle(cornerRadius: height * screenshot.targetRoundness, style: .continuous)
                        .strokeBorder(HomeStyle.tint, lineWidth: HomeStyle.screenshotFrameWidth)
                        .frame(width: width, height: height)
                        .offset(
                            x: screenshot.target.minX * area.size.width,
                            y: screenshot.target.minY * area.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: HomeStyle.screenshotCornerRadius, style: .continuous))
            .accessibilityElement()
            .accessibilityLabel(Text(description))
            .accessibilityAddTraits(.isImage)
    }
}

#Preview {
    VStack(spacing: 12) {
        TutorialScreenshotView(screenshot: .settingsActionButtonRow, description: "Settings")
        TutorialScreenshotView(screenshot: .actionButtonShortcutChoice, description: "Action Button")
    }
    .padding()
    .background(HomeStyle.card)
}
