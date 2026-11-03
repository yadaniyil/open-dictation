# Handoff: code review and fixes

Working note for whoever picks this up. **Delete this file before merging.**

Branch: `claude/admiring-hopper-98qymq`. Never push to `main`, never merge.

## Goal

Review the whole app, fix only bugs that can be shown clearly (small fixes), add tests for every
fix and for core logic that had none, and open a draft PR with a "review notes" section.
No changes to signing, store metadata, release config or secrets. No new dependencies.

## Done

| Commit | What |
|---|---|
| 4da3953 | A recording is moved out of the temporary folder before it is turned into text, and one left over at launch waits for another try (`UnsentRecording`). Background time is asked for before the microphone stops and is ended when it runs out. |
| 1f8693e | The clipboard re-copy on coming to the front checks the change count, so it never replaces something the user copied since (`ClipboardRetry`). |
| ace2a21 | A stopped first model download carries on by itself only on Wi-Fi. |
| 125c394 | ElevenLabs requests send `tag_audio_events=false`. |
| bcba55f | New tests for `HistoryStore` and `MultipartForm`. |

## In progress

Nothing. Draft PR: https://github.com/yadaniyil/open-dictation/pull/1

Checked on Linux with Swift 6.3, in a scratch package outside the repo that copies the
Foundation-only files and stands in for UIKit, Network, os, ActivityKit, AVFoundation and the
two model libraries:
- 96 tests in 18 suites pass: all new tests, plus the existing store, preparation, turn-taking,
  network (OpenAI, ElevenLabs), rewriter, archive and token tests.
- Each fix was undone in turn; its test then failed.
- `DictationController.swift` type-checks in Swift 6 mode with each plausible annotation of
  `beginBackgroundTask`'s expiration handler.

## Next steps

1. On a Mac with Xcode 27: `xcodegen generate`, then run the tests (command below). Nothing here
   was built with the iOS SDK.
2. On a real iPhone, check: a 10 minute recording with Parakeet that stops by the time limit
   while another app is in front, then open the app (it should show the text, or offer the
   recording again). Also the clipboard case: dictate, paste, copy a link elsewhere, open the app
   within 2 minutes; the link must stay.
3. Consider the review notes in the PR, most of all the Live Activity's stop button.

## Bugs found, not fixed

- `OpenDictationWidgets/DictationLiveActivity.swift:73,119`: the Live Activity's stop button runs
  the same toggle intent. If the app died while recording, the activity stays, and tapping its stop
  button starts a new recording. Needs a stop-only intent, tested on a device.
- `OpenDictation/Core/UnsentRecording.swift` (`keepForRetry`): one place for a failed recording.
  A second failure replaces the first without a word. Was the same before.
- `OpenDictation/Core/Speech/OneAtATime.swift:25`: a download's last step loads its model outside
  the queue, so it can overlap a dictation with the other model (two big models in memory).
- `OpenDictation/Core/OpenAIRewriter.swift:29`: `max_output_tokens` 2048 cuts long dictations
  (roughly 1,500 English words, fewer in Ukrainian); the plain text is copied with a note.
- `OpenDictation/Core/HistoryStore.swift:21` and `Stats/DictationLog.swift:66`: a file that
  cannot be read is treated as empty, and the next save replaces it.
- `OpenDictation/Core/AudioRecorder.swift`: no handling of media services being reset, and
  Bluetooth microphones are never used (no `.allowBluetoothHFP`).
- `OpenDictation/Views/Home/UnsentRecordingCard.swift:18`: "Throw it away" works during a retry.

## Build and test

```sh
xcodegen generate
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation \
  -destination 'platform=iOS Simulator,name=YOUR_SIMULATOR' test
```

Could not run here: no Xcode or iOS SDK in the cloud box, so no iOS build and no XCTest/Swift
Testing run against the real app target.
