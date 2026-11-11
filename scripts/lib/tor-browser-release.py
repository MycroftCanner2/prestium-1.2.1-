#!/usr/bin/env python3
# Parse Tor's official stable linux-x86_64 download metadata and print shell assignments.
# Used by scripts/fetch-thirdparty.sh. Version strings are digits and dots only, so the
# printed assignments are safe to eval under set -u.
import argparse
import json
import re
import sys

VERSION_RE = re.compile(r"^[0-9]+\.[0-9]+(?:\.[0-9]+)*$")
DIST = "https://dist.torproject.org/torbrowser"


def expected_urls(version):
    binary = f"{DIST}/{version}/tor-browser-linux-x86_64-{version}.tar.xz"
    return binary, f"{binary}.asc"


def parse_release(meta=None, override_version=None):
    if override_version is not None:
        version = override_version
        if not VERSION_RE.fullmatch(version):
            raise ValueError(f"invalid PRESTIUM_TB_VERSION: {version!r}")
        binary, sig = expected_urls(version)
        return version, binary, sig
    if not isinstance(meta, dict):
        raise ValueError("release metadata is not a JSON object")
    version = meta.get("version", "")
    binary = meta.get("binary", "")
    sig = meta.get("sig", "")
    if not VERSION_RE.fullmatch(str(version)):
        raise ValueError(f"unexpected Tor Browser version in release metadata: {version!r}")
    expected_bin, expected_sig = expected_urls(version)
    if binary != expected_bin or sig != expected_sig:
        raise ValueError(
            f"Tor Browser download URLs do not match the official dist layout for {version}"
        )
    return version, binary, sig


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("metadata", nargs="?", help="Path to download-linux-x86_64.json")
    parser.add_argument("--version", help="Use this still-published version instead of metadata")
    args = parser.parse_args(argv)
    try:
        if args.version:
            version, binary, sig = parse_release(override_version=args.version)
        else:
            if not args.metadata:
                raise ValueError("metadata file or --version is required")
            with open(args.metadata, encoding="utf-8") as f:
                meta = json.load(f)
            version, binary, sig = parse_release(meta)
    except (OSError, ValueError, json.JSONDecodeError) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    tbf = f"tor-browser-linux-x86_64-{version}.tar.xz"
    print(f"TB_VERSION={version}")
    print(f"TBF={tbf}")
    print(f"TB_URL={binary}")
    print(f"TB_SIG_URL={sig}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
