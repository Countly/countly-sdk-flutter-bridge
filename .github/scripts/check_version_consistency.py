#!/usr/bin/env python3
"""Fails the build when the files that carry a version disagree with sdk_versions.txt.

Every version in this repository is generated from scripts/config/sdk_versions.txt by
scripts/sync_sdk_versions.dart, and there is nothing stopping a hand edit to one of the
generated files. The result is an SDK that reports one version to the server, resolves a
different native SDK, and announces a third one in the changelog, none of which any build
step notices.

The iOS row is only checked when ios/countly_flutter/Package.swift pins the native SDK by
version. While it pins a branch the resolved version is whatever that branch's HEAD is, so
sdk_versions.txt cannot be compared against anything, which is the same rule the sync script
applies before it refuses to write.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(relative):
    path = ROOT / relative
    if not path.is_file():
        sys.exit("::error::%s is missing" % relative)
    return path.read_text(encoding="utf-8")


def find(pattern, relative, what):
    match = re.search(pattern, read(relative), re.MULTILINE)
    if not match:
        sys.exit("::error::could not find the %s in %s" % (what, relative))
    return match.group(1)


def declared_versions():
    """The versions sdk_versions.txt declares, which everything else is compared against."""
    declared = {}
    for line in read("scripts/config/sdk_versions.txt").splitlines():
        line = line.strip()
        if not line or "=" not in line:
            continue
        key, value = line.split("=", 1)
        declared[key.strip()] = value.strip()

    for key in ("flutter_sdk_version", "android_sdk_version", "ios_sdk_version", "web_sdk_version"):
        if not declared.get(key):
            sys.exit("::error::%s is missing from scripts/config/sdk_versions.txt" % key)
    return declared


def check(label, expected, found):
    """Reports one group, and returns the files that disagree with the expected version."""
    print("\n%s: expected %s" % (label, expected))
    wrong = {}
    for relative, version in found.items():
        mark = "ok  " if version == expected else "WRONG"
        print("  %-5s %-62s %s" % (mark, relative, version))
        if version != expected:
            wrong[relative] = version
    return wrong


def main():
    declared = declared_versions()
    failures = {}

    failures.update(check("Plugin version", declared["flutter_sdk_version"], {
        "pubspec.yaml": find(r"^version:\s*(\S+)", "pubspec.yaml", "plugin version"),
        "scripts/no-push-files/pubspec.yaml": find(
            r"^version:\s*(\S+)", "scripts/no-push-files/pubspec.yaml", "no-push plugin version"),
        "android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java": find(
            r'COUNTLY_FLUTTER_SDK_VERSION_STRING\s*=\s*"([^"]+)"',
            "android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java",
            "reported SDK version"),
        "ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.swift": find(
            r'kCountlyFlutterSDKVersion\s*=\s*"([^"]+)"',
            "ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.swift",
            "reported SDK version"),
        "lib/src/web/plugin_config.dart": find(
            r"SDK_VERSION_STRING\s*=\s*'([^']+)'", "lib/src/web/plugin_config.dart",
            "reported SDK version"),
    }))

    failures.update(check("Underlying Android SDK", declared["android_sdk_version"], {
        "android/build.gradle": find(
            r"implementation 'ly\.count\.android:sdk:([^']+)'", "android/build.gradle",
            "native SDK dependency"),
        "scripts/no-push-files/build.gradle": find(
            r"implementation 'ly\.count\.android:sdk:([^']+)'", "scripts/no-push-files/build.gradle",
            "native SDK dependency"),
        "CHANGELOG.md": find(
            r"^\* Underlying Android SDK version is (\S+)", "CHANGELOG.md",
            "underlying Android SDK version"),
    }))

    failures.update(check("Underlying Web SDK", declared["web_sdk_version"], {
        "lib/src/web/plugin_config.dart": find(
            r"WEB_SDK_VERSION\s*=\s*'([^']+)'", "lib/src/web/plugin_config.dart",
            "native SDK version"),
        "CHANGELOG.md": find(
            r"^\* Underlying Web SDK version is (\S+)", "CHANGELOG.md",
            "underlying Web SDK version"),
    }))

    package_swift = read("ios/countly_flutter/Package.swift")
    if re.search(r'countly-sdk-swift\.git",\s*branch:', package_swift):
        print("\nUnderlying iOS SDK: skipped, Package.swift pins countly-sdk-swift by branch,")
        print("  so the resolved version is whatever that branch's HEAD is.")
    else:
        failures.update(check("Underlying iOS SDK", declared["ios_sdk_version"], {
            "ios/countly_flutter/Package.swift": find(
                r'countly-sdk-swift\.git",\s*from:\s*"([^"]+)"',
                "ios/countly_flutter/Package.swift", "native SDK dependency"),
            "CHANGELOG.md": find(
                r"^\* Underlying iOS SDK version is (\S+)", "CHANGELOG.md",
                "underlying iOS SDK version"),
        }))

    if failures:
        print()
        for relative, version in failures.items():
            print("::error file=%s::%s carries %s, which sdk_versions.txt does not declare. "
                  "Run `dart run scripts/sync_sdk_versions.dart`." % (relative, relative, version))
        sys.exit(1)

    print("\nEvery file agrees with scripts/config/sdk_versions.txt.")


if __name__ == "__main__":
    main()
