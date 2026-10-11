import SwiftUI

/// One short fact about a provider in the Settings list, such as "Super fast".
struct ProviderHint: Equatable, Sendable {
    /// Where the provider stands among the four. It decides the colour of the small picture.
    enum Level: Sendable {
        case best
        case good
        case weak
    }

    let symbol: String
    let text: String
    let level: Level
}

extension SpeechModel {
    /// How fast and how exact a provider is next to the other three: speed first, then accuracy.
    ///
    /// These are for reference and are not measured on the user's phone. They come from one test
    /// with the same 8 recordings in English, Ukrainian and Polish (October 2026): Parakeet took
    /// 0.3 s a recording and got 16% of the words wrong, Whisper 3.1 s and 9%, OpenAI 1.2 s and
    /// 7.5%, ElevenLabs 0.9 s and 2%. Run that test again before changing a word here.
    var hints: [ProviderHint] {
        switch self {
        case .openAI:
            [.speed("bolt.fill", "Fast", .good), .accuracy("Great accuracy", .good)]
        case .elevenLabs:
            [.speed("bolt.fill", "Fast", .good), .accuracy("Best accuracy", .best)]
        case .parakeetV3:
            [.speed("hare.fill", "Super fast", .best), .accuracy("Average accuracy", .weak)]
        case .whisperLargeTurbo:
            [.speed("tortoise.fill", "Slow", .weak), .accuracy("Great accuracy", .good)]
        }
    }
}

extension ProviderHint {
    fileprivate static func speed(_ symbol: String, _ text: String, _ level: Level) -> ProviderHint {
        ProviderHint(symbol: symbol, text: text, level: level)
    }

    fileprivate static func accuracy(_ text: String, _ level: Level) -> ProviderHint {
        ProviderHint(symbol: "scope", text: text, level: level)
    }
}

/// A provider's hints on one line, or under each other when the row is too narrow for that.
struct ProviderHintsLine: View {
    let hints: [ProviderHint]

    @ScaledMetric(relativeTo: .caption) private var iconWidth: CGFloat = 18

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { items }
            VStack(alignment: .leading, spacing: 2) { items }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var items: some View {
        ForEach(hints, id: \.text) { hint in
            HStack(spacing: 3) {
                Image(systemName: hint.symbol)
                    .imageScale(.small)
                    .foregroundStyle(hint.level.color)
                    // One width for every picture, so the words line up from row to row.
                    .frame(width: iconWidth)
                    .accessibilityHidden(true)
                Text(hint.text)
                    .fixedSize()
            }
        }
    }
}

extension ProviderHint.Level {
    fileprivate var color: Color {
        switch self {
        case .best: .green
        case .good: .secondary
        case .weak: .orange
        }
    }
}

#Preview {
    List(SpeechModel.allCases) { model in
        ProviderHintsLine(hints: model.hints)
    }
}
