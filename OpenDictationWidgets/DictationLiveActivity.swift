import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct DictationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DictationActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PhaseIcon(phase: state.phase)
                        .font(.title2)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if state.phase == .recording {
                        ElapsedTime(since: state.startedAt)
                            .font(.title3.weight(.semibold))
                            .padding(.trailing, 6)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(state.phase.title)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottom(state: state)
                }
            } compactLeading: {
                PhaseIcon(phase: state.phase)
            } compactTrailing: {
                switch state.phase {
                case .recording: ElapsedTime(since: state.startedAt).frame(maxWidth: 42)
                case .transcribing: ProgressView().tint(.white)
                case .copied: Text("Copied").font(.caption2.weight(.semibold)).foregroundStyle(state.phase.tint)
                case .failed: Text("Failed").font(.caption2.weight(.semibold)).foregroundStyle(state.phase.tint)
                }
            } minimal: {
                PhaseIcon(phase: state.phase)
            }
            .keylineTint(state.phase.tint)
        }
    }
}

private struct ExpandedBottom: View {
    let state: DictationActivityAttributes.ContentState

    var body: some View {
        content
            // Keeps the words clear of the island's round bottom corners, which cut them off.
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
    }

    @ViewBuilder private var content: some View {
        switch state.phase {
        case .recording:
            HStack {
                // One short line: a second line would not fit beside the button.
                Text("Press the Action Button to stop.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Button(intent: ToggleDictationIntent()) {
                    Label("Done", systemImage: "stop.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(.red)
            }
        case .transcribing:
            Text("Turning your voice into text…")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .copied, .failed:
            if let detail = state.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct LockScreenView: View {
    let state: DictationActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            PhaseIcon(phase: state.phase)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.phase.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let detail = state.detail, state.phase != .recording {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if state.phase == .recording {
                ElapsedTime(since: state.startedAt)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 64)
                Button(intent: ToggleDictationIntent()) {
                    Image(systemName: "stop.fill")
                }
                .tint(.red)
            }
        }
        .padding(16)
    }
}

private struct PhaseIcon: View {
    let phase: DictationActivityAttributes.ContentState.Phase

    var body: some View {
        Image(systemName: phase.symbol)
            .foregroundStyle(phase.tint)
    }
}

private struct ElapsedTime: View {
    let since: Date

    var body: some View {
        Text(timerInterval: since...since.addingTimeInterval(60 * 60), countsDown: false)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

private extension DictationActivityAttributes.ContentState.Phase {
    var title: String {
        switch self {
        case .recording: "Listening"
        case .transcribing: "Working"
        case .copied: "Copied"
        case .failed: "Did not work"
        }
    }

    var symbol: String {
        switch self {
        case .recording: "mic.fill"
        case .transcribing: "waveform"
        case .copied: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .recording: .red
        case .transcribing: .white
        case .copied: .green
        case .failed: .yellow
        }
    }
}
