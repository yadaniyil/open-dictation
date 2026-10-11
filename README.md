# Open Dictation

Open Dictation is a small iPhone app for one job: you hold the Action Button, talk, hold it again, and the text of what you said is on the clipboard, ready to paste into any app. Speech becomes text either on the iPhone itself, with a model you download once, or through your own OpenAI or ElevenLabs API key. There is no account, no subscription, no server of ours, no analytics and no tracking. The app is free and the code is here.

## How it works

1. Hold the Action Button. The Dynamic Island shows "Listening".
2. Say what you want to write.
3. Hold the Action Button again. When it says "Copied", paste.

## Features

- One action, "Toggle Dictation", starts and stops. It works from the Action Button, Control Center, the Lock Screen, Back Tap, the Shortcuts app and the button in the app.
- A Live Activity (Dynamic Island and Lock Screen) shows a timer while the app listens, with a button to stop.
- Four ways to turn speech into text. Two run on the iPhone: Parakeet V3 and Whisper Large Turbo. Two run in the cloud with your own key: OpenAI and ElevenLabs.
- Languages: Parakeet V3 knows 25 European languages, with English, Ukrainian and Polish among them. Whisper Large Turbo knows about a hundred. The language is detected automatically; with a cloud provider you can also set it.
- Writing styles (optional, need your OpenAI key): As spoken, Clean, Casual, Formal, or your own instructions.
- Spoken instructions (optional, need your OpenAI key): start or end a dictation with "give me this in Polish" and the text comes out in Polish.
- "Words to get right": a list of names and special words. Only the OpenAI speech model uses it.
- The last 30 texts stay in the app, so nothing is lost if a paste goes wrong.
- A recording you forget stops by itself (10 minutes by default, 1 to 30 in Settings) and is still turned into text.
- A recording that could not be turned into text stays on the phone, and you can try again.

## Privacy

- No server of ours exists. The app talks only to the provider you chose, and to Hugging Face when you download a model.
- With an on-device model your voice stays on the iPhone, and dictation works offline.
- With a cloud provider your voice goes straight from the iPhone to that provider, with your key.
- If an OpenAI key is saved and "Spoken instructions" is on (the default) or a style is picked, the **text** also goes to OpenAI, whichever option did the listening.
- Keys are stored in the iPhone Keychain, for this device only.
- No analytics, no ads, no tracking, no crash-report SDK.

The full policy is in [PRIVACY.md](PRIVACY.md).

## Speech options

| Option | Where it runs | What you need | Cost |
|---|---|---|---|
| Parakeet V3 | On the iPhone | A 494 MB download | Free |
| Whisper Large Turbo | On the iPhone | A 632 MB download | Free |
| OpenAI | Cloud | Your own OpenAI API key | You pay OpenAI for what you use |
| ElevenLabs | Cloud | Your own ElevenLabs API key | As your ElevenLabs plan says |

Pick one in Settings and tap "Use for dictation". Saving a key or finishing a download never switches by itself.

### OpenAI key

Make a key at <https://platform.openai.com/api-keys>. A restricted key is enough. It needs exactly these permissions:

- **List models: Read** (the app uses it to check the key when you save it)
- **Model capabilities: Request** (speech to text, and the text step for styles)

The same key is used for writing styles and spoken instructions, whichever option listens.

### ElevenLabs key

Make a key in your ElevenLabs account at <https://elevenlabs.io>. It needs one permission:

- **Speech to Text**

## Set up the Action Button

The app shows these steps under Settings > Action Button.

**1. Make the shortcut**

1. Open the Shortcuts app and tap **+**. If it asks you to describe a shortcut, tap **Edit**.
2. In the search field, type **Toggle Dictation** and tap it.
3. Search for **If** and tap it. It picks Toggle Dictation by itself. Tap **is** and choose **has any value**.
4. Search for **Copy to Clipboard** and tap it. It lands at the bottom. Hold it and drag it up, to just under the **If** line. It then reads "Copy Toggle Dictation to clipboard".
5. Tap the name at the top, choose **Rename** and type **Dictate**.

The shortcut is what puts the text on the clipboard while another app is open. "Copy to Clipboard" has to sit inside the If. Left at the bottom, it empties your clipboard every time you start dictating.

**2. Put it on the Action Button**

1. Open the iPhone Settings app and tap **Action Button**.
2. Swipe to **Shortcut**, tap **Choose a Shortcut** and pick **Dictate**.

**3. Use it**

Hold the Action Button, talk, hold it again, paste.

No Action Button? The same shortcut works from Control Center, the Lock Screen or Back Tap.

## Build it yourself

You need:

- A Mac with Xcode 27
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An iPhone with iOS 26 or later. The Simulator has no Action Button, and starting the microphone in the background and the clipboard only behave like the real thing on a real iPhone.
- An Apple developer team id

Steps:

```sh
git clone https://github.com/yadaniyil/open-dictation.git
cd open-dictation
```

Open `project.yml` and change two things to your own:

- `DEVELOPMENT_TEAM`: your team id
- `bundleIdPrefix` and the `PRODUCT_BUNDLE_IDENTIFIER` lines (app, widget extension, tests): a bundle id that belongs to you

Then:

```sh
xcodegen generate
open OpenDictation.xcodeproj
```

Choose the `OpenDictation` scheme and your iPhone, then run. The Xcode project is generated, so edit `project.yml` and not the project. Run `xcodegen generate` again after adding or removing files.

Swift Package Manager fetches two libraries, pinned to exact versions in `project.yml`: FluidAudio 0.17.7 and WhisperKit 1.1.1.

### Tests

```sh
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation \
  -destination 'platform=iOS Simulator,name=YOUR_SIMULATOR' test
```

The tests never call the real OpenAI or ElevenLabs API. Debug builds read `OD_API_BASE_URL`, `OD_TEST_API_KEY`, `OD_ELEVENLABS_BASE_URL` and `OD_TEST_ELEVENLABS_KEY` from the launch environment, so a local mock server can stand in.

## How the code fits together

- `Shared/ToggleDictationIntent.swift`: the one App Intent behind the Action Button, Shortcuts and the Live Activity's Done button.
- `OpenDictation/Core/DictationController.swift`: the state machine (idle, recording, transcribing).
- `OpenDictation/Core/AudioRecorder.swift`: the microphone, into a small 16 kHz AAC file.
- `OpenDictation/Core/Speech/`: the on-device models.
- `OpenDictation/Core/OpenAITranscriber.swift`, `ElevenLabsTranscriber.swift`: the cloud speech calls.
- `OpenDictation/Core/OpenAIRewriter.swift`: the optional style step.
- `OpenDictationWidgets/`: the Live Activity and Dynamic Island.

## Third-party licenses

Open Dictation uses the work of others.

| What | Made by | License | Notes |
|---|---|---|---|
| [FluidAudio](https://github.com/FluidInference/FluidAudio) 0.17.7 | FluidInference | Apache 2.0 | Runs Parakeet on the iPhone. Linked into the app. |
| [Parakeet TDT 0.6B v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) | NVIDIA | **CC BY 4.0, attribution required** | Speech model. Not in the app bundle: downloaded on request as the [Core ML conversion by FluidInference](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml), also CC BY 4.0. |
| [WhisperKit](https://github.com/argmaxinc/WhisperKit) 1.1.1 | Argmax, Inc. | MIT | Runs Whisper on the iPhone. Linked into the app. The repository is now named `argmax-oss-swift`. |
| [Whisper large-v3-turbo](https://huggingface.co/openai/whisper-large-v3-turbo) | OpenAI | MIT | Speech model weights. Not in the app bundle: downloaded on request as the Core ML build from [argmaxinc/whisperkit-coreml](https://huggingface.co/argmaxinc/whisperkit-coreml) (MIT). |

Parts that come inside those two libraries and are linked into the app:

- Inside FluidAudio: fastcluster (BSD 2-Clause), VBx (Apache 2.0), and the NemoTextProcessing binary built from text-processing-rs (Apache 2.0), which contains grammars from NVIDIA NeMo Text Processing (Apache 2.0) and the Rust crates rustfst and flate2 (MIT or Apache 2.0). FluidAudio lists these, and further notices for its text-to-speech parts that this app does not use, in its `ThirdPartyLicenses` folder.
- Inside WhisperKit: code derived from Hugging Face's swift-transformers (Apache 2.0), listed in its `NOTICES` file.

`swift-argument-parser` (Apache 2.0) shows up in `Package.resolved` because the libraries' command-line tools use it. It is not part of the app.

The exact attribution text is in [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md). These licenses were checked on 2026-10-11 against the pinned versions. If you change a version or a model, check again.

OpenAI, ElevenLabs, NVIDIA, Parakeet, Whisper and Hugging Face are names and trademarks of their owners. Open Dictation is an independent project. None of them made it, sponsors it or endorses it.

## Contributing

Issues and pull requests are welcome.

- For a bug, say which iPhone and iOS version, which speech option was in use, and what you did.
- Never post an API key or a private recording in an issue.
- Keep changes small and in the spirit of the app: one job, few settings, no accounts, no analytics.
- Run the tests before you open a pull request.
- By contributing you agree that your contribution is under the MIT license.

## Support

Open an issue: <https://github.com/yadaniyil/open-dictation/issues>

## License

MIT. See [LICENSE](LICENSE).

Copyright (c) 2026 Danny Yakovlev
