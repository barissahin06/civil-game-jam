"""Validate feature data with schemas/<feature>/<relative-name>.schema.json."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
DECISION_EFFECTS = {
    "protection_earthquake", "protection_flood", "protection_fire",
    "protection_avalanche", "protection_landslide", "resilience", "evacuation",
    "rescue_efficiency", "logistics_efficiency", "repair_efficiency",
}


def validate(root: Path) -> int:
    game = root / "our-game"
    files = sorted(game.glob("*/data/**/*.json"))
    for data in files:
        feature, _, *relative = data.relative_to(game).parts
        schema = (root / "schemas" / feature).joinpath(*relative).with_suffix(".schema.json")
        if not schema.is_file():
            raise ValueError(f"Missing schema for {data}: {schema}")
        subprocess.run([
            sys.executable, "-m", "check_jsonschema", "--schemafile", str(schema), str(data),
        ], check=True, cwd=root)
    validate_references(root)
    return len(files)


def unique_ids(entries: list[dict], key: str, source: Path) -> set[str]:
    ids = [entry[key] for entry in entries]
    if len(ids) != len(set(ids)):
        raise ValueError(f"Duplicate {key} in {source}")
    return set(ids)


def validate_references(root: Path) -> None:
    game = root / "our-game"
    events_path = game / "events/data/historical/events.json"
    aftermath_path = events_path.with_name("aftermath.json")
    if aftermath_path.is_file() and not events_path.is_file():
        raise ValueError(f"Missing event catalog for {aftermath_path}")
    if events_path.is_file():
        events = json.loads(events_path.read_text(encoding="utf-8"))["events"]
        event_ids = unique_ids(events, "id", events_path)
        if aftermath_path.is_file():
            entries = json.loads(aftermath_path.read_text(encoding="utf-8"))["entries"]
            references = unique_ids(entries, "event_id", aftermath_path)
            if unknown := references - event_ids:
                raise ValueError(f"Unknown event_id in {aftermath_path}: {sorted(unknown)}")
    actions_path = game / "management/data/preventive_actions.json"
    if actions_path.is_file():
        actions = json.loads(actions_path.read_text(encoding="utf-8"))["actions"]
        unique_ids(actions, "id", actions_path)
    validate_decisions(game)


def validate_decisions(game: Path) -> None:
    path = game / "events/data/decisions.json"
    if not path.is_file():
        return
    cards = json.loads(path.read_text(encoding="utf-8"))["cards"]
    unique_ids(cards, "id", path)
    catalogs = {}
    for name, relative, collection in [
        ("events", "events/data/historical/events.json", "events"),
        ("measures", "management/data/measures.json", "measures"),
        ("areas", "regions/data/service_areas.json", "areas"),
    ]:
        source = game / relative
        if not source.is_file():
            raise ValueError(f"Missing {name} catalog for {path}")
        entries = json.loads(source.read_text(encoding="utf-8"))[collection]
        unique_ids(entries, "id", source)
        catalogs[name] = {entry["id"]: entry for entry in entries}
    used_projects = set()
    for card in cards:
        area_id = card["area_id"]
        if area_id and area_id not in catalogs["areas"]:
            raise ValueError(f"Unknown decision area_id: {area_id}")
        for event_id in card["event_ids"]:
            if event_id not in catalogs["events"]:
                raise ValueError(f"Unknown decision event_id: {event_id}")
            if area_id:
                provinces = set(catalogs["areas"][area_id]["province_ids"])
                if not provinces & set(catalogs["events"][event_id]["province_ids"]):
                    raise ValueError(f"Decision area does not own event province: {card['id']}")
        option_ids = unique_ids(card["options"], "id", path)
        if option_ids != {"full", "focused", "decline"}:
            raise ValueError(f"Invalid decision options: {card['id']}")
        for option in card["options"]:
            project_id = option["project_id"]
            if option["id"] == "decline":
                if project_id:
                    raise ValueError(f"Decline cannot start a project: {card['id']}")
                continue
            if not project_id.startswith("decision_") or project_id not in catalogs["measures"]:
                raise ValueError(f"Unknown decision project_id: {project_id}")
            if project_id in used_projects:
                raise ValueError(f"Duplicate decision project_id: {project_id}")
            used_projects.add(project_id)
            measure = catalogs["measures"][project_id]
            if (
                (measure["kind"] == "national") != (area_id == 0)
                or measure["kind"] in {"research", "awareness"}
            ):
                raise ValueError(f"Decision project scope mismatch: {project_id}")
            if (
                measure["repeatable"] or measure["year"] != 1950
                or measure["prerequisites"] or measure["cost_awareness"]
            ):
                raise ValueError(f"Decision project must be nonrepeatable and event-gated: {project_id}")
            effects = measure.get("effects", {})
            if measure["kind"] == "team":
                if effects != {"teams": 1}:
                    raise ValueError(f"Decision team must add exactly one team: {project_id}")
            elif measure["kind"] not in {"local", "national"} or set(effects) - DECISION_EFFECTS:
                raise ValueError(f"Unsupported decision project effects: {project_id}")
    expected_projects = {
        identifier for identifier in catalogs["measures"] if identifier.startswith("decision_")
    }
    if used_projects != expected_projects:
        raise ValueError(f"Unreferenced decision projects: {sorted(expected_projects - used_projects)}")


if __name__ == "__main__":
    count = validate(ROOT)
    print(f"Gameplay JSON schemas: {count} validated" if count else "No gameplay JSON yet; 0 schemas validated")
