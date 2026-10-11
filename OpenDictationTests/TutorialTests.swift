import Foundation
import Testing
import UIKit
@testable import OpenDictation

struct TutorialTests {
    private let triggers = Tutorial.triggers(hasActionButton: true)

    private func words(of tutorial: Tutorial) -> [String] {
        tutorial.steps.compactMap(\.text).map { String(localized: $0) }
    }

    @Test func anIPhoneWithAnActionButtonIsOfferedItFirst() {
        #expect(triggers.map(\.id) == ["actionButton", "controlCenter", "lockScreen", "backTap"])
    }

    @Test func anIPhoneWithoutOneIsNotOfferedItAndControlCenterLeads() {
        let offered = Tutorial.triggers(hasActionButton: false)
        #expect(offered.map(\.id) == ["controlCenter", "lockScreen", "backTap"])
    }

    /// The main screen walks through one way only: the best one this iPhone has.
    @Test func theMainScreenShowsTheBestWayForThisIPhone() {
        #expect(Tutorial.best(hasActionButton: true) == .actionButton)
        #expect(Tutorial.best(hasActionButton: false) == .controlCenter)
    }

    @Test func everyPlaceToRunItFromHasATilePictureAndAResult() {
        for tutorial in triggers {
            #expect(tutorial.glyph != nil, "\(tutorial.id)")
            #expect(tutorial.result != nil, "\(tutorial.id)")
        }
    }

    /// Only the shortcut can put the text on the clipboard, so every guide starts by getting it.
    @Test func everyPlaceToRunItFromStartsWithGettingTheShortcut() {
        for tutorial in triggers {
            #expect(tutorial.steps.first?.action == .getShortcut, "\(tutorial.id)")
            #expect(tutorial.steps.dropFirst().allSatisfy { $0.action != .getShortcut }, "\(tutorial.id)")
            #expect(tutorial.steps.allSatisfy { $0.text != nil }, "\(tutorial.id)")
        }
    }

    @Test func aGuideIsShort() {
        for tutorial in triggers {
            #expect((2...4).contains(tutorial.steps.count), "\(tutorial.id)")
        }
        #expect(Tutorial.makeShortcut.steps.count <= 5)
    }

    /// The ready-made shortcut is called "Open Dictation", so that is the name to look for.
    @Test func everyGuideEndsByChoosingTheShortcutByItsName() {
        #expect(Tutorial.shortcutName == "Open Dictation")
        for tutorial in triggers + [.makeShortcut] {
            let last = words(of: tutorial).last ?? ""
            #expect(last.contains(Tutorial.shortcutName), "\(tutorial.id)")
        }
    }

    /// The list a shortcut is picked from also has a row for the app itself, and that row starts
    /// a dictation that cannot be pasted. So the guides say where the shortcut is.
    @Test func theGuidesPointAtTheUsersOwnShortcuts() {
        for tutorial in [Tutorial.controlCenter, .lockScreen] {
            #expect(words(of: tutorial).last?.contains("My Shortcuts") == true, "\(tutorial.id)")
        }
    }

    @Test func makingItByHandNeedsNoShortcutFirst() {
        #expect(Tutorial.makeShortcut.steps.allSatisfy { $0.text != nil && $0.action == nil })
        let all = words(of: .makeShortcut).joined(separator: " ")
        #expect(all.contains("Toggle Dictation"))
        #expect(all.contains("has any value"))
        #expect(all.contains("Copy to Clipboard"))
    }

    @Test func everyPictureHasWordsForVoiceOver() {
        for tutorial in triggers + [.makeShortcut] {
            for step in tutorial.steps {
                #expect(!String(localized: step.pictureDescription).isEmpty, "\(tutorial.id)")
            }
        }
    }

    /// A screenshot stands in for a drawing only where the picture is in the app.
    @Test func everyScreenshotIsInTheAppAndItsFrameIsInsideIt() {
        for tutorial in triggers + [.makeShortcut] {
            for step in tutorial.steps {
                guard let screenshot = step.screenshot else { continue }
                let image = UIImage(named: screenshot.asset)
                #expect(image != nil, "\(screenshot.asset)")
                if let size = image?.size {
                    #expect(abs(size.width / size.height - screenshot.aspect) < 0.01, "\(screenshot.asset)")
                }
                #expect(CGRect(x: 0, y: 0, width: 1, height: 1).contains(screenshot.target), "\(screenshot.asset)")
            }
        }
    }

    @Test func guidesAreToldApartByName() {
        let all = triggers + [.makeShortcut]
        #expect(Set(all).count == all.count)
        #expect(Tutorial.actionButton == Tutorial.actionButton)
        #expect(Tutorial.actionButton != Tutorial.controlCenter)
    }

    @Test func theShortcutLinkIsAnICloudShortcut() throws {
        let link = try #require(AppLinks.dictateShortcut)
        #expect(link.scheme == "https")
        #expect(link.host() == "www.icloud.com")
        #expect(link.path().hasPrefix("/shortcuts/"))
    }

    @Test func everyProviderShowsItsMakersLogo() {
        #expect(SpeechModel.openAI.logo.asset == "OpenAILogo")
        #expect(SpeechModel.whisperLargeTurbo.logo.asset == "OpenAILogo")
        #expect(SpeechModel.elevenLabs.logo.asset == "ElevenLabsLogo")
        #expect(SpeechModel.parakeetV3.logo.asset == "NvidiaLogo")
        for model in SpeechModel.allCases {
            #expect(UIImage(named: model.logo.asset) != nil, "\(model.name)")
            #expect(model.logo.label.hasSuffix("logo"), "\(model.name)")
        }
    }
}
