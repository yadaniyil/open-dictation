import SwiftUI

/// The small coloured square with a symbol in it, as in the iPhone's own Settings.
struct SettingsTile: View {
    let symbol: String
    let tint: Color
    var side: CGFloat = 29

    /// Grows with the text size, but not so far that it crowds the words out.
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        let side = side * min(scale, 1.4)
        Image(systemName: symbol)
            .font(.system(size: side * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: side * 0.23, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// A Settings row: tile, title and an optional second line.
struct SettingsRowLabel: View {
    let title: String
    var subtitle: String?
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            SettingsTile(symbol: symbol, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
