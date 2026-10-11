import SwiftUI

/// Draws a step's picture in its square. It is a picture, so its sizes are fixed and VoiceOver
/// reads one sentence for it. Nothing here is a screenshot: every screen is hinted at with shapes.
struct TutorialPictureView: View {
    let picture: TutorialPicture
    let description: LocalizedStringResource

    var body: some View {
        drawing
            .frame(width: PictureStyle.side, height: PictureStyle.side)
            .background(isNight ? PictureStyle.night : PictureStyle.well)
            .clipShape(shape)
            // The night squares are black in both modes, so in dark mode only this line shows their edge.
            .overlay(shape.strokeBorder(.white.opacity(isNight ? 0.14 : 0)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(description))
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private var drawing: some View {
        switch picture {
        case .shortcut: ShortcutTilePicture()
        case .list(let highlighted): ListPicture(highlighted: highlighted)
        case .actionPicker: ActionPickerPicture()
        case .myShortcuts: MyShortcutsPicture()
        case .controlCenterAdd: ControlCenterAddPicture()
        case .shortcutControl: ShortcutControlPicture()
        case .lockScreenCustomize: LockScreenCustomizePicture()
        case .lockScreenSwap: LockScreenSwapPicture()
        case .backTap: BackTapPicture()
        case .newShortcut: ShortcutTilePicture(hasPlus: true)
        case .toggleAction: ActionsPicture(actions: [.init(symbol: "mic.fill", isHighlighted: true)])
        case .ifAction:
            ActionsPicture(actions: [
                .init(symbol: "mic.fill"),
                .init(symbol: "arrow.triangle.branch", isHighlighted: true),
            ])
        case .copyInsideIf:
            ActionsPicture(actions: [
                .init(symbol: "arrow.triangle.branch"),
                .init(symbol: "doc.on.clipboard.fill", isHighlighted: true, isInside: true),
                .init(symbol: nil),
            ])
        case .rename: RenamePicture()
        }
    }

    /// The screens that are dark on a real iPhone are drawn on a dark square.
    private var isNight: Bool {
        switch picture {
        case .actionPicker, .controlCenterAdd, .shortcutControl, .lockScreenCustomize, .lockScreenSwap: true
        default: false
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: PictureStyle.cornerRadius, style: .continuous)
    }
}

/// The colours and sizes the pictures share.
enum PictureStyle {
    static let side: CGFloat = 104
    static let cornerRadius: CGFloat = 18
    /// The square behind a picture, a shade away from the tile it sits on.
    static let well = Color(.tertiarySystemGroupedBackground)
    /// The square behind a picture of a dark screen.
    static let night = Color(red: 0.043, green: 0.043, blue: 0.059)
    /// Small cards inside a picture.
    static let paper = Color(.secondarySystemGroupedBackground)
    /// Stands in for a line of text.
    static let line = Color.primary.opacity(0.14)
    /// Stands in for an icon.
    static let mark = Color.primary.opacity(0.22)
    /// Things on a dark square that are not the point of the picture.
    static let dim = Color.white.opacity(0.2)
    /// Three stacked sheets: how the pictures say "shortcut".
    static let shortcutSymbol = "square.3.layers.3d"
}

#Preview {
    let pictures: [TutorialPicture] = [
        .shortcut, .list(highlighted: 1), .actionPicker, .myShortcuts, .controlCenterAdd, .shortcutControl,
        .lockScreenCustomize, .lockScreenSwap, .backTap, .newShortcut, .toggleAction, .ifAction, .copyInsideIf,
        .rename,
    ]
    return ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: PictureStyle.side))]) {
            ForEach(pictures.indices, id: \.self) { index in
                TutorialPictureView(picture: pictures[index], description: "Preview")
            }
        }
        .padding()
    }
    .background(HomeStyle.card)
}
