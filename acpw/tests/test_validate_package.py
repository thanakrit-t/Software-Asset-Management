import tempfile
import unittest
from pathlib import Path

from acpw.scripts.validate_package import REQUIRED_FILES, main, required_files_missing


class PackageCompletenessTests(unittest.TestCase):
    def test_empty_package_reports_every_required_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            missing = required_files_missing(Path(tmp))
            self.assertEqual(sorted(missing), sorted(REQUIRED_FILES))


if __name__ == "__main__":
    unittest.main()
