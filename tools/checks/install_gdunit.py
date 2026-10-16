"""Install the checksum-pinned GdUnit4 addon without overwriting local work."""
import hashlib
import io
from pathlib import Path
import shutil
from tempfile import TemporaryDirectory
import tomllib
from urllib.request import urlopen
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[2]


def main():
    config = tomllib.loads((ROOT / "tools/pyproject.toml").read_text(encoding="utf-8"))
    package = config["tool"]["civil-game-jam"]["gdunit4"]
    version, checksum = package["version"], package["sha256"]
    target = ROOT / "our-game/addons/gdUnit4"
    marker = target / ".archive-sha256"
    if target.exists():
        if marker.is_file() and marker.read_text().strip() == checksum and (target / "plugin.cfg").is_file():
            print(f"GdUnit4 {version}: already installed")
            return
        raise RuntimeError(f"Preserving existing addon at {target}; move it aside before installing")
    url = f"https://codeload.github.com/godot-gdunit-labs/gdUnit4/zip/refs/tags/v{version}"
    with urlopen(url, timeout=60) as response:
        archive = response.read()
    if hashlib.sha256(archive).hexdigest() != checksum:
        raise ValueError("GdUnit4 archive checksum mismatch; nothing installed")
    prefix = f"gdUnit4-{version}/addons/gdUnit4/"
    with TemporaryDirectory() as directory, ZipFile(io.BytesIO(archive)) as bundle:
        staging = Path(directory).resolve()
        for member in bundle.infolist():
            if not member.filename.startswith(prefix) or member.is_dir():
                continue
            destination = (staging / member.filename[len(prefix):]).resolve()
            if not destination.is_relative_to(staging):
                raise ValueError(f"Unsafe archive path: {member.filename}")
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(bundle.read(member))
        if not (staging / "plugin.cfg").is_file() or not (staging / "LICENSE").is_file():
            raise ValueError("GdUnit4 archive is missing its plugin or license")
        (staging / ".archive-sha256").write_text(checksum + "\n", encoding="utf-8")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(staging, target)
    print(f"GdUnit4 {version}: installed at {target}")


if __name__ == "__main__":
    main()
