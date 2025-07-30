import unittest
from unittest.mock import patch, MagicMock
import sys
import subprocess
from gallery_lock import core, cli

class TestGalleryLock(unittest.TestCase):

    @patch("sys.platform", "linux")
    def test_non_windows_os(self):
        """
        Test that the script exits if the OS is not Windows.
        """
        with self.assertRaises(SystemExit) as cm:
            cli.main()
        self.assertEqual(cm.exception.code, 1)

    @patch("sys.platform", "win32")
    @patch("argparse.ArgumentParser.parse_args")
    @patch("gallery_lock.core.install")
    def test_install_action(self, mock_install, mock_parse_args):
        """
        Test that the install action calls the core.install function.
        """
        mock_parse_args.return_value = MagicMock(action="install")
        cli.main()
        mock_install.assert_called_once()

    @patch("sys.platform", "win32")
    @patch("argparse.ArgumentParser.parse_args")
    @patch("gallery_lock.core.remove")
    def test_remove_action(self, mock_remove, mock_parse_args):
        """
        Test that the remove action calls the core.remove function.
        """
        mock_parse_args.return_value = MagicMock(action="remove")
        cli.main()
        mock_remove.assert_called_once()

    @patch("sys.platform", "win32")
    @patch("argparse.ArgumentParser.parse_args")
    @patch("gallery_lock.core.check_status")
    def test_status_action(self, mock_check_status, mock_parse_args):
        """
        Test that the status action calls the core.check_status function.
        """
        mock_parse_args.return_value = MagicMock(action="status")
        cli.main()
        mock_check_status.assert_called_once()

    @patch("subprocess.run")
    @patch("os.path.exists", return_value=True)
    def test_run_powershell_script_success(self, mock_exists, mock_subprocess_run):
        """
        Test that run_powershell_script calls subprocess.run with the correct arguments.
        """
        core.run_powershell_script("test_script.ps1")
        mock_subprocess_run.assert_called_once_with(
            ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", "test_script.ps1"],
            check=True,
            capture_output=True,
            text=True,
        )

    @patch("os.path.exists", return_value=False)
    def test_run_powershell_script_not_found(self, mock_exists):
        """
        Test that run_powershell_script exits if the script is not found.
        """
        with self.assertRaises(SystemExit) as cm:
            core.run_powershell_script("test_script.ps1")
        self.assertEqual(cm.exception.code, 1)

if __name__ == "__main__":
    unittest.main()
