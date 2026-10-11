import SwiftUI

/// The one layout every set-up guide uses: the title, the steps, then what a dictation is like
/// once it is done, and the button that goes back. The steps scroll, so the largest text still fits.
struct TutorialView: View {
    let tutorial: Tutorial

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { page in
            ScrollView {
                VStack(spacing: HomeStyle.tileSpacing) {
                    ForEach(tutorial.steps.indices, id: \.self) { index in
                        TutorialStepTile(number: index + 1, step: tutorial.steps[index])
                    }
                    // A short guide leaves room: the result then sits at the bottom, over the button.
                    Spacer(minLength: 0)
                    result
                }
                .padding(.horizontal, HomeStyle.sideMargin)
                .padding(.top, HomeStyle.topMargin)
                .padding(.bottom, HomeStyle.resultToButton)
                .frame(minHeight: page.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(HomeStyle.background)
        .navigationTitle(Text(tutorial.title))
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom, spacing: 0) { bar }
    }

    private var bar: some View {
        Button {
            dismiss()
        } label: {
            Text("Done")
        }
        .buttonStyle(DoneButtonStyle())
        .accessibilityIdentifier("tutorial.done")
        .padding(.horizontal, HomeStyle.sideMargin)
        .padding(.bottom, HomeStyle.barBottomMargin)
        // Solid, so the steps do not show through behind the button when they scroll under it.
        .background(HomeStyle.background)
        .overlay(alignment: .top) { fade }
    }

    /// What using it is like once it is set up: the reason for the steps above.
    @ViewBuilder private var result: some View {
        if let words = tutorial.result {
            HStack(spacing: 10) {
                Image(systemName: "mic")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(HomeStyle.tint)
                    .accessibilityHidden(true)
                Text(words)
                    .font(HomeStyle.rowFont)
                    .foregroundStyle(HomeStyle.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, HomeStyle.rowPadding)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: HomeStyle.resultHeight)
            .background(HomeStyle.card, in: RoundedRectangle(cornerRadius: HomeStyle.resultCornerRadius, style: .continuous))
        }
    }

    /// Steps that scroll down to the button fade out just above it instead of being cut off.
    private var fade: some View {
        LinearGradient(
            colors: [HomeStyle.background.opacity(0), HomeStyle.background],
            startPoint: .top, endPoint: .bottom)
            .frame(height: HomeStyle.barFade)
            .offset(y: -HomeStyle.barFade)
            .allowsHitTesting(false)
    }
}

/// The big filled button. Its height is a minimum, so larger text makes it taller.
private struct DoneButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: HomeStyle.buttonCornerRadius, style: .continuous)
        configuration.label
            .font(HomeStyle.buttonFont)
            .foregroundStyle(HomeStyle.onTint)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: HomeStyle.buttonHeight)
            .background(shape.fill(HomeStyle.tint))
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#Preview("Action Button") {
    NavigationStack { TutorialView(tutorial: .actionButton) }
}

#Preview("By hand, large text") {
    NavigationStack { TutorialView(tutorial: .makeShortcut) }
        .dynamicTypeSize(.accessibility3)
}
