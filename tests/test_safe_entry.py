import json
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]

class SafeEntryTests(unittest.TestCase):
    def call(self, *args, data=None):
        return subprocess.run([sys.executable, "-B", str(ROOT / "pallette_clenser.py"), *args], input=data, text=True, capture_output=True, cwd=ROOT)
    def test_default_has_no_changes_or_clean_claim(self):
        p = self.call(); self.assertEqual(p.returncode, 0)
        j = json.loads(p.stdout); self.assertEqual(j["changes"], []); self.assertEqual(j["proposals"], [])
        self.assertIn("No inventory supplied", " ".join(j["limitations"]))
    def test_fixture_remains_review_only(self):
        p = self.call("--inventory-stdin", data=(ROOT / "audit-planner/examples/owned-fixture.json").read_text())
        self.assertEqual(p.returncode, 0); j = json.loads(p.stdout)
        self.assertEqual(j["changes"], []); self.assertTrue(j["proposals"])
        self.assertTrue(all(x["action"] == "human_review" for x in j["proposals"]))
    def test_remove_rejected(self):
        p = self.call("--remove"); self.assertEqual(p.returncode, 2)
        self.assertEqual(json.loads(p.stdout)["changes"], [])
    def test_legacy_roots_are_exact_non_dispatching_stubs(self):
        for name in ["PUPRemover-S1.ps1", "PUPRemover-Test.ps1", "build.ps1"]:
            lines = (ROOT / name).read_text().splitlines()
            self.assertEqual(len(lines), 3); self.assertTrue(lines[0].startswith("#"))
            self.assertTrue(lines[1].startswith('Write-Error "')); self.assertEqual(lines[2], "exit 2")
