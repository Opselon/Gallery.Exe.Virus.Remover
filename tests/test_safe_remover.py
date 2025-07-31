import unittest
from unittest.mock import patch, MagicMock
import os
import sys
import tempfile
import shutil
import json
import hashlib
import logging

# Add the root directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import SafeRemover

class TestSafeRemover(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.threat_db_path = os.path.join(self.test_dir, "threat_db.json")

        # Create a dummy threat database
        self.threat_db_content = {
            "threats": [{"type": "file", "signatures": {"filenames": ["dummy.exe"], "file_sizes": [13], "hashes": [self.get_sha256("dummy_content")]}}]
        }
        with open(self.threat_db_path, 'w') as f:
            json.dump(self.threat_db_content, f)

        # Create dummy files
        self.threat_file_path = os.path.join(self.test_dir, "dummy.exe")
        with open(self.threat_file_path, "w") as f:
            f.write("dummy_content")

        self.safe_file_path = os.path.join(self.test_dir, "safe.txt")
        with open(self.safe_file_path, "w") as f:
            f.write("safe content")

        # Mock the QUARANTINE_DIR for testing
        SafeRemover.QUARANTINE_DIR = os.path.join(self.test_dir, "Quarantine")
        self.quarantine_dir = SafeRemover.QUARANTINE_DIR


    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def get_sha256(self, text):
        return hashlib.sha256(text.encode('utf-8')).hexdigest()

    # --- Platform-Agnostic Tests ---
    def test_scan_filesystem(self):
        """Test that the filesystem scanner finds threats correctly."""
        findings = SafeRemover.scan_filesystem([self.test_dir], self.threat_db_content)
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0]['location'], self.threat_file_path)

    def test_quarantine_file(self):
        """Test that file quarantine works as expected."""
        self.assertTrue(SafeRemover.quarantine_file(self.threat_file_path))
        self.assertFalse(os.path.exists(self.threat_file_path))
        self.assertTrue(os.path.exists(os.path.join(self.quarantine_dir, "dummy.exe")))

    def test_quarantine_file_name_collision(self):
        """Test that quarantine handles filename collisions correctly."""
        os.makedirs(self.quarantine_dir)
        with open(os.path.join(self.quarantine_dir, "dummy.exe"), "w") as f:
            f.write("original")

        SafeRemover.quarantine_file(self.threat_file_path)
        self.assertTrue(os.path.exists(os.path.join(self.quarantine_dir, "dummy_1.exe")))

    # --- Windows-Specific Tests (will be skipped on non-Windows platforms) ---

    @unittest.skipUnless(os.name == 'nt', "Windows-specific test for registry backup")
    @patch('SafeRemover.subprocess.run')
    def test_backup_registry_key(self, mock_run):
        """Test the registry backup function (Windows only)."""
        mock_run.return_value.returncode = 0
        self.assertTrue(SafeRemover.backup_registry_key("HKCU", "Software\\Test"))
        mock_run.assert_called_once()

    @unittest.skipUnless(os.name == 'nt', "Windows-specific test for registry removal")
    @patch('SafeRemover.winreg.OpenKey')
    @patch('SafeRemover.winreg.DeleteValue')
    def test_remove_registry_value(self, mock_delete_value, mock_open_key):
        """Test the registry removal function (Windows only)."""
        mock_key_handle = MagicMock()
        mock_open_key.return_value.__enter__.return_value = mock_key_handle

        self.assertTrue(SafeRemover.remove_registry_value("HKEY", "Path", "ValueName"))
        mock_delete_value.assert_called_once_with(mock_key_handle, "ValueName")

    @unittest.skipUnless(os.name == 'nt', "Windows-specific test for scheduled tasks")
    @patch('SafeRemover.subprocess.run')
    def test_disable_scheduled_task(self, mock_run):
        """Test the scheduled task disabling function (Windows only)."""
        mock_run.return_value.returncode = 0
        self.assertTrue(SafeRemover.disable_scheduled_task("MyTask"))
        mock_run.assert_called_once()

if __name__ == '__main__':
    # Suppress logging output during tests
    SafeRemover.setup_logging()
    logging.getLogger().setLevel(logging.CRITICAL)
    unittest.main()
