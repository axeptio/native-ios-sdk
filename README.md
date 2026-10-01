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
    .package(url: "https://github.com/axeptio/native-ios-sdk.git", from: "1.3.0"),
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
| `getRemainingDaysForConsent(ttlDays:)` | Days before the consent expires (`async`): negative once expired, `ttlDays` (default 190) when there's none. Offline, counts from the last consent on the device. |

The vendor consents are saved on the device, so they're available before the SDK has loaded, and when it can't load (offline).

To react to changes as they happen, pass an `onConsentsUpdated` closure to `initialize` - it's called whenever the consent state on the device changes, with all the values above already up to date.

### Clearing the consent

`Axeptio.shared.clearConsentData()` forgets the user's choices on this device, `IABTCF_*` values included, and keeps `axeptioToken`. `shouldDisplayConsents` becomes `true`: `consentStatus` reports it once the SDK is initialized, and `onConsentsUpdated` and the event listeners are called. Use it for a "reset my choices" setting or on sign-out.

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
| Usage analytics | Consent-flow events (see below) with timestamp, app name and bundle id, a Safari-like user agent, the Axeptio user token, project and configuration IDs, and the vendor choices |

The Axeptio user token is a random identifier that Axeptio's backend creates for the consent record. The SDK doesn't read the advertising identifier.

**Analytics** use the same events as the WebView and Android SDKs:
- `app:open`, `app:close`
- `cookies:open`, `cookies:close`
- `cookies:consent:accept`, `cookies:consent:reject`, `cookies:consent:partial`
- `cookies:vendors:toggle:on|off` and `cookies:vendors:toggleall:on|off`
- `app:att:authorized|denied`

As in the WebView SDK:
- Events are sent only once the user has authorized App Tracking Transparency.
- Until then, only the ATT answer itself is sent; the other events wait on the device, up to 500.
- If tracking is denied, those events are deleted.

The SDK ships a privacy manifest (`PrivacyInfo.xcprivacy`) declaring product-interaction data collected for analytics, not linked to the user and not used for tracking.

## Migrating from the WebView SDK

| WebView SDK (`AxeptioSDK`) | Native SDK (this repository) |
| --- | --- |
| `clearConsent()` | `clearConsentData()` |
| `getRemainingDaysForConsent()` | `await getRemainingDaysForConsent()`: negative once expired, 190 when there's no consent (the WebView SDK returned 0) |
| `setEventListener` / `removeEventListener` | Same names, with an `AxeptioEventListener` |
| `onPopupClosedEvent` | `onPopupClosedEvent` |
| `onError` (`String`) | `onError` (`AxeptioError`) |
| Consent saved | `onConsentsUpdated`, or `consentStatus` becoming `.ready(shouldDisplayConsents: false)` |
| `onGoogleConsentModeUpdate`, `onConsentCleared`, `onConfigServed`, `onCookiesVersionChanged`, `onCMPRestored` | Not supported yet |

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
