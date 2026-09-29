# Axeptio iOS SDK

[![Latest release](https://img.shields.io/github/v/release/axeptio/native-ios-sdk)](https://github.com/axeptio/native-ios-sdk/releases) [![License](https://img.shields.io/badge/license-Axeptio-blue.svg)](LICENSE) [![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org) [![iOS](https://img.shields.io/badge/iOS-17%2B-blue)](https://developer.apple.com/ios/)

Collect and manage user consents natively in your iOS app. The SDK provides a complete, remotely configured consent experience - cookie consents and system permissions - in a single screen flow. Consents are stored on the device and synced with the Axeptio backend.

## Features

- **Two cookie flows** - Brands, or Publisher following the IAB TCF standard, resolved from your remote Axeptio configuration.
- **TCF compliant** - writes the TC string and all `IABTCF_*` values to `UserDefaults`, where third-party SDKs expect them.
- **System permissions** - request App Tracking Transparency, notifications, camera and more from one configurable flow.
- **Persistent syncing** - the device is the source of truth. Unsynced consents retry automatically on the next launch.
- **Consent state at hand** - check whether the flow should be shown, read the TC string and per-vendor consents, get notified when consents change.
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
    .package(url: "https://github.com/axeptio/native-ios-sdk.git", from: "1.1.0-beta.1"),
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
| `shouldDisplayConsents` | Whether the consent flow should be presented (`async`). |
| `axeptioToken` | The token identifying this user on the Axeptio backend. |
| `tcString` | The IAB TC string, also stored as `IABTCF_TCString` in `UserDefaults`. |
| `brandsVendorConsents` | Brands vendor consents, keyed by vendor name. |
| `tcfVendorConsents` | TCF vendor consents, keyed by vendor id. |

To react to changes as they happen, pass an `onConsentsUpdated` closure to `initialize` - it's called whenever the consent state on the device changes, with all the values above already up to date.

### Handling errors

The `onError` closure you pass to `initialize` receives an `AxeptioError` whenever the SDK hits a problem during any flow - missing Info.plist keys, configuration issues, network failures. Every error is also logged to the Xcode console.

## Localization

The SDK is localized in **26 languages**: English plus Bulgarian, Croatian, Czech, Danish, Dutch, Estonian, Finnish, French, German, Greek, Hungarian, Irish, Italian, Latvian, Lithuanian, Maltese, Norwegian Bokmål, Polish, Portuguese (Portugal), Romanian, Russian, Slovak, Slovenian, Spanish, and Swedish.

> **Important:** iOS only shows a framework's localization for languages your **app** also supports. iOS resolves the whole process - the SDK included - to the best match between the device language and your **app's** supported localizations. If your app isn't localized for a language, the SDK falls back to English even though the translation is bundled.

## Example App

For a complete integration - including permission requests, the consents-updated callback and reading consent values - see the example app:

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
