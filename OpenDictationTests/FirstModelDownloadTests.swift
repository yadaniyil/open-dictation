import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct FirstModelDownloadTests {
    private let parakeet = FakeSpeechEngine()
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "FirstModelDownloadTests.\(UUID().uuidString)"))
    }

    /// A new phone: no key saved, no model downloaded.
    private func makeStore(openAIKey: Bool = false) -> SpeechModelStore {
        SpeechModelStore(
            engines: [.parakeetV3: parakeet, .whisperLargeTurbo: FakeSpeechEngine()],
            selected: .openAI,
            hasKey: { openAIKey && $0 == .openAI },
            save: { _ in })
    }

    private func start(
        _ store: SpeechModelStore, agreed: Bool = true,
        freeBytes: Int64 = FirstModelDownload.neededBytes, onWiFi: Bool = true
    ) async {
        await FirstModelDownload.startIfSensible(
            store: store, defaults: defaults,
            hasAgreed: { agreed }, freeBytes: { freeBytes }, isOnCheapNetwork: { onWiFi })
    }

    private func waitUntilReady(_ store: SpeechModelStore) async {
        for _ in 0..<400 where store.status(of: FirstModelDownload.model) != .ready {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func aNewPhoneOnWiFiGetsTheModelByItselfAndUsesIt() async {
        let store = makeStore()
        await start(store)
        await waitUntilReady(store)
        #expect(store.status(of: .parakeetV3) == .ready)
        #expect(store.selected == .parakeetV3)
        #expect(store.canListen)
    }

    @Test func nothingStartsBeforeTheWelcomePagesAreAgreedTo() async {
        let store = makeStore()
        await start(store, agreed: false)
        #expect(store.status(of: .parakeetV3) == .notSetUp)
    }

    @Test func nothingStartsOnMobileData() async {
        let store = makeStore()
        await start(store, onWiFi: false)
        #expect(store.status(of: .parakeetV3) == .notSetUp)
        // Later, on Wi-Fi, it does.
        await start(store)
        await waitUntilReady(store)
        #expect(store.status(of: .parakeetV3) == .ready)
    }

    @Test func nothingStartsWithoutRoomOnThePhone() async {
        let store = makeStore()
        await start(store, freeBytes: FirstModelDownload.neededBytes - 1)
        #expect(store.status(of: .parakeetV3) == .notSetUp)
    }

    @Test func aPhoneWithAKeyIsLeftAlone() async {
        let store = makeStore(openAIKey: true)
        await start(store)
        #expect(store.status(of: .parakeetV3) == .notSetUp)
    }

    @Test func aCancelledDownloadDoesNotStartAgainByItself() async {
        let store = makeStore()
        parakeet.plan(steps: [0.25], waitsForRelease: true)
        await start(store)
        #expect(store.status(of: .parakeetV3) != .notSetUp)

        store.cancelDownload(.parakeetV3)
        parakeet.release()
        for _ in 0..<400 where store.status(of: .parakeetV3) != .notSetUp {
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(store.status(of: .parakeetV3) == .notSetUp)

        await start(store)
        #expect(store.status(of: .parakeetV3) == .notSetUp)
    }

    @Test func itStartsByItselfOnlyOnWiFiWithRoomToSpare() {
        let room = FirstModelDownload.neededBytes
        #expect(FirstModelDownload.shouldStart(freeBytes: room, isOnCheapNetwork: true))
        #expect(!FirstModelDownload.shouldStart(freeBytes: room, isOnCheapNetwork: false))
        #expect(!FirstModelDownload.shouldStart(freeBytes: room - 1, isOnCheapNetwork: true))
    }

    /// The download starts without a question, so the welcome pages have to name its size first.
    @Test func theWelcomePagesNameTheSizeOfTheDownload() throws {
        let size = try #require(FirstModelDownload.model.sizeLabel)
        let captions = OnboardingPage.consent.tiles.compactMap(\.caption).map { String(localized: $0) }
        #expect(captions.contains { $0.contains(size) })
    }

    @Test func itAsksForMoreRoomThanTheFilesTake() {
        // 494 MB of files; the phone also keeps a prepared copy of the model.
        #expect(FirstModelDownload.neededBytes > 2 * 494_000_000)
    }
}
