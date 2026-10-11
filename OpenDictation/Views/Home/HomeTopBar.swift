import SwiftUI

/// The top of the main screen: the app's name, and the ways into the user's stats and Settings.
struct HomeTopBar: View {
    let openStats: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: HomeStyle.rowSpacing) {
            Text("Open Dictation")
                .font(HomeStyle.nameFont)
                .foregroundStyle(HomeStyle.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            HomeTopBarButton(symbol: "chart.bar.fill", name: "Your stats", action: openStats)
                .accessibilityIdentifier("statsButton")
            HomeTopBarButton(symbol: "slider.horizontal.3", name: "Settings", action: openSettings)
                .accessibilityIdentifier("settingsButton")
        }
        .frame(minHeight: HomeStyle.touchTarget)
    }
}

/// One round button of the top bar.
private struct HomeTopBarButton: View {
    let symbol: String
    /// What VoiceOver says.
    let name: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // A fixed size, like the circle around it.
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HomeStyle.text)
                .frame(width: HomeStyle.touchTarget, height: HomeStyle.touchTarget)
                .background(Circle().fill(HomeStyle.card))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
    }
}

#Preview {
    HomeTopBar(openStats: {}, openSettings: {})
        .padding()
        .background(HomeStyle.background)
}
