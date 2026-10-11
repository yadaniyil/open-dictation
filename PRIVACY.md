# Open Dictation privacy policy

Effective date: 2026-10-11

Open Dictation is an iPhone app that turns your speech into text and puts the text on your clipboard. It is made by Danny Yakovlev, an independent developer. In this policy "I" means Danny Yakovlev.

## The short version

- I do not receive any of your data. The app has no servers of mine, no account, no analytics, no ads and no tracking.
- With an on-device model, your voice never leaves your iPhone.
- With a cloud provider, your voice goes from your iPhone straight to the provider **you** chose, with **your** API key. I am not in the middle and cannot see it.
- If you saved an OpenAI key, the **text** of a dictation can go to OpenAI for writing styles and spoken instructions. The section on writing styles below says exactly when.
- Your recent texts and your API keys are stored on your iPhone, not on any server.

## What happens to your voice

When you dictate, the app records the microphone into a small audio file on your iPhone. What happens next depends on the speech option you picked in Settings.

### On-device models (Parakeet V3, Whisper Large Turbo)

- The audio is turned into text on your iPhone. The audio is not sent anywhere.
- It works without an internet connection.
- The model itself is a large file that the app downloads once, from Hugging Face (huggingface.co). As with any download, Hugging Face sees your IP address. No audio and no text is part of that download.

### OpenAI, with your own key

- The app sends the audio file over HTTPS to OpenAI (`api.openai.com`).
- With it go: the name of the speech model, the language code if you set a language, and your "Words to get right" list if you made one.
- When you save a key, the app asks OpenAI for its list of models once, to check that the key works. No audio is sent for this check.

### ElevenLabs, with your own key

- The app sends the audio file over HTTPS to ElevenLabs (`api.elevenlabs.io`).
- With it go: the name of the speech model and the language code if you set a language. The "Words to get right" list is not sent.

### Writing styles and spoken instructions (optional, OpenAI only)

- This step works on the **text**, not on the audio. The app sends the text of your dictation and the style instructions over HTTPS to OpenAI. It asks OpenAI not to store the request (`store: false`).
- It happens when you have saved an OpenAI key **and** one of these is true: you picked a style other than "As spoken", or the switch "Spoken instructions" is on. That switch is on by default.
- So, if you have saved an OpenAI key, the text can go to OpenAI even when an on-device model or ElevenLabs did the listening. To stop that, turn off "Spoken instructions" and use the style "As spoken", or remove the OpenAI key.
- Without an OpenAI key this step never runs.

### What the providers do with your data

That is between you and the provider. You have your own account and agreement with them, and their rules apply. Please read them:

- OpenAI privacy policy: https://openai.com/policies/privacy-policy/ (for Europe: https://openai.com/policies/eu-privacy-policy/)
- OpenAI, how API data is handled: https://developers.openai.com/api/docs/guides/your-data
- ElevenLabs privacy policy: https://elevenlabs.io/privacy-policy
- Hugging Face privacy policy (model downloads only): https://huggingface.co/privacy

Two things I read there on 2026-10-11, which may change: OpenAI writes that data sent to its API is not used to train its models unless you opt in. ElevenLabs writes that it may use personal information to improve its models, and that you can opt out in your account under "Data use". Check their pages for the current rules.

## What is stored on your iPhone

| What | Where | How long |
|---|---|---|
| Your API keys | The iPhone Keychain, on this device only | Until you tap "Remove key". A key is only ever sent to the service it belongs to. |
| Your last 30 texts ("Recent") | The app's own storage | Until you swipe a text away, tap Settings > Advanced > "Clear recent dictations", or delete the app. Older texts drop off the list by themselves. |
| The audio of a dictation | A temporary file | Deleted as soon as it has been turned into text. |
| A recording that could not be turned into text | The app's own storage, one file at most | Until "Try the last recording again" works, or you tap "Throw it away". |
| Kept recordings (a testing aid, **off** unless you turn it on) | The app's own storage | The last 20 recordings with their texts, the style and the model name. Turning "Keep recordings" off deletes them all. |
| Your settings (language, style, custom instructions, word list, chosen model) | The app's preferences | Until you change them or delete the app. |
| Downloaded speech models | The app's own storage | Until you tap "Delete download" or delete the app. |

Things iOS does, which you should know about:

- **Clipboard.** The text is put on the system clipboard, because that is the point of the app. Any app you paste into gets it. If you use Apple's Universal Clipboard, iOS can make it available on your other Apple devices.
- **Live Activity.** While the app listens, the Dynamic Island and the Lock Screen show a timer. When the text is ready, they show the first words of it for a few seconds.
- **Backups.** If you back up your iPhone to iCloud or to a computer, the app's stored texts, kept recordings and settings are part of your backup, like the data of other apps. Downloaded models are left out. The API keys are stored for this device only.
- **Crash reports.** If you turned on "Share With App Developers" in the iPhone's Settings, Apple sends me crash and usage reports without your name. The app adds nothing to them.

## What the app does not do

- No server of mine receives anything. I have none.
- No account, no sign-in, no email address.
- No analytics, no advertising, no tracking, no advertising identifier.
- No reading of your contacts, photos, location or anything else. The only permission the app asks for is the microphone, and it records only after you start a dictation.

The app talks to these hosts and no others: `api.openai.com` (only with your OpenAI key), `api.elevenlabs.io` (only with your ElevenLabs key) and `huggingface.co` with its download servers (only when you download a model). The source code is public, so anyone can check this: https://github.com/yadaniyil/open-dictation

## Your choices

- Use an on-device model if you do not want your voice to leave the iPhone.
- Remove a key in Settings at any time. From then on nothing goes to that provider.
- Delete the app to remove the texts, recordings, settings and models it stored on the iPhone. iOS can keep Keychain entries after an app is deleted, so tap "Remove key" first if you want the keys gone too.
- For data that a provider holds in your account there, use that provider's own tools or contact them. I cannot see, export or delete it, because I never have it.

## Children

The app is not directed at children. It collects no personal data from anyone, children included. The cloud providers have their own minimum age rules for accounts.

## Changes

If this policy changes, the new text and its date will be in this file. The full history is public: https://github.com/yadaniyil/open-dictation/commits/main/PRIVACY.md

## Contact

Questions about privacy: open an issue at https://github.com/yadaniyil/open-dictation/issues. Issues are public, so do not put private details there.
