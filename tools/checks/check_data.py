"""Validate feature data with schemas/<feature>/<relative-name>.schema.json."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


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


if __name__ == "__main__":
    count = validate(ROOT)
    print(f"Gameplay JSON schemas: {count} validated" if count else "No gameplay JSON yet; 0 schemas validated")
