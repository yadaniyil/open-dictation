import SwiftUI

/// How to get a cloud provider's key, as a numbered list. A step with a web page has a link
/// under its words that opens the page in the browser.
struct ProviderKeySteps: View {
    let model: SpeechModel

    /// The circle grows with the text size, so a large number still fits inside it.
    @ScaledMetric(relativeTo: .footnote) private var badgeSide: CGFloat = 24

    var body: some View {
        Section("Get a key") {
            ForEach(Array(model.keySteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.footnote.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.tint)
                        .frame(width: badgeSide, height: badgeSide)
                        .background(.tint.opacity(0.15), in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(step.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Step \(index + 1). \(step.text)")
                        if let link = step.link {
                            Link(destination: link.url) {
                                HStack(spacing: 4) {
                                    // One line: a web address broken in two gets a hyphen it does not have.
                                    Text(link.title)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    Image(systemName: "arrow.up.right")
                                        .imageScale(.small)
                                        .accessibilityHidden(true)
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                            .accessibilityIdentifier("keyStepLink\(index + 1)")
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

#Preview {
    List { ProviderKeySteps(model: .openAI) }
}
