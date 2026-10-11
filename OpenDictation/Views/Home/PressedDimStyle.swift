import SwiftUI

/// For tiles and rows that are buttons: the label keeps its own look and dims while pressed.
struct PressedDimStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.6 : 1)
    }
}
