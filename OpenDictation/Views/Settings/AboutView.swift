import SwiftUI

/// Which version this is, and where to read the privacy policy, the code and the credits.
struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Version", value: Self.info("CFBundleShortVersionString"))
                LabeledContent("Build", value: Self.info("CFBundleVersion"))
            }

            Section {
                WebLink(title: "Report a problem", url: AppLinks.issues)
            } footer: {
                Text("Something not working? Tell us here. It opens in your browser and needs a GitHub account.")
            }

            Section {
                WebLink(title: "Privacy policy", url: AppLinks.privacyPolicy)
                WebLink(title: "Source code", url: AppLinks.repository)
            } footer: {
                Text("Both open in your browser. Open Dictation is open source under the MIT License.")
            }

            Section {
                NavigationLink("Acknowledgements", value: SettingsRoute.acknowledgements)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func info(_ key: String) -> String {
        Bundle.main.infoDictionary?[key] as? String ?? ""
    }
}

/// A row that leaves the app for a web page. The arrow stands where a pushed screen has its chevron.
private struct WebLink: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    // Not `.tertiary`: inside a Link that is a pale shade of the accent colour.
                    .foregroundStyle(Color(.tertiaryLabel))
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview {
    NavigationStack { AboutView() }
}
