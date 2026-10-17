"""Check catalog relationships and the authored-content validation boundary."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import check_data

ROOT = Path(__file__).resolve().parents[2]


class CatalogTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.events = self.root / "our-game/events/data/historical/events.json"
        self.aftermath = self.events.with_name("aftermath.json")
        self.actions = self.root / "our-game/management/data/preventive_actions.json"
        self.write(self.events, {"events": [{"id": "historical-001"}, {"id": "historical-002"}]})
        self.write(self.aftermath, {"entries": [{"event_id": "historical-001"}]})
        self.write(self.actions, {"actions": [{"id": "hazard_zoning"}]})

    def write(self, path: Path, value: dict) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value), encoding="utf-8")

    def test_sparse_references_and_optional_catalogs_are_valid(self) -> None:
        check_data.validate_references(self.root)
        self.aftermath.unlink()
        self.actions.unlink()
        check_data.validate_references(self.root)

    def test_unknown_event_and_missing_event_catalog_are_rejected(self) -> None:
        self.write(self.aftermath, {"entries": [{"event_id": "historical-999"}]})
        with self.assertRaisesRegex(ValueError, "Unknown event_id"):
            check_data.validate_references(self.root)
        self.events.unlink()
        with self.assertRaisesRegex(ValueError, "Missing event catalog"):
            check_data.validate_references(self.root)

    def test_duplicate_event_references_are_rejected(self) -> None:
        self.write(self.aftermath, {"entries": [{"event_id": "historical-001"}] * 2})
        with self.assertRaisesRegex(ValueError, "Duplicate event_id"):
            check_data.validate_references(self.root)

    def test_duplicate_catalog_ids_are_rejected(self) -> None:
        for path, collection, entry in [
            (self.events, "events", {"id": "historical-001"}),
            (self.actions, "actions", {"id": "hazard_zoning"}),
        ]:
            with self.subTest(catalog=collection):
                self.write(path, {collection: [entry, entry]})
                with self.assertRaisesRegex(ValueError, "Duplicate id"):
                    check_data.validate_references(self.root)
                self.write(path, {collection: [entry]})

    def test_aftermath_schema_rejects_missing_sources_and_unexplained_research(self) -> None:
        entry = {"event_id": "historical-001", "actions": [{
            "type": "decision", "description": "A sourced decision", "sources": ["https://example.com/source"],
        }]}
        catalog = {"format_version": 1, "note": "Authored content", "default_research_note": "No entry", "entries": [entry]}
        schema = ROOT / "schemas/events/historical/aftermath.schema.json"

        def valid() -> bool:
            self.write(self.aftermath, catalog)
            result = subprocess.run([
                sys.executable, "-m", "check_jsonschema", "--schemafile", str(schema), str(self.aftermath),
            ], capture_output=True, text=True, check=False)
            return result.returncode == 0

        self.assertTrue(valid())
        entry["actions"][0]["sources"] = []
        self.assertFalse(valid())
        entry["actions"] = []
        self.assertFalse(valid())
        entry["research_note"] = "No matching source found"
        self.assertTrue(valid())
        entry["research_sources"] = ["http://example.com/source"]
        self.assertFalse(valid())


if __name__ == "__main__":
    unittest.main()
