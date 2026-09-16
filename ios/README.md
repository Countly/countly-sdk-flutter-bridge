### The native iOS SDK

The iOS platform uses the [Countly Swift SDK](https://github.com/Countly/countly-sdk-swift)
as a Swift Package Manager dependency. It is no longer vendored as a Git submodule.

The dependency is declared in `ios/countly_flutter/Package.swift`. To change which
version is used, edit the `.package(url:...)` requirement there.

CocoaPods is not supported. The plugin ships a Swift Package Manager manifest only,
so a consuming app needs Swift Package Manager enabled:

```bash
flutter config --enable-swift-package-manager
```

An app that has not enabled it is told so by the Flutter tool rather than failing
at build time.

#### Version sync

`scripts/config/sdk_versions.txt` still records the intended iOS SDK version, and
`dart run scripts/sync_sdk_versions.dart` reports it. While `Package.swift` pins
countly-sdk-swift by branch there is nothing for the script to rewrite, so the
version there is informational until the SDK is tagged.

#### Notification service extension

An extension for rich push notifications links the `CountlyNotificationService`
library product from the Countly Swift SDK. See `example/ios/CountlyNSE/` for a
working target.
