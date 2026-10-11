import SwiftUI

/// Shown while a recording waits for another try, because it could not be turned into text.
struct UnsentRecordingCard: View {
    let controller: DictationController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                Button {
                    Task { await controller.retryUnsent() }
                } label: {
                    row("Try the last recording again", symbol: "arrow.clockwise", color: HomeStyle.tint)
                }
                .disabled(controller.phase != .idle)
                Divider()
                    .padding(.leading, HomeStyle.rowPadding)
                Button(role: .destructive) {
                    controller.discardUnsent()
                } label: {
                    row("Throw it away", symbol: "trash", color: .red)
                }
            }
            .buttonStyle(PressedDimStyle())
            .background(HomeStyle.card, in: RoundedRectangle(cornerRadius: HomeStyle.rowCornerRadius, style: .continuous))

            Text("The last recording was not turned into text. It is still saved on this phone.")
                .font(HomeStyle.captionFont)
                .foregroundStyle(HomeStyle.secondaryText)
                .padding(.horizontal, 4)
        }
    }

    private func row(_ title: LocalizedStringKey, symbol: String, color: Color) -> some View {
        HStack(spacing: HomeStyle.rowSpacing) {
            Image(systemName: symbol)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(HomeStyle.bodyFont)
        .foregroundStyle(color)
        .padding(.horizontal, HomeStyle.rowPadding)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    UnsentRecordingCard(controller: .shared)
        .padding()
        .frame(maxHeight: .infinity)
        .background(HomeStyle.background)
}
