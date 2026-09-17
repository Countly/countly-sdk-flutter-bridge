// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Flipped to true by scripts/script.py when generating the no-push flavour.
let excludePush = false

let package = Package(
    name: "countly_flutter",
    platforms: [
        // Matches the Countly Swift SDK's own floor and this plugin's podspec.
        // A package floor above the consumer's deployment target is rejected by
        // SwiftPM, so the podspec must not go below this.
        .iOS(.v15)
    ],
    products: [
        // The library name replaces "_" with "-" per SwiftPM convention.
        .library(name: "countly-flutter", targets: ["countly_flutter"])
    ],
    dependencies: [
        // Kept in step with scripts/config/sdk_versions.txt by scripts/sync_sdk_versions.dart.
        .package(url: "https://github.com/Countly/countly-sdk-swift.git", from: "26.8.0")
    ],
    targets: [
        .target(
            name: "countly_flutter",
            dependencies: [
                .product(name: "Countly", package: "countly-sdk-swift")
            ],
            // The Swift SDK ships no privacy manifest, so the plugin carries one
            // covering the required-reason APIs the SDK uses.
            resources: [.process("PrivacyInfo.xcprivacy")],
            swiftSettings: excludePush ? [.define("COUNTLY_EXCLUDE_PUSHNOTIFICATIONS")] : []
        )
    ]
)
