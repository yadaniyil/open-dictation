import SwiftUI

/// The first thing a new user needs: something that listens. On Wi-Fi the on-device model
/// downloads by itself (`FirstModelDownload`) and this card shows how far it is. Otherwise one
/// tap starts it. People who bring a key go to Settings instead. The card is gone as soon as a
/// provider is ready.
struct SpeechModelCard: View {
    let store: SpeechModelStore
    let useOwnKey: () -> Void

    static let model = FirstModelDownload.model

    var body: some View {
        VStack(alignment: .leading, spacing: HomeStyle.rowSpacing) {
            HStack(spacing: HomeStyle.rowSpacing) {
                Image(systemName: "iphone")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HomeStyle.tint)
                    .frame(width: HomeStyle.roundButtonSize, height: HomeStyle.roundButtonSize)
                    .background(HomeStyle.softTint, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Speech model")
                        .font(HomeStyle.rowFont)
                        .foregroundStyle(HomeStyle.text)
                    Text(detail)
                        .font(HomeStyle.detailFont)
                        .monospacedDigit()
                        .foregroundStyle(HomeStyle.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                action
            }
            if case .downloading(let progress) = status {
                ProgressView(value: progress)
            } else {
                Button(action: useOwnKey) {
                    Text("Use my own key instead")
                        .font(HomeStyle.captionFont)
                        .foregroundStyle(HomeStyle.tint)
                        .frame(minHeight: HomeStyle.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressedDimStyle())
                .accessibilityIdentifier("home.useOwnKey")
            }
        }
        .padding(HomeStyle.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeStyle.card, in: RoundedRectangle(cornerRadius: HomeStyle.rowCornerRadius, style: .continuous))
    }

    private var status: SpeechModelStore.Status { store.status(of: Self.model) }

    private var size: String { Self.model.sizeLabel ?? "" }

    private var detail: String {
        switch status {
        case .notSetUp, .ready, .preparing: "On this iPhone, \(size)"
        case .downloading(let progress): "\(SpeechModel.percent(progress)) of \(size)"
        case .failed(let why): why
        }
    }

    @ViewBuilder private var action: some View {
        switch status {
        case .notSetUp:
            Button("Download") { store.download(Self.model) }
                .buttonStyle(PillButtonStyle())
                .accessibilityIdentifier("home.downloadModel")
        case .failed:
            Button("Try again") { store.download(Self.model) }
                .buttonStyle(PillButtonStyle())
        case .downloading:
            Button("Cancel") { store.cancelDownload(Self.model) }
                .font(HomeStyle.rowFont)
                .frame(minHeight: HomeStyle.touchTarget)
        case .ready, .preparing:
            EmptyView()
        }
    }
}

#Preview {
    SpeechModelCard(store: .shared) {}
        .padding()
        .frame(maxHeight: .infinity)
        .background(HomeStyle.background)
}
