import tempfile
import unittest
from pathlib import Path

from acpw.scripts.validate_package import REQUIRED_FILES, main, required_files_missing


class PackageCompletenessTests(unittest.TestCase):
    def test_empty_package_reports_every_required_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            missing = required_files_missing(Path(tmp))
            self.assertEqual(sorted(missing), sorted(REQUIRED_FILES))

    def test_cli_returns_one_for_incomplete_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(main([tmp]), 1)

    def test_cli_returns_zero_for_complete_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for relative_path in REQUIRED_FILES:
                target = root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.touch()
            self.assertEqual(main([tmp]), 0)


if __name__ == "__main__":
    unittest.main()