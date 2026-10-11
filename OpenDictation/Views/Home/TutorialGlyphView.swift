import SwiftUI

/// Draws the small picture of a place a dictation can be started from, inside a square.
/// Decoration only: the tile's label says what it means.
struct TutorialGlyphView: View {
    let glyph: TutorialGlyph

    @ScaledMetric(relativeTo: .subheadline) private var side = HomeStyle.glyphSize

    var body: some View {
        ZStack { drawing }
            .foregroundStyle(HomeStyle.tint)
            .frame(width: side, height: side)
            .accessibilityHidden(true)
    }

    /// The pictures SF Symbols does not have are put together on a grid of 24 by 24.
    private var unit: CGFloat { side / 24 }

    private var line: StrokeStyle {
        StrokeStyle(lineWidth: 1.9 * unit, lineCap: .round, lineJoin: .round)
    }

    @ViewBuilder private var drawing: some View {
        switch glyph {
        case .actionButton:
            Image(systemName: "button.programmable")
                .font(.system(size: side * 0.8, weight: .medium))
        case .lockScreen:
            Image(systemName: "lock")
                .font(.system(size: side * 0.8, weight: .medium))
        case .controlCenter:
            // Four controls, one of them switched on.
            Grid(horizontalSpacing: 3 * unit, verticalSpacing: 3 * unit) {
                GridRow {
                    control(isOn: false)
                    control(isOn: true)
                }
                GridRow {
                    control(isOn: false)
                    control(isOn: false)
                }
            }
        case .backTap:
            // The back of an iPhone: its camera at the top, and a tap in the middle.
            RoundedRectangle(cornerRadius: 2.6 * unit, style: .continuous)
                .stroke(style: line)
                .frame(width: 10 * unit, height: 19 * unit)
            Circle()
                .stroke(style: line)
                .frame(width: 2.2 * unit, height: 2.2 * unit)
                .offset(x: -1.6 * unit, y: -6 * unit)
            Circle()
                .stroke(style: line)
                .frame(width: 7.2 * unit, height: 7.2 * unit)
                .opacity(0.5)
                .offset(y: 1.5 * unit)
            Circle()
                .frame(width: 2.8 * unit, height: 2.8 * unit)
                .offset(y: 1.5 * unit)
        }
    }

    private func control(isOn: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2.2 * unit, style: .continuous)
            .stroke(style: line)
            .background(RoundedRectangle(cornerRadius: 2.2 * unit, style: .continuous).fill(isOn ? HomeStyle.tint : .clear))
            .frame(width: 7 * unit, height: 7 * unit)
    }
}

#Preview {
    HStack(spacing: 24) {
        TutorialGlyphView(glyph: .actionButton)
        TutorialGlyphView(glyph: .controlCenter)
        TutorialGlyphView(glyph: .lockScreen)
        TutorialGlyphView(glyph: .backTap)
    }
    .padding()
}
