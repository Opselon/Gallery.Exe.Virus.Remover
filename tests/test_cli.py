import unittest
from unittest.mock import patch
from gallery_lock import cli

class TestCLI(unittest.TestCase):
    @patch("sys.platform", "win32")
    @patch("gallery_lock.core.install")
    def test_install_action(self, mock_install):
        with patch("sys.argv", ["gallery_lock", "install"]):
            cli.main()
            mock_install.assert_called_once()

    @patch("sys.platform", "win32")
    @patch("gallery_lock.core.remove")
    def test_remove_action(self, mock_remove):
        with patch("sys.argv", ["gallery_lock", "remove"]):
            cli.main()
            mock_remove.assert_called_once()

    @patch("sys.platform", "win32")
    @patch("gallery_lock.core.check_status")
    def test_status_action(self, mock_check_status):
        with patch("sys.argv", ["gallery_lock", "status"]):
            cli.main()
            mock_check_status.assert_called_once()

if __name__ == "__main__":
    unittest.main()
