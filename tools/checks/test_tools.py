"""Check validation boundaries and Godot log failures without running the editor."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import check_data
import verify


class ToolTests(unittest.TestCase):
    def test_gameplay_data_requires_a_schema_and_rejects_invalid_values(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = root / "our-game/farming/data/crops.json"
            data.parent.mkdir(parents=True)
            data.write_text('{"cost": 2}', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Missing schema"):
                check_data.validate(root)
            schema = root / "schemas/farming/crops.schema.json"
            schema.parent.mkdir(parents=True)
            schema.write_text('{"type":"object","required":["cost"],"properties":{"cost":{"type":"integer","minimum":0}}}', encoding="utf-8")
            self.assertEqual(check_data.validate(root), 1)
            data.write_text('{"cost": -1}', encoding="utf-8")
            with self.assertRaises(subprocess.CalledProcessError):
                check_data.validate(root)

    def test_zero_exit_does_not_hide_godot_errors_or_missing_marker(self) -> None:
        with tempfile.TemporaryDirectory() as directory, patch.object(verify, "ROOT", Path(directory)):
            for output in ("ERROR: broken\nDONE", "CHECK FAILED\nDONE", "incomplete"):
                def fake_run(*args, **kwargs):
                    kwargs["stdout"].write(output)
                    return subprocess.CompletedProcess(args[0], 0)
                with self.subTest(output=output), patch.object(verify.subprocess, "run", side_effect=fake_run):
                    with self.assertRaises(RuntimeError):
                        verify.run("godot", "fixture", [], "DONE")

    def test_installer_preserves_an_unknown_existing_addon(self) -> None:
        spec = importlib.util.spec_from_file_location("install_gdunit", Path(__file__).with_name("install_gdunit.py"))
        installer = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(installer)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "tools/pyproject.toml"
            config.parent.mkdir()
            config.write_text('[tool.civil-game-jam.gdunit4]\nversion="6.2.2"\nsha256="fixture"\n', encoding="utf-8")
            addon = root / "our-game/addons/gdUnit4"
            addon.mkdir(parents=True)
            local = addon / "local.txt"
            local.write_text("keep", encoding="utf-8")
            with patch.object(installer, "ROOT", root), patch.object(installer, "urlopen") as download:
                with self.assertRaisesRegex(RuntimeError, "Preserving existing addon"):
                    installer.main()
                download.assert_not_called()
            self.assertEqual(local.read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
