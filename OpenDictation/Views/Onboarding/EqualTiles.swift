import SwiftUI

/// Puts tiles in equal columns and makes every tile as tall as the tallest one.
struct EqualTiles: Layout {
    let columns: Int
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let tile = tileSize(in: width, subviews: subviews)
        let rows = CGFloat((subviews.count + columns - 1) / columns)
        return CGSize(width: width, height: rows * tile.height + max(rows - 1, 0) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let tile = tileSize(in: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let column = CGFloat(index % columns)
            let row = CGFloat(index / columns)
            subview.place(
                at: CGPoint(
                    x: bounds.minX + column * (tile.width + spacing),
                    y: bounds.minY + row * (tile.height + spacing)),
                proposal: ProposedViewSize(tile))
        }
    }

    private func tileSize(in width: CGFloat, subviews: Subviews) -> CGSize {
        let tileWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let heights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: tileWidth, height: nil)).height }
        return CGSize(width: tileWidth, height: heights.max() ?? 0)
    }
}
