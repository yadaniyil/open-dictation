import SwiftUI

/// The user's own numbers: how much was dictated, the time it saved and what it cost.
/// All of it is worked out on the phone from `DictationLog`. Nothing is sent anywhere.
struct YourStatsView: View {
    var log: DictationLog = .shared

    /// Nil until the log has been read, which takes a moment at most.
    @State private var stats: DictationStats?
    @State private var confirmsClear = false

    var body: some View {
        ZStack {
            if let stats, !stats.isEmpty {
                List {
                    headline(stats.total)
                    numbers(stats)
                    cost(stats)
                    clearSection
                }
            } else {
                ContentUnavailableView {
                    Label("Nothing to count yet", systemImage: "chart.bar")
                } description: {
                    Text("Your numbers show up here after your first dictation. They are counted and kept on this iPhone, and nothing is sent anywhere.")
                }
                // Not shown before the log has been read: it may well hold something.
                .opacity(stats == nil ? 0 : 1)
                // A list with no rows is white, unlike every other Settings screen.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Your stats")
        .navigationBarTitleDisplayMode(.inline)
        // Read again when a dictation ends while this screen is showing.
        .task(id: DictationController.shared.phase) { stats = await log.stats() }
    }

    /// The promise the app makes about these numbers, said once at the top.
    static let privacyLine = "Counted and kept on this iPhone. Nothing is sent anywhere."

    private func headline(_ total: DictationTotals) -> some View {
        Section {
            VStack(spacing: 4) {
                Text(StatsFormat.count(total.words))
                    .font(.largeTitle.weight(.heavy))
                Text(total.words == 1 ? "word dictated" : "words dictated")
                    .font(.headline)
                Text(Self.privacyLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("statsHeadline")
        }
    }

    private func numbers(_ stats: DictationStats) -> some View {
        Section {
            LabeledContent("Last 7 days", value: StatsFormat.words(stats.lastSevenDays.words))
            LabeledContent("Dictations", value: StatsFormat.count(stats.total.dictations))
            LabeledContent("Time spoken", value: StatsFormat.duration(stats.total.audioSeconds))
            LabeledContent("Time saved", value: StatsFormat.duration(stats.total.secondsSaved))
        } footer: {
            Text("Time saved is measured against typing the same words at \(Int(DictationTotals.typingWordsPerMinute)) words a minute, a usual speed on a phone.")
        }
    }

    private func cost(_ stats: DictationStats) -> some View {
        Section {
            CostRow(title: "This month", cost: Pricing.cost(of: stats.thisMonth))
            CostRow(title: "All time", cost: Pricing.cost(of: stats.allTime))
        } header: {
            Text("Estimated cost")
        } footer: {
            Text("ElevenLabs tells the app what each dictation cost. OpenAI tells it the seconds it billed, counted at \(StatsFormat.dollars(Pricing.openAISpeechPerMinute)) a minute (its price in \(Pricing.checked)), plus a little for styles and spoken instructions. On-device models are free. Your real bill can still differ.")
        }
    }

    /// The question hangs off the button itself, which is where iOS points the bubble.
    private var clearSection: some View {
        Section {
            Button("Clear stats", role: .destructive) { confirmsClear = true }
                .accessibilityIdentifier("clearStats")
                .confirmationDialog("Clear your stats?", isPresented: $confirmsClear, titleVisibility: .visible) {
                    Button("Clear stats", role: .destructive) {
                        Task {
                            await log.clear()
                            stats = await log.stats()
                        }
                    }
                } message: {
                    Text("Every number here starts again from zero. Your recent texts stay.")
                }
        }
    }
}

/// An estimate, with who sends the bill underneath when more than one provider does.
private struct CostRow: View {
    let title: String
    let cost: Pricing.Cost

    var body: some View {
        LabeledContent {
            Text(StatsFormat.estimate(cost.total))
        } label: {
            Text(title)
            if let split = StatsFormat.split(cost) {
                Text(split)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { YourStatsView(log: .samples()) }
}
#endif
