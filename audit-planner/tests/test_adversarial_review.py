"""Independent malformed-input and contradictory-ownership regression tests.

Only in-memory synthetic dictionaries and trapped planner calls are exercised.
No legacy script or real platform inventory is imported or executed.
"""

import copy
import unittest

import test_audit_candidate as contract

fixture = contract.fixture


class AdversarialReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Reuse the import allowlist and all platform traps without inheriting
        # the other test class (which would rerun all of its test methods).
        contract.AuditSafetyTests.setUpClass.__func__(cls)

    run_audit = contract.AuditSafetyTests.run_audit
    assert_skipped = contract.AuditSafetyTests.assert_skipped

    def test_unhashable_primary_profile_reference_is_inert(self):
        for profile_id in ([], {}, ["alice"], {"id": "alice"}):
            with self.subTest(profile_id=profile_id):
                data = fixture()
                data["applications"][0]["profile_id"] = profile_id
                self.assert_skipped(data)

    def test_unhashable_unknown_app_profile_cannot_crash_valid_app_review(self):
        for profile_id in ([], {}, ["alice"], {"id": "alice"}):
            with self.subTest(profile_id=profile_id):
                data = fixture()
                data["applications"].append({
                    "app_id": "unknown-app",
                    "product_id": "unknown-product",
                    "publisher": "unknown-publisher",
                    "profile_id": profile_id,
                    "install_root": r"C:\Users\Alice\AppData\Local\Unknown",
                })
                self.assert_skipped(data)

    def test_unknown_sibling_contradicts_exclusive_root(self):
        for owners in ([], ["unknown-app"], ["app-a", "unknown-app"]):
            with self.subTest(owners=owners):
                data = fixture()
                root = data["applications"][0]["install_root"]
                sibling = root + r"\unrelated-user-data.txt"
                data["artifacts"].append({
                    "artifact_id": "unowned-sibling",
                    "kind": "file",
                    "path": sibling,
                    "resolved_path": sibling,
                    "profile_id": "alice",
                    "owner_app_ids": owners,
                    "sha256": "c" * 64,
                    "is_reparse_point": False,
                    "hardlink_count": 1,
                })
                self.assert_skipped(data)

    def test_unsupported_parent_artifact_cannot_assert_shared_root(self):
        data = fixture()
        root = data["applications"][0]["install_root"]
        data["artifacts"].append({
            "artifact_id": "shared-directory",
            "kind": "folder",
            "path": root,
            "resolved_path": root,
            "profile_id": "alice",
            "owner_app_ids": ["unknown-app"],
        })
        self.assert_skipped(data)

    def test_resolved_unknown_sibling_cannot_hide_behind_outside_path(self):
        data = fixture()
        root = data["applications"][0]["install_root"]
        data["artifacts"].append({
            "artifact_id": "alias-sibling",
            "kind": "file",
            "path": r"C:\Users\Alice\Documents\innocent.txt",
            "resolved_path": root + r"\unrelated-user-data.txt",
            "profile_id": "alice",
            "owner_app_ids": [],
        })
        self.assert_skipped(data)

    def test_unknown_outside_artifact_does_not_invalidate_precise_root(self):
        data = fixture()
        outside = r"C:\Users\Alice\Documents\ordinary-notes.txt"
        data["artifacts"].append({
            "artifact_id": "outside-notes",
            "kind": "file",
            "path": outside,
            "resolved_path": outside,
            "profile_id": "alice",
            "owner_app_ids": [],
        })
        report = self.run_audit(data)
        self.assertEqual([p["artifact_id"] for p in report["proposals"]], ["file-a"])
        self.assertEqual([s["artifact_id"] for s in report["skipped"]], ["outside-notes"])

    def test_exact_path_collision_from_unsupported_kind_still_blocks(self):
        data = fixture()
        conflicting = copy.deepcopy(data["artifacts"][0])
        conflicting.update({"artifact_id": "unknown-kind", "kind": ["file"]})
        data["artifacts"].append(conflicting)
        self.assert_skipped(data)

    def test_owner_and_evidence_plain_json_type_confusion_is_skipped(self):
        for owners in (None, {}, {"0": "app-a"}, [None], [[]], [{}], [True]):
            with self.subTest(owners=owners):
                data = fixture()
                data["artifacts"][0]["owner_app_ids"] = owners
                self.assert_skipped(data)
        for value in (None, [], ["reg-app-a"], {}, {"id": "reg-app-a"}, True):
            with self.subTest(source_id=value):
                data = fixture()
                data["applications"][0]["evidence"]["registration_source_id"] = value
                self.assert_skipped(data)


if __name__ == "__main__":
    unittest.main()
