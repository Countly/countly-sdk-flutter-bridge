#!/usr/bin/env python3
"""Fails the build when the pub.dev archive would carry files that must never ship, or would
miss files that must.

`flutter pub publish --dry-run` prints the archive as a tree and then exits non-zero for any
warning at all, including the long standing and harmless one about checked in files that a
`.gitignore` also matches. Failing on that exit code would make this gate permanent noise, so
this reads the tree instead.

Two hazards are specific to this repository. A `.pubignore` at the root disables the root
`.gitignore` for publishing outright rather than merging with it, and pub then also includes
untracked files, so anything that must not ship has to be repeated in `.pubignore`. And the
iOS SDK is a git submodule: published from a checkout where it was never initialized, the
archive carries an empty directory and every iOS build of the release fails.
"""

import re
import sys

# Top level entries the archive must not contain, with why each one matters.
FORBIDDEN = {
    "test_results": "integration test logs, megabytes of them, regenerated on every run",
    "MyApplication": "a stray local Android project that is not part of the plugin",
    ".idea": "IDE configuration",
    "build": "build output",
}

# Files that must appear somewhere in the archive, with why each one matters.
REQUIRED = {
    "Countly.m": "the vendored iOS SDK; run `dart run scripts/sync_sdk_versions.dart` first",
    "CountlyCommon.h": "the vendored iOS SDK; run `dart run scripts/sync_sdk_versions.dart` first",
    "PrivacyInfo.xcprivacy": "the privacy manifest App Store review requires",
}

# `├── name (12 KB)` or `└── name` at the top level of the printed tree.
TOP_LEVEL = re.compile(r"^[├└]── ([^\s(]+)", re.MULTILINE)

# Any entry of the printed tree, at any depth.
ANY_LEVEL = re.compile(r"[├└]── ([^\s(]+)")


def main(path):
    """Reads the dry run output at `path` and exits non-zero when the archive is wrong."""
    with open(path, encoding="utf-8", errors="replace") as handle:
        output = handle.read()

    entries = TOP_LEVEL.findall(output)
    if not entries:
        sys.exit("::error::could not read the archive tree out of the dry run output")

    print("Top level entries in the archive:")
    for entry in entries:
        print("  %s" % entry)

    failed = False
    for entry in entries:
        if entry in FORBIDDEN:
            print("::error file=.pubignore::%s would be published (%s). Add it to .pubignore."
                  % (entry, FORBIDDEN[entry]))
            failed = True

    all_entries = set(ANY_LEVEL.findall(output))
    for name, reason in REQUIRED.items():
        if name not in all_entries:
            print("::error::%s is missing from the archive (%s)." % (name, reason))
            failed = True

    if failed:
        sys.exit(1)

    warning = re.search(r"^Package has (\d+) warnings?\.", output, re.MULTILINE)
    if warning:
        print("\n::notice::pub reports %s validation warning(s); see the dry run output above."
              % warning.group(1))

    print("\nThe archive carries nothing from the deny list and every required file.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: check_package_contents.py <dry-run output file>")
    main(sys.argv[1])
