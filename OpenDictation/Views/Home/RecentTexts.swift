import SwiftUI
import UIKit

/// The last texts, newest first, so nothing is lost if a paste goes wrong.
/// Tap one to copy it again. Touch and hold it to delete it.
struct RecentTexts: View {
    let history: HistoryStore

    @State private var justCopied: HistoryStore.Item.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: HomeStyle.textCardSpacing) {
            Text("Recent")
                .font(HomeStyle.sectionFont)
                .foregroundStyle(HomeStyle.secondaryText)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            ForEach(history.items) { item in
                RecentTextCard(item: item, justCopied: justCopied == item.id) {
                    copy(item)
                } delete: {
                    history.remove(item)
                }
            }
        }
    }

    private func copy(_ item: HistoryStore.Item) {
        UIPasteboard.general.string = item.text
        justCopied = item.id
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if justCopied == item.id { justCopied = nil }
        }
    }
}

/// One recent text on its own card.
private struct RecentTextCard: View {
    let item: HistoryStore.Item
    let justCopied: Bool
    let copy: () -> Void
    let delete: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: copy) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.text)
                    .font(HomeStyle.bodyFont)
                    .foregroundStyle(HomeStyle.text)
                    .lineSpacing(3)
                    // Very large text fits few words on a line, so it gets more lines.
                    .lineLimit(typeSize.isAccessibilitySize ? 10 : 4)
                    .multilineTextAlignment(.leading)
                Text(justCopied ? "Copied" : "\(when). Tap to copy.")
                    .font(HomeStyle.captionFont)
                    .foregroundStyle(justCopied ? HomeStyle.good : HomeStyle.secondaryText)
            }
            .padding(HomeStyle.textCardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HomeStyle.card, in: shape)
            .contentShape(shape)
        }
        .buttonStyle(PressedDimStyle())
        .contentShape(.contextMenuPreview, shape)
        .contextMenu {
            Button("Copy", systemImage: "doc.on.doc", action: copy)
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
        }
        .accessibilityLabel(item.text)
        .accessibilityValue(justCopied ? "Copied" : when)
        .accessibilityHint("Copies it")
        .accessibilityAction(named: "Delete", delete)
    }

    /// "2 minutes ago", with a capital where the phrase starts with a word: "Yesterday".
    private var when: String {
        let phrase = item.date.formatted(.relative(presentation: .named))
        return phrase.prefix(1).capitalized + phrase.dropFirst()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeStyle.textCardCornerRadius, style: .continuous)
    }
}
