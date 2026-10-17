"""Release packaging must reject corrupt templates, failed exports and missing runtime files."""
import hashlib
import io
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
from unittest import mock
import zipfile

import build_windows


def executable_bytes(machine: int = 0x8664) -> bytes:
    result = bytearray(128)
    result[:2] = b"MZ"
    struct.pack_into("<I", result, 60, 64)
    result[64:68] = b"PE\0\0"
    struct.pack_into("<H", result, 68, machine)
    return bytes(result)


class WindowsBuildTests(unittest.TestCase):
    def fixture_licenses(self, directory: Path) -> list[Path]:
        files = []
        for name in build_windows.LICENSE_SHA256:
            path = directory / name
            path.write_bytes(b"fixture official notice")
            files.append(path)
        digest = hashlib.sha256(b"fixture official notice").hexdigest()
        self.enterContext(mock.patch.dict(
            build_windows.LICENSE_SHA256, {path.name: digest for path in files}
        ))
        return files

    def test_package_has_runtime_and_licenses_and_rejects_missing_pack(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            exe = directory / "Game.exe"
            pack = directory / "Game.pck"
            output = directory / "Game.zip"
            exe.write_bytes(executable_bytes())
            notices = self.fixture_licenses(directory)
            with self.assertRaises(ValueError):
                build_windows.package_release(exe, pack, output, notices)
            pack.write_bytes(b"GDPC" + b"\0" * 124)
            manifest = build_windows.package_release(exe, pack, output, notices)
            with zipfile.ZipFile(output) as archive:
                self.assertEqual(set(archive.namelist()), {
                    "RewriteIt-Windows-x64/Game.exe",
                    "RewriteIt-Windows-x64/Game.pck",
                    "RewriteIt-Windows-x64/licenses/LICENSE.txt",
                    "RewriteIt-Windows-x64/licenses/COPYRIGHT.txt",
                })
                self.assertEqual(archive.read(archive.namelist()[0]), exe.read_bytes())
            self.assertEqual(len(manifest["files"]), 5)

    def test_wrong_architecture_and_invalid_pack_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            exe = directory / "Game.exe"
            pack = directory / "Game.pck"
            exe.write_bytes(executable_bytes(0x014C))
            with self.assertRaises(ValueError):
                build_windows.validate_x64_executable(exe)
            exe.write_bytes(executable_bytes())
            pack.write_bytes(b"invalid pack" + b"\0" * 128)
            with self.assertRaises(ValueError):
                build_windows.package_release(exe, pack, directory / "Game.zip", [])

    def test_release_rejects_missing_or_modified_license_notices(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            exe = directory / "Game.exe"
            pack = directory / "Game.pck"
            exe.write_bytes(executable_bytes())
            pack.write_bytes(b"GDPC" + b"\0" * 124)
            with self.assertRaises(ValueError):
                build_windows.package_release(exe, pack, directory / "Game.zip", [])
            notices = self.fixture_licenses(directory)
            notices[0].write_bytes(b"modified")
            with self.assertRaises(ValueError):
                build_windows.package_release(exe, pack, directory / "Game.zip", notices)

    def test_bad_download_digest_never_replaces_previous_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            cache = Path(temporary)
            archive = cache / build_windows.ARCHIVE_NAME
            archive.write_bytes(b"previous archive")
            with mock.patch("urllib.request.urlopen", return_value=io.BytesIO(b"bad download")):
                with self.assertRaises(ValueError):
                    build_windows.download_templates(cache)
            self.assertEqual(archive.read_bytes(), b"previous archive")
            self.assertFalse(archive.with_suffix(".tpz.part").exists())

    def test_cached_download_is_reused_only_after_digest_verification(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            cache = Path(temporary)
            archive = cache / build_windows.ARCHIVE_NAME
            archive.write_bytes(b"verified fixture")
            digest = hashlib.sha256(b"verified fixture").hexdigest()
            with mock.patch.object(build_windows, "ARCHIVE_SHA256", digest):
                with mock.patch("urllib.request.urlopen") as request:
                    self.assertEqual(build_windows.download_templates(cache), archive)
                    request.assert_not_called()

    def test_extracts_only_named_windows_files_and_rejects_wrong_version(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            archive = directory / "templates.tpz"
            with zipfile.ZipFile(archive, "w") as source:
                source.writestr("templates/version.txt", build_windows.VERSION)
                source.writestr("../../outside.txt", "must not be extracted")
                for name in build_windows.TEMPLATE_NAMES:
                    source.writestr("templates/" + name, executable_bytes())
            with mock.patch.object(build_windows, "ARCHIVE_SHA256", build_windows.sha256(archive)):
                build_windows.extract_windows_templates(archive, directory / "extracted")
            self.assertEqual(len(list((directory / "extracted").iterdir())), 5)
            self.assertFalse((directory.parent / "outside.txt").exists())
            with zipfile.ZipFile(archive, "w") as source:
                source.writestr("templates/version.txt", "4.6.1.stable")
            with mock.patch.object(build_windows, "ARCHIVE_SHA256", build_windows.sha256(archive)):
                with self.assertRaises(ValueError):
                    build_windows.extract_windows_templates(archive, directory / "wrong")

    def test_log_errors_fail_even_when_godot_exit_is_zero(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            log = Path(temporary) / "export.log"

            def fake_export(*_args, **kwargs):
                kwargs["stdout"].write("ERROR: template missing\n")
                return subprocess.CompletedProcess([], 0)

            with mock.patch("subprocess.run", side_effect=fake_export):
                with self.assertRaises(RuntimeError):
                    build_windows.run_godot(Path("godot"), ["--export-release"], log)


if __name__ == "__main__":
    unittest.main()
