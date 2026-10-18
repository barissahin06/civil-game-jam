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

    def test_decisions_validate_events_project_scope_and_unique_options(self) -> None:
        import copy

        path = self.root / "our-game/events/data/decisions.json"
        measures_path = self.root / "our-game/management/data/measures.json"
        self.write(self.events, {"events": [{"id": "historical-001", "province_ids": [1]}]})
        self.write(self.root / "our-game/regions/data/service_areas.json", {"areas": [{"id": 1, "province_ids": [1]}]})
        projects = [{"id": "decision_test_" + option, "kind": "local", "year": 1950, "prerequisites": [], "repeatable": False, "cost_awareness": 0} for option in ["full", "focused"]]
        self.write(measures_path, {"measures": projects})
        card = {"id": "test", "area_id": 1, "event_ids": ["historical-001"], "options": [
            {"id": "full", "project_id": "decision_test_full"},
            {"id": "focused", "project_id": "decision_test_focused"},
            {"id": "decline", "project_id": ""},
        ]}
        self.write(path, {"cards": [card]})
        check_data.validate_references(self.root)
        malformed = []
        value = copy.deepcopy(card)
        value["event_ids"] = ["historical-999"]
        malformed.append((value, "Unknown decision event_id"))
        value = copy.deepcopy(card)
        value["area_id"] = 0
        malformed.append((value, "scope mismatch"))
        value = copy.deepcopy(card)
        value["options"][1]["project_id"] = "decision_test_full"
        malformed.append((value, "Duplicate decision project_id"))
        value = copy.deepcopy(card)
        value["options"][1]["id"] = "full"
        malformed.append((value, "Duplicate id"))
        value = copy.deepcopy(card)
        value["options"][2]["project_id"] = "decision_test_full"
        malformed.append((value, "Decline cannot"))
        for value, message in malformed:
            with self.subTest(error=message):
                self.write(path, {"cards": [value]})
                with self.assertRaisesRegex(ValueError, message):
                    check_data.validate_references(self.root)

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

    def test_authored_decisions_cover_all_natural_disaster_actions_once(self) -> None:
        game = ROOT / "our-game"
        cards = json.loads((game / "events/data/decisions.json").read_text(encoding="utf-8"))["cards"]
        measures = json.loads((game / "management/data/measures.json").read_text(encoding="utf-8"))["measures"]
        aftermath = json.loads((game / "events/data/historical/aftermath.json").read_text(encoding="utf-8"))["entries"]
        source_entries = {entry["event_id"]: entry for entry in aftermath if entry["actions"] and entry["event_id"] != "historical-097"}
        covered = {event_id for card in cards for event_id in card["event_ids"]}
        self.assertEqual(len(cards), 21)
        self.assertEqual(len(covered), 20)
        self.assertEqual(covered, set(source_entries))
        projects = [measure["id"] for measure in measures if measure["id"].startswith("decision_")]
        references = [option["project_id"] for card in cards for option in card["options"] if option["project_id"]]
        self.assertEqual(len(projects), 42)
        self.assertEqual(len(set(references)), 42)
        self.assertEqual(set(projects), set(references))
        actions = [action["description"] for entry in source_entries.values() for action in entry["actions"]]
        self.assertEqual(len(actions), 25)
        for action in actions:
            with self.subTest(action=action):
                self.assertEqual(sum(action in card["historical_note"] for card in cards), 1)
        reform = [card for card in cards if "historical-041" in card["event_ids"]]
        self.assertEqual([card["id"] for card in reform], ["construction_inspection"])
        check_data.validate_references(ROOT)


if __name__ == "__main__":
    unittest.main()
