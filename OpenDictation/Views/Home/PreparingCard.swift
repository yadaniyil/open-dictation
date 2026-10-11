import SwiftUI

/// Shown while the model in use is loaded for the first time since an update, which takes from
/// half a minute to a few minutes. Dictation works meanwhile, it only has to wait. There is
/// nothing to tap: the card goes away by itself when the model is ready.
struct PreparingCard: View {
    var body: some View {
        HStack(spacing: HomeStyle.rowSpacing) {
            ProgressView()
                .frame(width: HomeStyle.roundButtonSize, height: HomeStyle.roundButtonSize)
                .background(HomeStyle.softTint, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Preparing the speech model")
                    .font(HomeStyle.rowFont)
                    .foregroundStyle(HomeStyle.text)
                Text(SpeechModel.preparingNote)
                    .font(HomeStyle.detailFont)
                    .foregroundStyle(HomeStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, HomeStyle.rowPadding)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: HomeStyle.rowHeight, alignment: .leading)
        .background(HomeStyle.card, in: RoundedRectangle(cornerRadius: HomeStyle.rowCornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.preparing")
    }
}

#Preview {
    PreparingCard()
        .padding()
        .frame(maxHeight: .infinity)
        .background(HomeStyle.background)
}
