import SwiftUI

struct SetupGuideView: View {
    var body: some View {
        List {
            Section {
                Step(number: 1, text: "Open the **Shortcuts** app and tap **+**. If it asks you to describe a shortcut, tap **Edit**.")
                Step(number: 2, text: "In the search field, type **Toggle Dictation** and tap it.")
                Step(number: 3, text: "Search for **If** and tap it. It picks Toggle Dictation by itself. Tap **is** and choose **has any value**.")
                Step(number: 4, text: "Search for **Copy to Clipboard** and tap it. It lands at the bottom: hold it and drag it up, to just under the **If** line. It then reads Copy **Toggle Dictation** to clipboard.")
                Step(number: 5, text: "Tap the name at the top, choose **Rename** and type **Dictate**.")
            } header: {
                Text("1. Make the shortcut")
            } footer: {
                Text("The shortcut is what puts the text on the clipboard while another app is open. Copy to Clipboard has to sit inside the If: left at the bottom, it empties your clipboard every time you start dictating.")
            }

            Section {
                Step(number: 1, text: "Open the iPhone **Settings** app and tap **Action Button**.")
                Step(number: 2, text: "Swipe to **Shortcut**, tap **Choose a Shortcut** and pick **Dictate**.")
            } header: {
                Text("2. Put it on the Action Button")
            }

            Section {
                Step(number: 1, text: "Hold the Action Button. The top of the screen shows **Listening**.")
                Step(number: 2, text: "Say what you want to type.")
                Step(number: 3, text: "Hold the Action Button again. When it says **Copied**, paste.")
            } header: {
                Text("3. Use it")
            } footer: {
                Text("No Action Button? The same shortcut works from Control Center, the Lock Screen or Back Tap.")
            }
        }
        .navigationTitle("Action Button")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct Step: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))
            Text(text)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { SetupGuideView() }
}
