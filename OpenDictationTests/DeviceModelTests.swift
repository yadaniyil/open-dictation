import Testing
@testable import OpenDictation

struct DeviceModelTests {
    @Test(arguments: [
        // Before the Action Button.
        ("iPhone12,8", false),  // iPhone SE (2nd generation)
        ("iPhone14,6", false),  // iPhone SE (3rd generation)
        ("iPhone14,7", false),  // iPhone 14
        ("iPhone15,3", false),  // iPhone 14 Pro Max
        // The iPhone 15 family: only the two Pro models have one.
        ("iPhone15,4", false),  // iPhone 15
        ("iPhone15,5", false),  // iPhone 15 Plus
        ("iPhone16,1", true),   // iPhone 15 Pro
        ("iPhone16,2", true),   // iPhone 15 Pro Max
        ("iPhone16,3", false),
        // Every iPhone since.
        ("iPhone17,1", true),   // iPhone 16 Pro
        ("iPhone17,3", true),   // iPhone 16
        ("iPhone17,5", true),   // iPhone 16e
        ("iPhone18,1", true),   // iPhone 17 Pro
        ("iPhone19,4", true),
        ("iPhone100,12", true),
        // An iPad runs the app too, and has no Action Button.
        ("iPad16,3", false),
        // Anything that cannot be read counts as a yes.
        ("", true),
        ("arm64", true),
        ("x86_64", true),
        ("iPhone", true),
        ("iPhone16", true),
        ("iPhone,1", true),
        ("iPhone16,", true),
        ("iPhone16,one", true),
        ("iPhone16,1,2", true),
        ("iPhone 16,1", true),
    ])
    func theModelIdentifierSaysWhetherThereIsAnActionButton(identifier: String, expected: Bool) {
        #expect(DeviceModel.hasActionButton(identifier: identifier) == expected)
    }

    @Test func thisDeviceHasAnIdentifier() {
        #expect(!DeviceModel.identifier.isEmpty)
        #expect(DeviceModel.hasActionButton == DeviceModel.hasActionButton(identifier: DeviceModel.identifier))
    }
}
