"""Immutable configuration boundaries, independent of CLI and filesystem I/O."""

import json
import operator
import unittest
from typing import Any, cast

from pydantic import ValidationError

from portable_pkgs.models import (
    PACKAGE_ADAPTER,
    SCHEMA_VERSION,
    FileSpec,
    PortableManifest,
)


def bundle_data() -> dict[str, Any]:
    return {
        "type": "bundle",
        "repo": "demo/tool",
        "tag": "v1.0.0",
        "bins": {"tool": "bin/{bin}"},
        "targets": {
            "linux": {
                "asset_pattern": "^tool.tar.gz$",
                "bins": {"tool": "linux/{bin}"},
                "resolved": {
                    "asset": "tool.tar.gz",
                    "sha256": "a" * 64,
                    "files": {"tool": "linux/tool"},
                },
            },
        },
    }


class ImmutableModelsTest(unittest.TestCase):
    def test_manifest_rejects_empty_asset_patterns(self) -> None:
        raw = bundle_data()
        raw["targets"]["linux"]["asset_pattern"] = ""
        with self.assertRaises(ValidationError) as caught:
            PortableManifest.model_validate(
                {"schema_version": SCHEMA_VERSION, "tools": {"tool": raw}}
            )
        self.assertEqual(
            caught.exception.errors()[0]["loc"],
            ("tools", "tool", "bundle", "targets", "linux", "asset_pattern"),
        )

    def test_validated_snapshot_owns_all_nested_mappings(self) -> None:
        raw = bundle_data()
        manifest = PortableManifest.model_validate(
            {"schema_version": SCHEMA_VERSION, "tools": {"tool": raw}}
        )
        before = manifest.model_dump(mode="json")
        raw["bins"]["tool"] = "changed"
        raw["targets"]["linux"]["bins"]["tool"] = "changed"
        raw["targets"]["linux"]["resolved"]["files"]["tool"] = "changed"
        raw["targets"].clear()
        self.assertEqual(manifest.model_dump(mode="json"), before)

        package = manifest.tools["tool"]
        self.assertNotIsInstance(package, FileSpec)
        if isinstance(package, FileSpec):
            self.fail("expected archive package")
        target = package.targets["linux"]
        assert target.resolved is not None
        for mapping in (
            manifest.tools,
            package.targets,
            package.bins,
            target.bins,
            target.resolved.files,
        ):
            with self.subTest(mapping=mapping), self.assertRaises(TypeError):
                operator.setitem(cast(Any, mapping), "new", "value")
        with self.assertRaisesRegex(ValidationError, "frozen"):
            cast(Any, package).repo = "changed/repo"

    def test_default_mappings_are_frozen_too(self) -> None:
        package = FileSpec(type="file", repo="demo/tool", bin="tool")
        manifest = PortableManifest(schema_version=SCHEMA_VERSION)
        for mapping in (package.targets, manifest.tools):
            with self.assertRaises(TypeError):
                operator.setitem(cast(Any, mapping), "new", "value")

    def test_updates_validate_without_changing_original(self) -> None:
        package = PACKAGE_ADAPTER.validate_python(bundle_data())
        before = package.model_dump(mode="json")
        updated = package.updated(tag="v2.0.0")
        self.assertIsNot(package, updated)
        self.assertEqual(updated.tag, "v2.0.0")
        self.assertEqual(package.model_dump(mode="json"), before)
        with self.assertRaisesRegex(ValidationError, "declared commands"):
            package.updated(bins={"other": "bin/other"})
        with self.assertRaises(ValidationError):
            package.updated(strip_components=-1)
        self.assertEqual(package.model_dump(mode="json"), before)

    def test_manifest_replacement_checks_ownership_and_is_persistent(self) -> None:
        manifest = PortableManifest(schema_version=SCHEMA_VERSION)
        package = PACKAGE_ADAPTER.validate_python(bundle_data())
        added = manifest.with_package("tool", package)
        self.assertFalse(manifest.tools)
        self.assertEqual(list(added.tools), ["tool"])
        with self.assertRaisesRegex(ValidationError, "owned by both"):
            added.with_package(
                "other", FileSpec(type="file", repo="demo/other", bin="tool")
            )
        removed = added.without_package("tool")
        self.assertFalse(removed.tools)
        self.assertEqual(list(added.tools), ["tool"])

    def test_immutable_models_keep_manifest_serialization_contract(self) -> None:
        data = {"schema_version": SCHEMA_VERSION, "tools": {"tool": bundle_data()}}
        manifest = PortableManifest.model_validate(data)
        dumped = manifest.model_dump(mode="json", exclude_none=True)
        self.assertIsInstance(dumped["tools"], dict)
        self.assertEqual(
            dumped["tools"]["tool"]["targets"]["linux"]["asset_pattern"],
            "^tool.tar.gz$",
        )
        self.assertEqual(
            json.loads(manifest.model_dump_json(exclude_none=True)), dumped
        )
        self.assertEqual(PortableManifest.model_validate(dumped), manifest)

    def test_old_schema_and_removed_inference_configuration_are_rejected(self) -> None:
        for changes in (
            {"schema_version": SCHEMA_VERSION - 1},
            {"targets": {}},
            {"default_targets": []},
        ):
            with self.subTest(changes=changes), self.assertRaises(ValidationError):
                PortableManifest.model_validate(
                    {"schema_version": SCHEMA_VERSION} | changes
                )


if __name__ == "__main__":
    unittest.main()
