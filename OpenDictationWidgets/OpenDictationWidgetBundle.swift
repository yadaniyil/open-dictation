import SwiftUI
import WidgetKit

/// Only the Live Activity. There is no Control Center control on purpose: a control can start
/// and stop a dictation, but iOS does not let the app put the text on the clipboard while another
/// app is in front. A shortcut can, so Control Center runs the shortcut instead.
@main
struct OpenDictationWidgetBundle: WidgetBundle {
    var body: some Widget {
        DictationLiveActivity()
    }
}
