// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "countly_flutter_np",
    platforms: [
        // The vendored iOS SDK's floor; SwiftPM rejects a package minimum above the app's target.
        .iOS(.v15)
    ],
    products: [
        // The library name replaces "_" with "-" per SwiftPM convention.
        .library(name: "countly-flutter-np", targets: ["countly_flutter_np"])
    ],
    // Flutter asks plugins to depend on the framework package it generates, which needs Flutter 3.41 or later.
    // It is added together with a Flutter 3.41 minimum in pubspec.yaml; the plugin supports Flutter 3.24 and later.
    dependencies: [],
    targets: [
        .target(
            name: "countly_flutter_np",
            dependencies: [],
            // The Countly iOS SDK is vendored as a git submodule under countly-sdk-ios/, checked out
            // with scripts/config/sparse-checkout.list so only sources, LICENSE and the privacy
            // manifest are present. Exclude the remaining non-source file plus the unused default
            // Swift plugin stub (SwiftPM does not allow Swift and Objective-C in the same target).
            exclude: [
                "SwiftCountlyFlutterPlugin.swift",
                "countly-sdk-ios/LICENSE"
            ],
            resources: [
                .process("countly-sdk-ios/PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                // Resolve the flat #import "..." statements used by the bridge and the
                // vendored Countly iOS SDK without editing every source file.
                .headerSearchPath("include/countly_flutter_np"),
                .headerSearchPath("countly-sdk-ios"),
                .headerSearchPath("."),
                .define("COUNTLY_EXCLUDE_PUSHNOTIFICATIONS")
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("WebKit"),
                .linkedFramework("CoreTelephony"),
                .linkedFramework("WatchConnectivity")
            ]
        )
    ]
)
