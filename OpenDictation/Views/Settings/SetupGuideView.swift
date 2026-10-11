import SwiftUI

/// The "Ways to start" row in Settings: every guide, for people who want another way than the
/// one the main screen walks through.
struct SetupGuideView: View {
    var hasActionButton = DeviceModel.hasActionButton

    var body: some View {
        List {
            Section {
                ForEach(Tutorial.triggers(hasActionButton: hasActionButton)) { tutorial in
                    NavigationLink(value: tutorial) {
                        Label {
                            Text(tutorial.title)
                        } icon: {
                            if let glyph = tutorial.glyph { TutorialGlyphView(glyph: glyph) }
                        }
                    }
                }
            } footer: {
                Text("Each one runs the \(Tutorial.shortcutName) shortcut.")
            }

            Section {
                NavigationLink(value: Tutorial.makeShortcut) {
                    Text(Tutorial.makeShortcut.title)
                }
            } footer: {
                Text("For when the ready-made shortcut will not open.")
            }
        }
        .navigationTitle("Ways to start")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Tutorial.self) { tutorial in
            TutorialView(tutorial: tutorial)
        }
    }
}

#Preview {
    NavigationStack { SetupGuideView() }
}
