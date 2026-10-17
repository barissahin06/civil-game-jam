"""Build a portable Windows x64 release with verified Godot 4.6.3 templates."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = "4.6.3.stable"
ARCHIVE_NAME = "Godot_v4.6.3-stable_export_templates.tpz"
ARCHIVE_URL = (
    "https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/"
    + ARCHIVE_NAME
)
# Official godotengine/godot-builds 4.6.3-stable release asset digest.
ARCHIVE_SHA256 = "3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8"
TEMPLATE_NAMES = (
    "windows_release_x86_64.exe",
    "windows_release_x86_64_console.exe",
    "windows_debug_x86_64.exe",
    "windows_debug_x86_64_console.exe",
)
LICENSE_SHA256 = {
    "LICENSE.txt": "b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80",
    "COPYRIGHT.txt": "b3330849267d56ddd3d62a513817506606c2195034411fe05859f0140bff9d8a",
}
LICENSE_BASE_URL = "https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/"
TEMPLATE_CACHE = ROOT / "generated/tools/godot-export-templates"
BUILD_DIRECTORY = ROOT / "generated/builds/windows-x64"


def sha256(path: Path) -> str:
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def download_templates(cache: Path = TEMPLATE_CACHE) -> Path:
    cache.mkdir(parents=True, exist_ok=True)
    archive = cache / ARCHIVE_NAME
    if archive.is_file() and sha256(archive) == ARCHIVE_SHA256:
        return archive
    temporary = archive.with_suffix(".tpz.part")
    request = urllib.request.Request(ARCHIVE_URL, headers={"User-Agent": "civil-game-jam-build"})
    with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as output:
        received = 0
        report_at = 100 * 1024 * 1024
        while chunk := response.read(1024 * 1024):
            output.write(chunk)
            received += len(chunk)
            if received >= report_at:
                print(f"Templates downloaded: {received // (1024 * 1024)} MiB", flush=True)
                report_at += 100 * 1024 * 1024
    if sha256(temporary) != ARCHIVE_SHA256:
        temporary.unlink()
        raise ValueError("Godot template archive SHA-256 mismatch; export stopped")
    temporary.replace(archive)
    print("Official template archive SHA-256: PASS", flush=True)
    return archive


def extract_windows_templates(archive: Path, target: Path) -> None:
    if sha256(archive) != ARCHIVE_SHA256:
        raise ValueError("Unverified template archive")
    with zipfile.ZipFile(archive) as source:
        version = source.read("templates/version.txt").decode("utf-8").strip()
        if version != VERSION:
            raise ValueError(f"Template version mismatch: {version}")
        target.mkdir(parents=True, exist_ok=True)
        for name in TEMPLATE_NAMES:
            with source.open("templates/" + name) as member, (target / name).open("wb") as output:
                shutil.copyfileobj(member, output)
            validate_x64_executable(target / name)
        (target / "version.txt").write_text(version + "\n", encoding="utf-8", newline="\n")


def validate_x64_executable(path: Path) -> None:
    with path.open("rb") as executable:
        header = executable.read(64)
        if len(header) != 64 or header[:2] != b"MZ":
            raise ValueError(f"Missing Windows executable header: {path}")
        executable.seek(struct.unpack_from("<I", header, 60)[0])
        pe = executable.read(6)
        if len(pe) != 6 or pe[:4] != b"PE\0\0" or struct.unpack_from("<H", pe, 4)[0] != 0x8664:
            raise ValueError(f"Expected a Windows x64 executable: {path}")


def prepare_licenses(target: Path) -> list[Path]:
    target.mkdir(parents=True, exist_ok=True)
    files = []
    for name, expected in LICENSE_SHA256.items():
        path = target / name
        if not path.is_file() or sha256(path) != expected:
            with urllib.request.urlopen(LICENSE_BASE_URL + name, timeout=60) as response:
                notice = response.read()
            if hashlib.sha256(notice).hexdigest() != expected:
                raise ValueError(f"Godot license notice SHA-256 mismatch: {name}")
            path.write_bytes(notice)
        files.append(path)
    return files


def run_godot(godot: Path, arguments: list[str], log: Path) -> None:
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as output:
        result = subprocess.run(
            [str(godot), "--headless", "--path", str(ROOT / "our-game"), *arguments],
            cwd=ROOT,
            stdout=output,
            stderr=subprocess.STDOUT,
            timeout=240,
            check=False,
        )
    text = log.read_text(encoding="utf-8")
    if result.returncode or "ERROR:" in text or "CHECK FAILED" in text:
        raise RuntimeError(f"Godot build failed; see {log}")


def package_release(
    executable: Path, pack: Path, output_zip: Path, licenses: list[Path]
) -> dict[str, object]:
    validate_x64_executable(executable)
    if not pack.is_file() or pack.stat().st_size < 128:
        raise ValueError("Missing or empty exported PCK")
    with pack.open("rb") as source:
        if source.read(4) != b"GDPC":
            raise ValueError("Invalid PCK header")
    if sorted(path.name for path in licenses) != sorted(LICENSE_SHA256):
        raise ValueError("Both Godot license notices are required")
    for path in licenses:
        if not path.is_file() or sha256(path) != LICENSE_SHA256[path.name]:
            raise ValueError(f"Missing or modified Godot license notice: {path.name}")
    temporary = output_zip.with_suffix(".zip.part")
    with zipfile.ZipFile(
        temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6
    ) as archive:
        for path in (executable, pack):
            archive.write(path, arcname="RewriteIt-Windows-x64/" + path.name)
        for path in licenses:
            archive.write(path, arcname="RewriteIt-Windows-x64/licenses/" + path.name)
    with zipfile.ZipFile(temporary) as archive:
        if archive.testzip() is not None:
            raise ValueError("Portable ZIP integrity check failed")
    temporary.replace(output_zip)
    return {
        "engine_version": VERSION,
        "template_archive_sha256": ARCHIVE_SHA256,
        "license_sources": {name: LICENSE_BASE_URL + name for name in LICENSE_SHA256},
        "files": [
            {"name": path.name, "bytes": path.stat().st_size, "sha256": sha256(path)}
            for path in (executable, pack, *licenses, output_zip)
        ],
    }


def main() -> None:
    bundled = ROOT / "generated/tools/godot-standard/Godot_v4.6.3-stable_win64_console.exe"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot", type=Path,
        default=os.getenv("GODOT_PATH") or (bundled if bundled.is_file() else shutil.which("godot")),
    )
    parser.add_argument(
        "--templates-only", action="store_true",
        help="Download and verify templates without exporting",
    )
    args = parser.parse_args()
    archive = download_templates()
    extract_windows_templates(archive, TEMPLATE_CACHE / VERSION)
    if args.templates_only:
        print("WINDOWS_TEMPLATES_PASS", flush=True)
        return
    if args.godot is None:
        parser.error("Set GODOT_PATH or pass --godot")
    godot = Path(args.godot).resolve()
    version = subprocess.run(
        [str(godot), "--version"], capture_output=True, text=True, check=True, timeout=30
    ).stdout.strip()
    if not version.startswith(VERSION) or ".mono." in version:
        raise ValueError(f"Expected standard Godot {VERSION}; got {version}")
    BUILD_DIRECTORY.mkdir(parents=True, exist_ok=True)
    executable = BUILD_DIRECTORY / "RewriteIt.exe"
    pack = executable.with_suffix(".pck")
    # Stale derived outputs must never make a failed export look successful.
    for path in (executable, pack):
        path.unlink(missing_ok=True)
    run_godot(godot, ["--editor", "--import"], ROOT / "generated/reports/checks/windows-import.log")
    run_godot(
        godot, ["--export-release", "Windows Desktop", str(executable)],
        ROOT / "generated/reports/checks/windows-export.log",
    )
    licenses = prepare_licenses(BUILD_DIRECTORY / "licenses")
    manifest = package_release(
        executable, pack, BUILD_DIRECTORY.parent / "RewriteIt-Windows-x64.zip", licenses
    )
    manifest["exported_engine_version"] = version
    manifest["runtime_smoke"] = "not_run_by_packager"
    (BUILD_DIRECTORY.parent / "windows-x64-manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    print("WINDOWS_BUILD_PASS: release EXE + PCK + portable ZIP", flush=True)


if __name__ == "__main__":
    main()
