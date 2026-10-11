import SwiftUI

// The pictures that hint at the iPhone's own screens: Settings, Control Center, the Lock Screen.

/// A list of three rows, the way Settings looks, with one row picked out.
struct ListPicture: View {
    /// 0 is the top row.
    let highlighted: Int

    private let barWidths: [CGFloat] = [38, 44, 30]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(barWidths.indices, id: \.self) { index in
                let isHighlighted = index == highlighted
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .frame(width: 11, height: 11)
                    Capsule()
                        .frame(width: barWidths[index], height: 5)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(isHighlighted ? HomeStyle.tint : PictureStyle.mark)
                .padding(.horizontal, 7)
                .frame(height: isHighlighted ? 24 : 22)
                .background(isHighlighted ? HomeStyle.softTint : .clear)
            }
        }
        .frame(width: 78)
        .background(PictureStyle.paper)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Settings > Action Button: the chosen action in the middle and a dot for every choice.
struct ActionPickerPicture: View {
    /// Which dot is lit. Shortcut is one of the last choices.
    private let dots = 5
    private let current = 3

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: PictureStyle.shortcutSymbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(HomeStyle.onTint)
                .frame(width: 50, height: 50)
                .background(Circle().fill(HomeStyle.tint))
            HStack(spacing: 5) {
                ForEach(0..<dots, id: \.self) { dot in
                    Circle()
                        .fill(dot == current ? Color.white : PictureStyle.dim)
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
}

/// Control Center, with the + at its top left that starts editing.
struct ControlCenterAddPicture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(HomeStyle.onTint)
                .frame(width: 24, height: 24)
                .background(Circle().fill(HomeStyle.tint))
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<2, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<2, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(PictureStyle.dim)
                                .frame(width: 34, height: 22)
                        }
                    }
                }
            }
        }
    }
}

/// The controls to choose from, with Run Shortcut picked out among them.
struct ShortcutControlPicture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: PictureStyle.shortcutSymbol)
                        .font(.system(size: 12, weight: .semibold))
                    Capsule().frame(width: 18, height: 4)
                }
                .foregroundStyle(HomeStyle.onTint)
                .frame(width: 52, height: 28)
                .background(Capsule().fill(HomeStyle.tint))
                control
            }
            HStack(spacing: 8) {
                control
                control
                control
            }
        }
    }

    private var control: some View {
        Circle()
            .fill(PictureStyle.dim)
            .frame(width: 24, height: 24)
    }
}

/// The Lock Screen held down: the screen shrinks and "Customize" shows under it.
struct LockScreenCustomizePicture: View {
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 5) {
                Capsule().frame(width: 16, height: 3)
                Capsule().frame(width: 26, height: 9)
            }
            .foregroundStyle(.white.opacity(0.55))
            .padding(.top, 9)
            .frame(width: 44, height: 56, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(PictureStyle.dim))
            Capsule()
                .fill(HomeStyle.onTint)
                .frame(width: 30, height: 4)
                .frame(width: 54, height: 18)
                .background(Capsule().fill(HomeStyle.tint))
        }
    }
}

/// The two round buttons at the bottom of the Lock Screen while it is being edited:
/// one still there with its minus, one already taken away and waiting for a new control.
struct LockScreenSwapPicture: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "flashlight.off.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 34, height: 34)
                .background(Circle().fill(PictureStyle.dim))
                .overlay(alignment: .topLeading) {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(PictureStyle.night)
                        .frame(width: 15, height: 15)
                        .background(Circle().fill(.white))
                        .offset(x: -4, y: -4)
                }
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(HomeStyle.onTint)
                .frame(width: 34, height: 34)
                .background(Circle().fill(HomeStyle.tint))
        }
    }
}

/// The back of an iPhone, with rings where a finger taps it.
struct BackTapPicture: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(PictureStyle.paper)
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(PictureStyle.line, lineWidth: 1.5))
                .overlay(alignment: .topLeading) {
                    // The camera, which is how the back is told from the front.
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(PictureStyle.mark)
                        .frame(width: 17, height: 17)
                        .padding(6)
                }
                .frame(width: 46, height: 80)
            ZStack {
                Circle().fill(HomeStyle.tint.opacity(0.14)).frame(width: 38, height: 38)
                Circle().fill(HomeStyle.tint.opacity(0.3)).frame(width: 24, height: 24)
                Circle().fill(HomeStyle.tint).frame(width: 10, height: 10)
            }
            .offset(y: 12)
        }
    }
}
