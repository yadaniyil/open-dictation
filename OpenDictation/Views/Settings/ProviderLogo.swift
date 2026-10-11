import SwiftUI

/// The logo of the company behind a speech provider, on a small rounded tile.
/// The shapes are the companies' own files, used unchanged; only the size and colour are set here.
struct ProviderLogo: View {
    let model: SpeechModel
    var side: CGFloat = 34

    /// Grows with the text size, but not so far that it crowds the words out.
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        let side = side * min(scale, 1.4)
        let mark = model.logo
        let shape = RoundedRectangle(cornerRadius: side * 0.265, style: .continuous)
        Image(mark.asset)
            .resizable()
            .scaledToFit()
            .frame(width: side * mark.size, height: side * mark.size)
            .foregroundStyle(mark.color)
            .frame(width: side, height: side)
            .background(mark.tile, in: shape)
            .overlay(shape.strokeBorder(mark.border, lineWidth: 1))
            .accessibilityElement()
            .accessibilityLabel(mark.label)
            .accessibilityAddTraits(.isImage)
    }
}

/// A company's logo and the tile it sits on. The colours are the same in light and dark mode,
/// because they belong to the logo.
struct ProviderMark {
    /// The image's name in the asset catalogue.
    let asset: String
    /// What VoiceOver says for it.
    let label: String
    let color: Color
    let tile: Color
    let border: Color
    /// How much of the tile's side the logo takes.
    let size: CGFloat

    private static let ink = Color(red: 0.043, green: 0.043, blue: 0.059)
    private static let edge = Color(red: 0.89, green: 0.89, blue: 0.91)
    /// A black tile has no edge of its own on a dark page.
    private static let edgeInDarkMode = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.2) : .clear
    })

    static let openAI = ProviderMark(
        asset: "OpenAILogo", label: "OpenAI logo",
        color: .white, tile: ink, border: edgeInDarkMode, size: 22.0 / 34)

    static let elevenLabs = ProviderMark(
        asset: "ElevenLabsLogo", label: "ElevenLabs logo",
        color: ink, tile: .white, border: edge, size: 16.0 / 34)

    static let nvidia = ProviderMark(
        asset: "NvidiaLogo", label: "NVIDIA logo",
        color: Color(red: 0.463, green: 0.725, blue: 0), tile: .white, border: edge, size: 24.0 / 34)
}

#Preview {
    HStack {
        ForEach(SpeechModel.allCases) { ProviderLogo(model: $0, side: 56) }
    }
    .padding()
}
