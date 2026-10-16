"""Import Godot, run unit tests and verify the startup scene."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def run(godot: str, name: str, flags: list[str], marker: str | None = None) -> None:
    log = ROOT / "generated/reports/checks" / f"{name}.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as output:
        result = subprocess.run(
            [godot, "--path", str(ROOT / "our-game"), *flags],
            stdout=output, stderr=subprocess.STDOUT, timeout=120,
        )
    text = log.read_text(encoding="utf-8")
    if result.returncode or "ERROR:" in text or "CHECK FAILED" in text or (marker and marker not in text):
        raise RuntimeError(f"{name} failed; see {log}")
    print(f"{name}: PASS", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.getenv("GODOT_PATH") or shutil.which("godot"))
    parser.add_argument("--unit-only", action="store_true")
    args = parser.parse_args()
    if not args.godot:
        parser.error("Set GODOT_PATH or pass --godot")
    run(args.godot, "import", ["--headless", "--editor", "--import"])
    run(args.godot, "gdunit", [
        "--headless", "--script", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
        "--ignoreHeadlessMode", "-a", "res://tests/unit",
        "-rd", str(ROOT / "generated/reports/gdunit"),
    ], "Overall Summary")
    if not args.unit_only:
        run(args.godot, "startup", ["--headless", "--script", "res://tests/integration/startup.gd"], "STARTUP PASS")
    print("Verification PASS", flush=True)


if __name__ == "__main__":
    main()
