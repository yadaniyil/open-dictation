import SwiftUI

// The pictures that hint at the Shortcuts app: a shortcut, the list to pick one from, and the
// actions a shortcut is made of.

/// A shortcut, as the square tile the Shortcuts app shows for one.
struct ShortcutTilePicture: View {
    /// A small + on the corner, for "make a new one".
    var hasPlus = false

    var body: some View {
        Image(systemName: PictureStyle.shortcutSymbol)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(HomeStyle.onTint)
            .frame(width: 60, height: 60)
            .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(HomeStyle.tint))
            .overlay(alignment: .bottomTrailing) {
                if hasPlus {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(HomeStyle.tint)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(PictureStyle.paper))
                        // A ring in the square's colour lifts the badge off the tile's corner.
                        .background(Circle().fill(PictureStyle.well).padding(-3))
                        .offset(x: 9, y: 9)
                }
            }
    }
}

/// The list a shortcut is picked from: the user's own shortcuts as tiles at the top, with the
/// one to pick in the accent colour, and apps as plain rows under them.
struct MyShortcutsPicture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Capsule()
                .fill(PictureStyle.mark)
                .frame(width: 34, height: 5)
            HStack(spacing: 6) {
                tile(isPicked: true)
                tile(isPicked: false)
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach([30, 22] as [CGFloat], id: \.self) { width in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .frame(width: 10, height: 10)
                        Capsule().frame(width: width, height: 4)
                    }
                }
            }
            .foregroundStyle(PictureStyle.line)
        }
    }

    private func tile(isPicked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .frame(width: 8, height: 8)
            Capsule().frame(width: 22, height: 4)
        }
        .foregroundStyle(isPicked ? HomeStyle.onTint : PictureStyle.mark)
        .padding(6)
        .frame(width: 38, height: 32, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isPicked ? HomeStyle.tint : PictureStyle.paper))
    }
}

/// A shortcut being built: its actions as blocks, top to bottom.
struct ActionsPicture: View {
    struct Action {
        /// The action's icon, or nil for the plain block that closes an If.
        let symbol: String?
        /// The action this step adds.
        var isHighlighted = false
        /// Moved in a little, the way the Shortcuts app shows what happens inside an If.
        var isInside = false
    }

    let actions: [Action]

    private let width: CGFloat = 80
    private let indent: CGFloat = 12

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ForEach(actions.indices, id: \.self) { index in
                block(actions[index])
            }
        }
        .frame(width: width)
    }

    private func block(_ action: Action) -> some View {
        HStack(spacing: 6) {
            if let symbol = action.symbol {
                Image(systemName: symbol)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(action.isHighlighted ? HomeStyle.onTint : PictureStyle.paper)
                    .frame(width: 15, height: 15)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(action.isHighlighted ? HomeStyle.tint : PictureStyle.mark))
            }
            Capsule()
                .fill(action.isHighlighted ? HomeStyle.tint : PictureStyle.line)
                .frame(width: action.symbol == nil ? 20 : 30, height: 5)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .frame(width: action.isInside ? width - indent : width, height: 25)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(PictureStyle.paper))
        .overlay {
            if action.isHighlighted {
                RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(HomeStyle.tint, lineWidth: 1.5)
            }
        }
    }
}

/// The shortcut's name at the top of the editor, with the cursor in it.
struct RenamePicture: View {
    var body: some View {
        HStack(spacing: 3) {
            Capsule()
                .fill(HomeStyle.tint)
                .frame(width: 44, height: 5)
            Capsule()
                .fill(HomeStyle.tint)
                .frame(width: 2, height: 16)
            Spacer(minLength: 0)
            Image(systemName: "pencil")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PictureStyle.mark)
        }
        .padding(.horizontal, 9)
        .frame(width: 84, height: 32)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(PictureStyle.paper))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(HomeStyle.tint, lineWidth: 1.5))
    }
}
