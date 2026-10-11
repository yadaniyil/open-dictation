import SwiftUI

/// The button that gets the shortcut: it opens the ready-made one, and the Shortcuts app offers
/// to add it. Without a link, or when iOS cannot open it, the steps for making it by hand show
/// instead. The caller decides what the button looks like.
struct GetShortcutButton<Label: View>: View {
    @ViewBuilder let label: () -> Label

    @Environment(\.openURL) private var openURL
    @State private var showsHowToMakeIt = false

    var body: some View {
        Button(action: get, label: label)
            .accessibilityHint("Opens the Shortcuts app")
            .navigationDestination(isPresented: $showsHowToMakeIt) {
                TutorialView(tutorial: .makeShortcut)
            }
    }

    private func get() {
        guard let link = AppLinks.dictateShortcut else {
            showsHowToMakeIt = true
            return
        }
        openURL(link) { opened in
            if !opened { showsHowToMakeIt = true }
        }
    }
}

/// The filled, pill-shaped button. Its height is a minimum, so larger text makes it taller.
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: HomeStyle.pillHeight / 2, style: .continuous)
        configuration.label
            .font(HomeStyle.rowFont)
            .foregroundStyle(HomeStyle.onTint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, HomeStyle.pillSidePadding)
            .padding(.vertical, 8)
            .frame(minHeight: HomeStyle.pillHeight)
            .background(HomeStyle.tint, in: shape)
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// The small pill that sits beside a step's words.
struct SmallPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HomeStyle.rowFont)
            .foregroundStyle(HomeStyle.onTint)
            .lineLimit(1)
            .padding(.horizontal, HomeStyle.smallPillSidePadding)
            .frame(minHeight: HomeStyle.smallPillHeight)
            .background(HomeStyle.tint, in: Capsule())
            // The pill is small; what can be tapped is not.
            .frame(minHeight: HomeStyle.touchTarget)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Opens the Settings app. iOS only lets an app open its own page there.
struct OpenSettingsButton: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button("Open Settings") {
            if let settings = URL(string: UIApplication.openSettingsURLString) { openURL(settings) }
        }
        .buttonStyle(SmallPillButtonStyle())
        .accessibilityHint("Opens this app's page in Settings. Go back from there to the main list.")
        .accessibilityIdentifier("openSettings")
    }
}

#Preview {
    NavigationStack {
        GetShortcutButton { Text("Get the shortcut") }
            .buttonStyle(PillButtonStyle())
    }
}
