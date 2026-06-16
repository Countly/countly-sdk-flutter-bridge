// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "countly_flutter",
    platforms: [
        // SwiftPM mode is used by Flutter 3.44+, whose minimum iOS deployment target is 13.0.
        // The CocoaPods podspec keeps its own (lower) target for older Flutter versions.
        .iOS("13.0")
    ],
    products: [
        // The library name replaces "_" with "-" per SwiftPM convention.
        .library(name: "countly-flutter", targets: ["countly_flutter"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "countly_flutter",
            dependencies: [],
            // The Countly iOS SDK is vendored as a git submodule under countly-sdk-ios/.
            // Exclude its non-source files, plus the unused default Swift plugin stub
            // (SwiftPM does not allow Swift and Objective-C in the same target).
            exclude: [
                "SwiftCountlyFlutterPlugin.swift",
                "countly-sdk-ios/CHANGELOG.md",
                "countly-sdk-ios/README.md",
                "countly-sdk-ios/SECURITY.md",
                "countly-sdk-ios/LICENSE",
                "countly-sdk-ios/Countly.podspec",
                "countly-sdk-ios/Countly-PL.podspec",
                "countly-sdk-ios/countly_dsym_uploader.sh",
                "countly-sdk-ios/format.sh"
            ],
            resources: [
                .process("countly-sdk-ios/PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                // Resolve the flat #import "..." statements used by the bridge and the
                // vendored Countly iOS SDK without editing every source file.
                .headerSearchPath("include/countly_flutter"),
                .headerSearchPath("countly-sdk-ios"),
                .headerSearchPath(".")
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
