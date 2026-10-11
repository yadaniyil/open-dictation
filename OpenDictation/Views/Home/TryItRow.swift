import AVFoundation
import SwiftUI

/// A place to dictate inside the app: tap to start, tap again to stop. It shows which provider
/// listens, and what came of the last try. The text lands in the Recent list below.
struct TryItRow: View {
    let controller: DictationController
    let speechModels: SpeechModelStore
    /// Opens Settings on the provider that still waits for its key.
    let setUp: (SpeechModel) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: tapped) {
                layout {
                    HStack(spacing: HomeStyle.rowSpacing) {
                        roundButton
                        title
                            .font(HomeStyle.rowFont)
                            .foregroundStyle(HomeStyle.text)
                            // The title gives way before the provider's name breaks in two.
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    provider
                }
                .padding(.horizontal, HomeStyle.rowPadding)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: HomeStyle.rowHeight, alignment: .leading)
                .background(HomeStyle.card, in: shape)
                .contentShape(shape)
            }
            .buttonStyle(PressedDimStyle())
            .disabled(controller.phase == .transcribing)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(speechModels.selected.name)
            .accessibilityIdentifier("recordButton")

            status
                .font(HomeStyle.captionFont)
                .foregroundStyle(HomeStyle.secondaryText)
                .padding(.horizontal, 4)
                .accessibilityIdentifier("statusText")
        }
    }

    // MARK: - Parts

    private var roundButton: some View {
        ZStack {
            Circle().fill(isRecording ? HomeStyle.recording : HomeStyle.softTint)
            if controller.phase == .transcribing {
                ProgressView()
            } else {
                Image(systemName: isRecording ? "stop.fill" : "mic")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isRecording ? HomeStyle.onTint : HomeStyle.tint)
            }
        }
        .frame(width: HomeStyle.roundButtonSize, height: HomeStyle.roundButtonSize)
    }

    @ViewBuilder private var title: some View {
        switch controller.phase {
        case .idle:
            Text("Try it here")
        case .recording(let startedAt):
            HStack(spacing: 6) {
                Text("Listening")
                Text(startedAt, style: .timer).monospacedDigit()
            }
        case .transcribing:
            Text("Working…")
        }
    }

    /// The provider in use with its green check, or the way to set it up while it waits for a key.
    @ViewBuilder private var provider: some View {
        HStack(spacing: 5) {
            if missingKey == nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HomeStyle.good)
                Text(speechModels.selected.name)
                    .foregroundStyle(HomeStyle.secondaryText)
            } else {
                Text("Set up")
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.bold))
            }
        }
        .font(HomeStyle.detailFont)
        .foregroundStyle(HomeStyle.tint)
        .lineLimit(1)
        .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: false)
    }

    /// One line under the row: what is missing, or how the last dictation went.
    @ViewBuilder private var status: some View {
        if controller.phase == .idle {
            // A missing key comes first: the last result does not say why nothing starts.
            if let missingKey {
                Text("\(missingKey.name) needs your key. The on-device models need none.")
            } else {
                switch controller.lastMessage {
                case .copied(let note):
                    result(note ?? "Copied. Paste it anywhere.", symbol: "checkmark.circle.fill", color: HomeStyle.good)
                case .failed(let message):
                    result(message, symbol: "exclamationmark.triangle.fill", color: HomeStyle.warning)
                case nil:
                    EmptyView()
                }
            }
        }
    }

    private func result(_ text: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(text)
        }
    }

    // MARK: - State

    private var isRecording: Bool {
        if case .recording = controller.phase { true } else { false }
    }

    /// The provider in use, while it still waits for its key. An on-device one never does.
    private var missingKey: SpeechModel? {
        speechModels.canListen ? nil : speechModels.selected
    }

    private var accessibilityLabel: String {
        switch controller.phase {
        case .recording: "Stop and copy"
        case .transcribing: "Working"
        case .idle: missingKey.map { "Set up \($0.name) to try it here" } ?? "Try it here"
        }
    }

    /// Very large text puts the provider under the title, so neither is cut off.
    private var layout: AnyLayout {
        if typeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
        } else {
            AnyLayout(HStackLayout(spacing: HomeStyle.rowSpacing))
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeStyle.rowCornerRadius, style: .continuous)
    }

    private func tapped() {
        if let missingKey {
            setUp(missingKey)
            return
        }
        Task {
            if AVAudioApplication.shared.recordPermission == .undetermined {
                _ = await AVAudioApplication.requestRecordPermission()
            }
            // The controller keeps the error to show under the row.
            _ = try? await controller.toggle()
        }
    }
}

#Preview {
    TryItRow(controller: .shared, speechModels: .shared) { _ in }
        .padding()
        .frame(maxHeight: .infinity)
        .background(HomeStyle.background)
}
