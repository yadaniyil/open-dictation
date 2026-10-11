import Foundation

/// Which iPhone this is, read from its model identifier such as "iPhone16,1".
/// iOS has no call that says whether there is an Action Button, so the identifier has to.
enum DeviceModel {
    /// This iPhone's identifier. The Simulator runs on the Mac's processor, so there the
    /// identifier of the iPhone it stands in for comes from the environment.
    static let identifier: String = {
        let environment = ProcessInfo.processInfo.environment
        #if DEBUG
        // A Simulator cannot be told to stand in for another iPhone at launch. `OD_MODEL_IDENTIFIER`
        // in the launch environment can, to see what an iPhone without an Action Button gets:
        // "iPhone14,7" is one.
        if let pretended = environment["OD_MODEL_IDENTIFIER"], !pretended.isEmpty {
            return pretended
        }
        #endif
        if let simulated = environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        var system = utsname()
        uname(&system)
        return withUnsafeBytes(of: &system.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }()

    static let hasActionButton = hasActionButton(identifier: identifier)

    /// iPhone 15 Pro and 15 Pro Max ("iPhone16,1" and "iPhone16,2") were the first with an
    /// Action Button, and every iPhone since has one. An iPad has none.
    /// An identifier that cannot be read counts as a yes: an unknown one is most likely a newer iPhone.
    static func hasActionButton(identifier: String) -> Bool {
        if identifier.hasPrefix("iPad") { return false }
        guard identifier.hasPrefix("iPhone") else { return true }
        let numbers = identifier.dropFirst("iPhone".count).split(separator: ",", omittingEmptySubsequences: false)
        guard numbers.count == 2, let major = Int(numbers[0]), let minor = Int(numbers[1]) else { return true }
        switch major {
        case ..<16: return false
        case 16: return minor == 1 || minor == 2
        default: return true
        }
    }
}
