#!/usr/bin/env python3
"""Fails the build when the files that carry a version disagree with sdk_versions.txt.

Every version in this repository is generated from scripts/config/sdk_versions.txt by
scripts/sync_sdk_versions.dart, and there is nothing stopping a hand edit to one of the
generated files. The result is an SDK that reports one version to the server, resolves a
different native SDK, and announces a third one in the changelog, none of which any build
step notices.

The iOS SDK is vendored as a git submodule, so its version is the tag the pinned commit
belongs to, looked up on the iOS SDK's remote, which needs network access. While the plugin
bundles an unreleased iOS SDK, sdk_versions.txt names its branch instead of a tag, and the
changelog shows the unreleased placeholder until the iOS release exists.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
UNRELEASED = "XX.XX.XX"
IOS_SUBMODULE = "ios/countly_flutter/Sources/countly_flutter/countly-sdk-ios"
IOS_REMOTE = "https://github.com/Countly/countly-sdk-ios.git"


def read(relative):
    """Returns the text of a repository file, failing the build when it is missing."""
    path = ROOT / relative
    if not path.is_file():
        sys.exit("::error::%s is missing" % relative)
    return path.read_text(encoding="utf-8")


def find(pattern, relative, what):
    """Returns the first group of `pattern` in a repository file, failing the build when absent."""
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


def git(*args):
    """Runs a git command in the repository and returns its output."""
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, check=True).stdout


def pinned_ios_commit():
    """The commit the iOS SDK submodule is pinned to in the index, which is HEAD in a fresh
    checkout and includes a staged bump in a working copy."""
    listing = git("ls-files", "--stage", "--", IOS_SUBMODULE).split()
    if len(listing) < 2 or listing[0] != "160000":
        sys.exit("::error::%s is not a submodule in this tree" % IOS_SUBMODULE)
    return listing[1]


def ios_tag_commit(tag):
    """The commit an iOS SDK tag points to on the remote, peeled through annotated tags."""
    output = git("ls-remote", "--tags", IOS_REMOTE, "refs/tags/%s" % tag, "refs/tags/%s^{}" % tag)
    commits = {}
    for line in output.splitlines():
        commit, ref = line.split("\t")
        commits[ref] = commit
    return commits.get("refs/tags/%s^{}" % tag) or commits.get("refs/tags/%s" % tag)


def ios_branch_commit(branch):
    """The commit an iOS SDK branch points to on the remote, or None when there is no such branch."""
    fields = git("ls-remote", "--heads", IOS_REMOTE, "refs/heads/%s" % branch).split()
    return fields[0] if fields else None


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


def versions(*specs):
    """Maps each file of the (file, pattern, description) specs to the version it carries."""
    return {relative: find(pattern, relative, what) for relative, pattern, what in specs}


PLUGIN_VERSION = r"^version:\s*(\S+)"
PODSPEC_VERSION = r"s\.version\s*=\s*'([^']+)'"
ANDROID_DEPENDENCY = r"implementation 'ly\.count\.android:sdk:([^']+)'"


def changelog_version(platform):
    """The pattern for the underlying SDK version line of [platform] in the changelog."""
    return r"^\* Underlying %s SDK version is (\S+)" % platform


def main():
    """Compares every versioned file with sdk_versions.txt and fails on the first mismatch set."""
    declared = declared_versions()
    failures = {}

    failures.update(check("Plugin version", declared["flutter_sdk_version"], versions(
        ("pubspec.yaml", PLUGIN_VERSION, "plugin version"),
        ("scripts/no-push-files/pubspec.yaml", PLUGIN_VERSION, "no-push plugin version"),
        ("ios/countly_flutter.podspec", PODSPEC_VERSION, "podspec version"),
        ("scripts/no-push-files/countly_flutter_np.podspec", PODSPEC_VERSION, "no-push podspec version"),
        ("android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java",
         r'COUNTLY_FLUTTER_SDK_VERSION_STRING\s*=\s*"([^"]+)"', "reported SDK version"),
        ("ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.m",
         r'kCountlyFlutterSDKVersion\s*=\s*@"([^"]+)"', "reported SDK version"),
        ("lib/src/web/plugin_config.dart", r"SDK_VERSION_STRING\s*=\s*'([^']+)'", "reported SDK version"),
    )))

    failures.update(check("Underlying Android SDK", declared["android_sdk_version"], versions(
        ("android/build.gradle", ANDROID_DEPENDENCY, "native SDK dependency"),
        ("scripts/no-push-files/build.gradle", ANDROID_DEPENDENCY, "native SDK dependency"),
        ("CHANGELOG.md", changelog_version("Android"), "underlying Android SDK version"),
    )))

    failures.update(check("Underlying Web SDK", declared["web_sdk_version"], versions(
        ("lib/src/web/plugin_config.dart", r"WEB_SDK_VERSION\s*=\s*'([^']+)'", "native SDK version"),
        ("example/web/countly_sw.js", r"countly-sdk-web@([^/]+)/lib/countly_sw\.js", "service worker import"),
        ("CHANGELOG.md", changelog_version("Web"), "underlying Web SDK version"),
    )))

    ios_version = declared["ios_sdk_version"]
    pinned = pinned_ios_commit()
    tagged = ios_tag_commit(ios_version)
    expected_changelog = ios_version
    if tagged is not None:
        submodule_version = ios_version if tagged == pinned else "commit %s" % pinned[:10]
    elif ios_branch_commit(ios_version) is not None:
        submodule_version = ios_version
        expected_changelog = UNRELEASED
    else:
        submodule_version = "no tag or branch %s on the iOS SDK remote" % ios_version
    failures.update(check("Underlying iOS SDK", ios_version, {IOS_SUBMODULE: submodule_version}))
    failures.update(check("Underlying iOS SDK in the changelog", expected_changelog, {
        "CHANGELOG.md": find(changelog_version("iOS"), "CHANGELOG.md", "underlying iOS SDK version"),
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
