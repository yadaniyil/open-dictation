import SwiftUI

/// One speech provider in the Settings list: what it is, how fast and how exact it is next to
/// the others, whether it is set up, and whether it is the one dictations use.
struct ProviderRow: View {
    let model: SpeechModel
    let store: SpeechModelStore

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // At the largest text sizes the status moves under the name, so nothing gets cut off.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 8))
        HStack(spacing: 12) {
            ProviderLogo(model: model)
            VStack(alignment: .leading, spacing: 4) {
                layout {
                    VStack(alignment: .leading, spacing: 2) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) { name; inUse }
                            VStack(alignment: .leading, spacing: 4) { name; inUse }
                        }
                        Text(model.kind)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ProviderStatusBadge(model: model, status: store.status(of: model))
                }
                // Under both, so the status at the end does not squeeze it onto two lines.
                ProviderHintsLine(hints: model.hints)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("provider.\(model.rawValue)")
    }

    private var name: some View {
        Text(model.name)
    }

    @ViewBuilder private var inUse: some View {
        if store.selected == model {
            Text("In use")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(.tint.opacity(0.15), in: Capsule())
                .fixedSize()
        }
    }
}

/// The trailing end of a provider row: a green check, what is left to do, a download ring,
/// a spinner while the model is prepared, or a warning.
struct ProviderStatusBadge: View {
    let model: SpeechModel
    let status: SpeechModelStore.Status

    var body: some View {
        Group {
            switch status {
            case .ready:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.large)
            case .notSetUp:
                Text(model.isOnDevice ? "Download" : "Set up")
                    .foregroundStyle(.secondary)
            case .downloading(let progress):
                HStack(spacing: 6) {
                    ProgressRing(progress: progress)
                    Text(SpeechModel.percent(progress))
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            case .preparing:
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(model.statusText(status))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .imageScale(.large)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(label)
    }

    private var label: String {
        switch status {
        case .notSetUp: model.isOnDevice ? "Not downloaded" : "Not set up"
        case .failed(let message): "Problem: \(message)"
        case .ready, .downloading, .preparing: model.statusText(status)
        }
    }
}

/// A small ring that fills as a download goes on.
struct ProgressRing: View {
    let progress: Double

    @ScaledMetric(relativeTo: .subheadline) private var side: CGFloat = 18

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 3)
            Circle()
                .trim(from: 0, to: min(max(progress, 0.02), 1))
                .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: side, height: side)
        .animation(.default, value: progress)
        .accessibilityHidden(true)
    }
}
