<img alt="Axeptio Native iOS SDK" src="https://github.com/user-attachments/assets/5799ac86-5d77-4a9e-9bdf-36d40881a449" width="600" height="300"/>

# Axeptio Native iOS SDK

[![Latest release](https://img.shields.io/github/v/release/axeptio/native-ios-sdk)](https://github.com/axeptio/native-ios-sdk/releases) [![License](https://img.shields.io/badge/license-Axeptio-blue.svg)](LICENSE) [![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org) [![iOS](https://img.shields.io/badge/iOS-17%2B-blue)](https://developer.apple.com/ios/)

Collect and manage user consents natively in your iOS app. The SDK provides a complete, remotely configured consent experience - cookie consents and system permissions - in a single screen flow. Consents are stored on the device and synced with the Axeptio backend.

## Features

- **Two cookie flows** - Brands, or Publisher following the IAB TCF standard, resolved from your remote Axeptio configuration.
- **TCF compliant** - writes the TC string and all `IABTCF_*` values to `UserDefaults`, where third-party SDKs expect them.
- **System permissions** - request App Tracking Transparency, notifications, camera and more from one configurable flow.
- **Persistent syncing** - the device is the source of truth. Unsynced consents retry automatically on the next launch.
- **Consent state at hand** - check whether the flow should be shown, read the TC string and per-vendor consents, get notified when consents change.
- **Google Consent Mode v2** - hands you the four consent signals to forward to Firebase Analytics, without depending on Firebase itself.
- **Events** - stream the consent status with `async`/`await`, or register an `AxeptioEventListener` as with the WebView SDK.
- **26 languages** built in.

## Requirements

- iOS 17.0 or later
- Xcode 16 or later
- Swift 5.9 or later

## Installation

### Swift Package Manager (recommended)

**In Xcode**

1. Open your project and choose **File → Add Package Dependencies…**
2. Enter the package URL:
   ```
   https://github.com/axeptio/native-ios-sdk.git
   ```
3. Pick the version rule (**Up to Next Major Version** is recommended), then click **Add Package**.
4. Add the **AxeptioSDK** product to your app target and finish.

**In a `Package.swift` manifest**

Add the package to your `dependencies`:

```swift
dependencies: [
    .package(url: "https://github.com/axeptio/native-ios-sdk.git", from: "1.4.0-beta.1"),
],
```

Then add the product to the target that needs it:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "AxeptioSDK", package: "native-ios-sdk"),
    ]
),
```

### Manual installation (XCFramework)

If you prefer not to use SPM, you can embed the prebuilt binary framework directly:

1. Get `AxeptioSDK.xcframework` from this repository (clone it, or download the repository archive).
2. In Xcode, select your project in the navigator, then your app target, and open the **General** tab.
3. Under **Frameworks, Libraries, and Embedded Content**, drag in `AxeptioSDK.xcframework`.
4. Set it to **Embed & Sign**.

## Usage

All interaction goes through the `Axeptio.shared` singleton.

### 1. Initialize

Initialize once, early in your app's lifecycle - for example in your `@main` app's `init()` or in `application(_:didFinishLaunchingWithOptions:)`. The SDK starts fetching everything the consent flow needs, so the flow can usually be presented without a loading screen:

```swift
import AxeptioSDK

let config = LocalConfigurationModel(
    projectId: "your-project-id",
    version: "1.0.0",
    authToken: "your-api-token",
    cookiesConfiguration: .flowType(.brands)
)

Task {
    await Axeptio.shared.initialize(with: config, permissions: [], onConsentsUpdated: nil) { error in
        // React however you like - log it, show an alert, retry, etc.
        print("Axeptio error:", error.localizedDescription)
    }
}
```

`initialize` returns once the data is ready - await it when you want to act right after, or fire-and-forget and present the flow immediately.

### 2. Add usage descriptions to Info.plist

The consent flow asks the user for App Tracking Transparency, so your app's Info.plist needs:

- `NSUserTrackingUsageDescription`

If you pass permissions to `initialize`, also add the usage-description key for each one - for example `NSCameraUsageDescription` for `.camera`, `NSMicrophoneUsageDescription` for `.microphone`.

Missing keys are reported through the `onError` handler and logged to the Xcode console.

### 3. Present the consent flow

Check `shouldDisplayConsents` to know whether the user needs to (re)consent, then present:

```swift
// SwiftUI - use in a .fullScreenCover modifier
.fullScreenCover(isPresented: $showConsents) {
    Axeptio.shared.makeConsentFlow(for: .all)
}

// UIKit - present modally
Axeptio.shared.presentConsentFlow(from: someViewController, for: .all)
```

The flow advances through its steps and dismisses itself when done.

### 4. Read consent values

| Property | Description |
| --- | --- |
| `isInitialized` | `true` once the SDK has finished loading its data. |
| `shouldDisplayConsents` | Whether the consent flow should be presented (`async`): no consent yet, an expired one (190 days), or a configuration with "ask for a new consent" on that changed since (a new vendor, or a new CMP version for TCF). |
| `axeptioToken` | The token identifying this user on the Axeptio backend. |
| `tcString` | The IAB TC string, also stored as `IABTCF_TCString` in `UserDefaults`. |
| `brandsVendorConsents` | Brands vendor consents, keyed by vendor name. |
| `tcfVendorConsents` | TCF vendor consents, keyed by vendor id. |
| `googleConsentMode` | The Google Consent Mode v2 signals of the stored consent (`async`), or `nil`: see [Google Consent Mode v2](#google-consent-mode-v2). |
| `getRemainingDaysForConsent(ttlDays:)` | Days before the consent expires (`async`): negative once expired, `ttlDays` (default 190) when there's none. Offline, counts from the last consent on the device. |

The vendor consents are saved on the device, so they're available before the SDK has loaded, and when it can't load (offline).

To react to changes as they happen, pass an `onConsentsUpdated` closure to `initialize` - it's called whenever the consent state on the device changes, with all the values above already up to date.

### Clearing the consent

`Axeptio.shared.clearConsentData()` forgets the user's choices on this device, `IABTCF_*` values included, and keeps `axeptioToken`. `shouldDisplayConsents` becomes `true`: `consentStatus` reports it once the SDK is initialized, and `onConsentsUpdated` and the event listeners are called - after `onGoogleConsentModeUpdate` with the four signals denied, when the loaded configuration has [Google Consent Mode](#google-consent-mode-v2) on. Use it for a "reset my choices" setting or on sign-out.

### Handling errors

The `onError` closure you pass to `initialize` receives an `AxeptioError` whenever the SDK hits a problem during any flow - missing Info.plist keys, configuration issues, network failures. Every error is also logged to the Xcode console.

### Listening to SDK events

`consentStatus` streams where the SDK stands: the current status first, then every change. The states are the same as the Android SDK's `consentStatusFlow`:

```swift
.task {
    for await status in Axeptio.shared.consentStatus {
        switch status {
        case .ready(let shouldDisplayConsents):
            showConsents = shouldDisplayConsents // first time, expired, or the configuration asks again
        case .notInitialized:
            break // initialize hasn't finished yet
        case .configFetchFailed:
            break // the error went to onError; initialize again to retry
        }
    }
}
```

To get callbacks instead, register an `AxeptioEventListener`, as with the WebView SDK. Set only the closures you need; they run on the main actor:

```swift
let listener = AxeptioEventListener()
listener.onPopupClosedEvent = { /* the consent flow went away */ }
listener.onConsentsUpdated = { /* read the new values from Axeptio.shared */ }
listener.onError = { error in /* same errors as initialize's onError */ }
listener.onGoogleConsentModeUpdate = { consent in /* see Google Consent Mode v2 */ }
Axeptio.shared.setEventListener(listener)
// Later: Axeptio.shared.removeEventListener(listener)
```

`onPopupClosedEvent` fires once per presented consent flow, when it goes away: finished, dismissed early, or swiped down. That applies whether the flow was shown with `makeConsentFlow`, `presentConsentFlow` or `RootView`.

## Network and data collected

The SDK's API requests go over HTTPS to `https://headless-api.axeptio.tech`, or `https://staging-api.axeptio.tech` when initialized with `environment: .staging`. The images shown on the consent screens (hero illustration, vendor and category icons) are downloaded separately, from whatever hosts your Axeptio configuration references.

| Purpose | What is sent |
| --- | --- |
| Configuration | Project ID, configuration ID, app version, device language |
| Consent records | The user's vendor choices, the Axeptio user token and configuration ID |
| TCF | Vendor list and TC string encoding requests (Publisher flow) |
| Usage analytics | Consent-flow events (see below) with timestamp, app name and bundle id, a WebView-like user agent built from the device model and iOS version (also the request's `User-Agent` header), the Axeptio user token, project and configuration IDs, and the vendor choices |

The Axeptio user token is a random identifier that Axeptio's backend creates for the consent record. The SDK doesn't read the advertising identifier.

**Analytics** use the same events as the WebView and Android SDKs:
- `app:open`, `app:close`
- `cookies:loaded`, right after each `app:open`, with the session metadata (SDK and app versions, configuration name, subscription, configuration load time, Google Consent Mode settings)
- `cookies:open`, `cookies:close`
- `cookies:consent:accept`, `cookies:consent:reject`, `cookies:consent:partial`
- `cookies:vendors:toggle:on|off` and `cookies:vendors:toggleall:on|off`
- `app:att:authorized|denied`

As in the WebView SDK:
- Events are sent only once the user has authorized App Tracking Transparency.
- Until then, only the ATT answer itself is sent; the other events wait on the device, up to 500.
- If tracking is denied, those events are deleted.

Every event carries the Axeptio user token. Events logged before the first token is created (first launch, offline) wait on the device and are sent with it once it exists.

Every event also describes the configuration in use (identifier, name, language, consent and display modes, deployment date) and the visitor's geolocation (country and subdivision when the configuration was resolved by geolocation, whether the fallback configuration was served, and the device language). An event logged while the configuration loads is completed once it has loaded; if it can't be loaded, the event isn't sent.

The SDK ships a privacy manifest (`PrivacyInfo.xcprivacy`) declaring product-interaction data collected for analytics, not linked to the user and not used for tracking.

### Google Consent Mode v2

When your Axeptio configuration has Google Consent Mode on, the SDK reports the user's four Consent Mode v2 signals - `analytics_storage`, `ad_storage`, `ad_user_data` and `ad_personalization` - so you can forward them to Google Analytics for Firebase. The SDK doesn't depend on Firebase: you make the `setConsent` call.

Consent Mode is on for a Brands configuration whose Consent Mode step is displayed, and for a TCF configuration that has a Consent Mode block. The signals:

- **Brands:** the consent screens show the configuration's Consent Mode step, as the web CMP does: a "Data Sharing with Google" card on the purposes screen and, in "Let me choose", a section with one switch per signal and a "?" link to Google's policy, both first or last as the back office places them. "Accept all" grants the four signals, "Refuse all" denies them, and saved choices send each switch's signal. The step's texts come from the Axeptio API: while a configuration has none, the step isn't shown, "Accept all" grants the four signals and any other choice denies them, and the SDK logs a warning. A consent saved without the step - by SDK 1.3.0 or earlier, or while its texts were missing - is asked again once the step can be shown; its signals hold until the user answers.
- **TCF:** derived from the purposes the user consented to, like Axeptio's web TCF CMP: `ad_storage` on purpose 1, `ad_user_data` on purposes 1 and 7, `ad_personalization` on purposes 3 and 4, and `analytics_storage` on purposes 1, 2, 3, 4, 6 and 9 and special feature 1. Legitimate interests grant nothing.

**1. Default to denied** in your app's `Info.plist`, so Firebase collects nothing before the user decides:

```xml
<key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE</key>
<false/>
<key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE</key>
<false/>
<key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA</key>
<false/>
<key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS</key>
<false/>
```

**2. Forward each update** from your [event listener](#listening-to-sdk-events). `GoogleConsentType` and `GoogleConsentStatus` raw values are Firebase's `ConsentType` and `ConsentStatus` ones:

```swift
listener.onGoogleConsentModeUpdate = { consent in
    var settings: [ConsentType: ConsentStatus] = [:]
    for (type, status) in consent.toMap() {
        settings[ConsentType(rawValue: type.rawValue)] = ConsentStatus(rawValue: status.rawValue)
    }
    Analytics.setConsent(settings)
}
```

`onGoogleConsentModeUpdate` runs on the main actor, only while the configuration has Consent Mode on:

- for a new choice, just before its `onConsentsUpdated` (TCF: once its `IABTCF_*` values are written);
- once per `initialize`, once the configuration is loaded: the valid stored consent's signals, else the four denied - no consent yet, an expired one, one the SDK asks again for, or a Brands consent saved by an SDK without Google Consent Mode, which has none. A Brands consent that the Consent Mode step asks again for keeps its signals until the user answers. Firebase keeps what you set across launches, and this keeps it in step with the stored consent, fail-closed;
- with the four signals denied when `clearConsentData()` clears the consent - also when none was stored: Firebase keeps the signals an earlier launch set, which the clear must withdraw.

It is never called twice in a row with the same signals: a first refusal after a launch that denied them reports nothing new. It isn't replayed to a listener set later: read the current signals with `await Axeptio.shared.googleConsentMode`, which is `nil` when no valid consent holds signals and when Consent Mode is off.

**TCF apps:** forward the signals too. With Consent Mode on, the SDK also sets `IABTCF_EnableAdvertiserConsentMode` to `1`, as the web TCF CMP does: as soon as the configuration is loaded, and removed again once a configuration has Consent Mode off. Google's Firebase documentation doesn't describe how the Analytics SDK reads a TC string; according to other CMPs' integration guides, that key lets Firebase infer the three `ad_*` signals from it, but never `analytics_storage`. Forwarding all four doesn't depend on either.

## Migrating from the WebView SDK

| WebView SDK (`AxeptioSDK`) | Native SDK (this repository) |
| --- | --- |
| `clearConsent()` | `clearConsentData()` |
| `getRemainingDaysForConsent()` | `await getRemainingDaysForConsent()`: negative once expired, 190 when there's no consent (the WebView SDK returned 0) |
| `setEventListener` / `removeEventListener` | Same names, with an `AxeptioEventListener` |
| `onPopupClosedEvent` | `onPopupClosedEvent` |
| `onError` (`String`) | `onError` (`AxeptioError`) |
| Consent saved | `onConsentsUpdated`, or `consentStatus` becoming `.ready(shouldDisplayConsents: false)` |
| `onGoogleConsentModeUpdate(GoogleConsentV2)` | `onGoogleConsentModeUpdate(GoogleConsentV2)` - same type name; `consent.toMap()` keys the signals by type. Firebase isn't called for you: see [Google Consent Mode v2](#google-consent-mode-v2) |
| `onConsentCleared`, `onConfigServed`, `onCookiesVersionChanged`, `onCMPRestored` | Not supported yet |

## Localization

The SDK is localized in **26 languages**: English plus Bulgarian, Croatian, Czech, Danish, Dutch, Estonian, Finnish, French, German, Greek, Hungarian, Irish, Italian, Latvian, Lithuanian, Maltese, Norwegian Bokmål, Polish, Portuguese (Portugal), Romanian, Russian, Slovak, Slovenian, Spanish, and Swedish.

> **Important:** iOS only shows a framework's localization for languages your **app** also supports. iOS resolves the whole process - the SDK included - to the best match between the device language and your **app's** supported localizations. If your app isn't localized for a language, the SDK falls back to English even though the translation is bundled.

## Example App

For a complete integration - including permission requests, an event log of `consentStatus` and an `AxeptioEventListener`, and reading consent values - see the example app:

1. Clone this repository:
   ```sh
   git clone https://github.com/axeptio/native-ios-sdk.git
   ```
2. Open `Example/AxeptioSDKExample/AxeptioSDKExample.xcodeproj` in Xcode.
3. Select a simulator (or your device) and press **Run** (⌘R).

The example references the SDK as a local Swift package, so Xcode resolves it automatically - no extra setup required.

## Support

For integration questions, bug reports or feature requests, contact Axeptio support at
**support@axeptio.eu** or visit the [help centre](https://support.axeptio.eu). Release notes are on the
[releases page](https://github.com/axeptio/native-ios-sdk/releases). To report a security vulnerability, see [SECURITY.md](SECURITY.md).

## License

The Axeptio iOS SDK is distributed under Axeptio's licensing terms — see [LICENSE](LICENSE).
