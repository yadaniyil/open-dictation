import Foundation
import Observation

/// The last few transcripts, kept on the device only, so nothing is lost if a paste goes wrong.
@MainActor
@Observable
final class HistoryStore {
    struct Item: Codable, Identifiable, Hashable, Sendable {
        var id = UUID()
        var date = Date()
        var text: String
    }

    private(set) var items: [Item] = []

    private let limit = 30
    private let fileURL: URL

    init(fileURL: URL = HistoryStore.defaultFileURL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Item].self, from: data) {
            items = saved
        }
    }

    func add(_ text: String) {
        items.insert(Item(text: text), at: 0)
        if items.count > limit { items.removeLast(items.count - limit) }
        save()
    }

    func remove(_ item: Item) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    nonisolated static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appendingPathComponent("history.json")
    }
}
