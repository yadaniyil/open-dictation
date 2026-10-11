import SwiftUI

/// What the main screen shows once the shortcut is set up: how a dictation goes, in a few words,
/// and the way back to the steps.
struct ReadyCard: View {
    let guide: Tutorial
    let showSteps: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let words = guide.result {
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
                .frame(maxWidth: .infinity, minHeight: HomeStyle.resultHeight, alignment: .leading)
                .background(HomeStyle.card, in: RoundedRectangle(cornerRadius: HomeStyle.resultCornerRadius, style: .continuous))
            }
            Button(action: showSteps) {
                Text("Show the steps again")
                    .font(HomeStyle.captionFont)
                    .foregroundStyle(HomeStyle.tint)
                    .padding(.horizontal, 4)
                    .frame(minHeight: HomeStyle.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressedDimStyle())
            .accessibilityIdentifier("home.showSteps")
        }
    }
}

#Preview {
    ReadyCard(guide: .actionButton) {}
        .padding()
        .frame(maxHeight: .infinity)
        .background(HomeStyle.background)
}
