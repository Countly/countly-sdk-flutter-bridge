#!/usr/bin/env python3
"""Fails the build when the pub.dev archive would carry files that must never ship.

`flutter pub publish --dry-run` prints the archive as a tree and then exits non-zero for any
warning at all, including the long standing and harmless one about checked in files that a
`.gitignore` also matches. Failing on that exit code would make this gate permanent noise, so
this reads the tree instead and fails only on entries that have no business on pub.dev.

The hazard is specific to this repository: a `.pubignore` at the root disables the root
`.gitignore` for publishing outright rather than merging with it, and pub then also includes
untracked files. Anything that must not ship has to be repeated in `.pubignore`, and nothing
except this check notices when it is not.
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

# `├── name (12 KB)` or `└── name` at the top level of the printed tree.
TOP_LEVEL = re.compile(r"^[├└]── ([^\s(]+)", re.MULTILINE)


def main(path):
    with open(path, encoding="utf-8", errors="replace") as handle:
        output = handle.read()

    entries = TOP_LEVEL.findall(output)
    if not entries:
        sys.exit("::error::could not read the archive tree out of the dry run output")

    print("Top level entries in the archive:")
    for entry in entries:
        print("  %s" % entry)

    found = [entry for entry in entries if entry in FORBIDDEN]
    if found:
        print()
        for entry in found:
            print("::error file=.pubignore::%s would be published (%s). Add it to .pubignore."
                  % (entry, FORBIDDEN[entry]))
        sys.exit(1)

    warning = re.search(r"^Package has (\d+) warnings?\.", output, re.MULTILINE)
    if warning:
        print("\n::notice::pub reports %s validation warning(s); see the dry run output above."
              % warning.group(1))

    print("\nThe archive carries nothing from the deny list.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: check_package_contents.py <dry-run output file>")
    main(sys.argv[1])
