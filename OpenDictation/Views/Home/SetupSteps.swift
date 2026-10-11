import SwiftUI

/// The main screen's guide: the steps of the one best way to start a dictation on this iPhone.
/// The other ways are in Settings, so this screen stays short.
struct SetupSteps: View {
    let guide: Tutorial
    /// The user says the steps are done.
    let done: () -> Void

    var body: some View {
        VStack(spacing: HomeStyle.tileSpacing) {
            ForEach(guide.steps.indices, id: \.self) { index in
                TutorialStepTile(number: index + 1, step: guide.steps[index])
            }
            Button(action: done) {
                Text("I've set it up")
                    .font(HomeStyle.rowFont)
                    .foregroundStyle(HomeStyle.tint)
                    .frame(maxWidth: .infinity, minHeight: HomeStyle.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressedDimStyle())
            .accessibilityIdentifier("home.setupDone")
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            SetupSteps(guide: .actionButton) {}
                .padding()
        }
        .background(HomeStyle.background)
    }
}
