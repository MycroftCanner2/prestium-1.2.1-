#!/usr/bin/env python3
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from subprocess import check_output, run

HELPER = Path(__file__).resolve().parents[1] / "scripts" / "lib" / "tor-browser-release.py"


def load_helper():
    spec = importlib.util.spec_from_file_location("tor_browser_release", HELPER)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


tb = load_helper()


def meta(version="16.0.1", binary=None, sig=None, **extra):
    binary = binary or (
        f"https://dist.torproject.org/torbrowser/{version}/"
        f"tor-browser-linux-x86_64-{version}.tar.xz"
    )
    sig = sig or f"{binary}.asc"
    data = {"version": version, "binary": binary, "sig": sig}
    data.update(extra)
    return data


class TorBrowserReleaseTests(unittest.TestCase):
    def test_current_stable_layout(self):
        version, binary, sig = tb.parse_release(meta())
        self.assertEqual(version, "16.0.1")
        self.assertEqual(
            binary,
            "https://dist.torproject.org/torbrowser/16.0.1/tor-browser-linux-x86_64-16.0.1.tar.xz",
        )
        self.assertEqual(sig, binary + ".asc")

    def test_override_version(self):
        version, binary, sig = tb.parse_release(override_version="16.0.1")
        self.assertEqual(version, "16.0.1")
        self.assertTrue(binary.endswith("/16.0.1/tor-browser-linux-x86_64-16.0.1.tar.xz"))
        self.assertEqual(sig, binary + ".asc")

    def test_rejects_host_mismatch(self):
        with self.assertRaises(ValueError):
            tb.parse_release(meta(binary="https://example.invalid/tor-browser-linux-x86_64-16.0.1.tar.xz"))

    def test_rejects_version_path_mismatch(self):
        with self.assertRaises(ValueError):
            tb.parse_release(meta(version="16.0.1", binary=(
                "https://dist.torproject.org/torbrowser/16.0/"
                "tor-browser-linux-x86_64-16.0.1.tar.xz"
            )))

    def test_rejects_unsafe_version(self):
        for bad in ("latest", "16.0.1;rm", "../16.0.1", "16.0.1-alpha", ""):
            with self.subTest(bad=bad):
                with self.assertRaises(ValueError):
                    tb.parse_release(override_version=bad)
                with self.assertRaises(ValueError):
                    tb.parse_release(meta(version=bad))

    def test_cli_prints_shell_assignments(self):
        with tempfile.NamedTemporaryFile("w", suffix=".json", encoding="utf-8") as f:
            json.dump(meta(), f)
            f.flush()
            out = check_output(["python3", str(HELPER), f.name], text=True)
        self.assertIn("TB_VERSION=16.0.1\n", out)
        self.assertIn("TBF=tor-browser-linux-x86_64-16.0.1.tar.xz\n", out)

    def test_cli_rejects_bad_json(self):
        with tempfile.NamedTemporaryFile("w", suffix=".json", encoding="utf-8") as f:
            f.write("{")
            f.flush()
            proc = run(["python3", str(HELPER), f.name], capture_output=True, text=True)
        self.assertNotEqual(proc.returncode, 0)
        self.assertTrue(proc.stderr.startswith("ERROR:"))


if __name__ == "__main__":
    unittest.main()
