import SwiftUI

/// One step of a guide. A step with a button or a real screen uses the short form; the others
/// have a drawing on the left and their number and few words on the right.
struct TutorialStepTile: View {
    let number: Int
    let step: TutorialStep

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if step.screenshot != nil || step.action != nil {
            compact
        } else {
            withDrawing
        }
    }

    /// The short form: the number, the words and a small button on one line, then a real screen
    /// where there is one. It needs the tile's whole width for the screen to be readable.
    private var compact: some View {
        VStack(alignment: .leading, spacing: HomeStyle.stepWordsToScreenshot) {
            headerLayout {
                HStack(alignment: .firstTextBaseline, spacing: HomeStyle.badgeToWords) {
                    StepBadge(number: number)
                    if let text = step.text {
                        Text(text)
                            .font(HomeStyle.stepFont)
                            .foregroundStyle(HomeStyle.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                actionButton
            }
            if let screenshot = step.screenshot {
                TutorialScreenshotView(screenshot: screenshot, description: step.pictureDescription)
            }
        }
        .padding(HomeStyle.stepPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeStyle.card, in: RoundedRectangle(cornerRadius: HomeStyle.stepCornerRadius, style: .continuous))
    }

    @ViewBuilder private var actionButton: some View {
        switch step.action {
        case .getShortcut:
            GetShortcutButton { Text("Get") }
                .buttonStyle(SmallPillButtonStyle())
                .accessibilityLabel("Get the shortcut")
                .accessibilityIdentifier("getShortcut")
        case .openSettings:
            OpenSettingsButton()
        case nil:
            EmptyView()
        }
    }

    /// Very large text puts the button under the words.
    private var headerLayout: AnyLayout {
        if typeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: .leading, spacing: HomeStyle.badgeToWords))
        } else {
            AnyLayout(HStackLayout(spacing: HomeStyle.rowSpacing))
        }
    }

    private var withDrawing: some View {
        layout {
            TutorialPictureView(picture: step.picture, description: step.pictureDescription)
            VStack(alignment: .leading, spacing: HomeStyle.badgeToWords) {
                StepBadge(number: number)
                if let text = step.text {
                    Text(text)
                        .font(HomeStyle.stepFont)
                        .foregroundStyle(HomeStyle.text)
                        // Lets the words take every line they need instead of ending in "…".
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // VoiceOver reads the number and the words in one go.
            .accessibilityElement(children: .combine)
        }
        .padding(HomeStyle.stepPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeStyle.card, in: RoundedRectangle(cornerRadius: HomeStyle.stepCornerRadius, style: .continuous))
    }

    private var layout: AnyLayout {
        if typeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: .leading, spacing: HomeStyle.stepPictureToWords))
        } else {
            AnyLayout(HStackLayout(spacing: HomeStyle.stepPictureToWords))
        }
    }
}

#Preview {
    VStack {
        TutorialStepTile(number: 1, step: .getShortcut)
        TutorialStepTile(number: 2, step: Tutorial.actionButton.steps[1])
    }
    .padding()
    .background(HomeStyle.background)
}
