"""Validate feature data with schemas/<feature>/<relative-name>.schema.json."""
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
    return len(files)


if __name__ == "__main__":
    count = validate(ROOT)
    print(f"Gameplay JSON schemas: {count} validated" if count else "No gameplay JSON yet; 0 schemas validated")
