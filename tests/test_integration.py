import unittest
import os
import subprocess
import sys
import time
from gallery_lock import core

# These tests require administrator privileges to run, as they interact with
# file system permissions and system directories.

@unittest.skipIf(sys.platform != "win32", "These tests are for Windows only.")
@unittest.skipUnless(core.is_admin(), "Administrator privileges are required for these tests.")
class TestGalleryLockIntegration(unittest.TestCase):

    def setUp(self):
        """
        Ensure the environment is clean before each test.
        """
        self.user_decoy_path = os.path.expandvars(r"%APPDATA%\Gallery.exe")
        self.system_decoy_path = r"C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
        self.paths = [self.user_decoy_path, self.system_decoy_path]

        # Clean up before the test starts to ensure a clean slate.
        self.tearDown()

    def tearDown(self):
        """
        Clean up any decoy files that might be left over.
        This requires admin rights to succeed if the files are locked.
        """
        # The remove script handles the process of taking ownership and resetting ACLs.
        core.remove()

        # Double-check that the files are gone.
        for path in self.paths:
            if os.path.exists(path):
                # If the script fails, a manual cleanup might be needed.
                # This can happen if permissions are messed up beyond the script's ability to recover.
                print(f"WARNING: Decoy file still exists at {path} after teardown. Manual cleanup may be required.")

    def get_file_attributes(self, filepath):
        """
        Gets the file attributes using the 'attrib' command.
        """
        try:
            output = subprocess.check_output(["attrib", filepath], text=True, stderr=subprocess.PIPE)
            # Example output: "A  SHR      C:\Path\To\File.exe" -> parse "SH"
            attributes = output.strip().split()[1]
            return attributes
        except (subprocess.CalledProcessError, FileNotFoundError):
            return ""

    def test_install_creates_and_locks_files(self):
        """
        Tests that the 'install' command creates the decoy files,
        sets the correct attributes, and makes them undeletable.
        """
        # 1. Run the installation
        core.install()

        # 2. Verify creation, size, and attributes for both files
        for path in self.paths:
            with self.subTest(path=path):
                # Verify the file exists
                self.assertTrue(os.path.exists(path), f"Decoy file was not created at {path}")

                # Verify the file is 0 bytes
                self.assertEqual(os.path.getsize(path), 0, f"Decoy file is not 0 bytes at {path}")

                # Verify Hidden and System attributes are set
                # A small delay helps ensure file system changes are settled.
                time.sleep(0.2)
                attributes = self.get_file_attributes(path)
                self.assertIn('H', attributes, f"File at {path} is not Hidden.")
                self.assertIn('S', attributes, f"File at {path} is not System.")

                # 3. Verify the file is locked (cannot be deleted by a normal user/admin)
                with self.assertRaises(PermissionError, msg=f"File at {path} was deletable, but should be locked."):
                    os.remove(path)

    def test_remove_deletes_files(self):
        """
        Tests that the 'remove' command successfully deletes the decoy files.
        """
        # 1. First, install the decoys to ensure they exist.
        core.install()
        for path in self.paths:
            self.assertTrue(os.path.exists(path), f"Setup failed: Decoy file was not created at {path}")

        # 2. Run the removal script
        core.remove()

        # 3. Verify that the files are gone
        for path in self.paths:
            with self.subTest(path=path):
                self.assertFalse(os.path.exists(path), f"Decoy file was not removed from {path}")

    def test_install_replaces_existing_files(self):
        """
        Tests that the 'install' command replaces existing, unlocked
        files with the locked decoy files.
        """
        # 1. Create dummy files in the target locations.
        for path in self.paths:
            with self.subTest(f"create_dummy_{os.path.basename(path)}"):
                # Ensure the directory exists before creating the file
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "w") as f:
                    f.write("This is a fake Gallery.exe to be replaced.")

                # Verify it was created with content
                self.assertTrue(os.path.exists(path))
                self.assertGreater(os.path.getsize(path), 0)

        # 2. Run the installation, which should replace the dummy files
        core.install()

        # 3. Verify the original files were replaced and are now locked
        for path in self.paths:
            with self.subTest(f"verify_replacement_{os.path.basename(path)}"):
                self.assertTrue(os.path.exists(path))
                # Check that it's now a 0-byte file
                self.assertEqual(os.path.getsize(path), 0)
                # Check that it's locked
                with self.assertRaises(PermissionError):
                    os.remove(path)

    def test_install_handles_locked_file(self):
        """
        Tests that the enhanced script can remove a file that is locked
        by another process (simulated by an open file handle).
        """
        # We only need to test one path since the PowerShell logic is identical for both.
        locked_path = self.user_decoy_path
        os.makedirs(os.path.dirname(locked_path), exist_ok=True)

        # Create and "lock" the file by keeping a file handle open to it.
        # This is a common way to simulate a file being in use on Windows.
        with open(locked_path, "w") as f:
            f.write("This is a fake, locked Gallery.exe")
            f.flush()

            # Sanity check: verify the file is indeed locked by us.
            # A simple os.remove should fail at this point.
            with self.assertRaises(PermissionError, msg="Setup failed: Could not create a simulated locked file."):
                os.remove(locked_path)

            # Now, run the installation. The new robust script should be able to
            # overcome this simple lock.
            core.install()

        # The 'with' block has now closed the handle.
        # The ultimate verification is that the decoy file now exists, is empty, and is locked by ACLs.
        self.assertTrue(os.path.exists(locked_path), "Decoy file was not created after defeating the lock.")
        self.assertEqual(os.path.getsize(locked_path), 0, "Decoy file should be 0 bytes.")

        # Verify the new decoy is locked by the script's ACLs
        with self.assertRaises(PermissionError, msg="The new decoy file should be locked by ACLs."):
            os.remove(locked_path)

    def test_install_creates_missing_directory(self):
        """
        Tests that the script creates the target directory if it is missing.
        """
        # We only need to test one path since the PowerShell logic is identical.
        decoy_path = self.user_decoy_path
        parent_dir = os.path.dirname(decoy_path)

        # 1. Remove the directory to simulate it being missing.
        if os.path.exists(parent_dir):
            import shutil
            shutil.rmtree(parent_dir)
        self.assertFalse(os.path.exists(parent_dir), "Setup failed: Could not remove directory.")

        # 2. Run the installer, which should recreate the directory.
        core.install()

        # 3. Verify the directory and the decoy file were created.
        self.assertTrue(os.path.exists(parent_dir), "Script did not recreate the parent directory.")
        self.assertTrue(os.path.exists(decoy_path), "Decoy file was not created in the new directory.")
        self.assertEqual(os.path.getsize(decoy_path), 0)

        # 4. Verify the new decoy is locked.
        with self.assertRaises(PermissionError, msg="Decoy file should be locked."):
            os.remove(decoy_path)

    def test_status_command_secure(self):
        """
        Tests that the 'status' command correctly reports a SECURE status.
        """
        core.install()

        from io import StringIO
        old_stdout = sys.stdout
        sys.stdout = captured_output = StringIO()
        core.check_status()
        sys.stdout = old_stdout
        output = captured_output.getvalue()

        self.assertIn("Status: [bold green]SECURE[/bold green]", output)
        self.assertIn("System is fully protected", output)

    def test_status_command_insecure_tampered_file(self):
        """
        Tests that 'status' reports an INSECURE status for a tampered file.
        """
        decoy_path = self.user_decoy_path
        os.makedirs(os.path.dirname(decoy_path), exist_ok=True)
        with open(decoy_path, "w") as f:
            f.write("This is not a 0-byte file.")

        from io import StringIO
        old_stdout = sys.stdout
        sys.stdout = captured_output = StringIO()
        core.check_status()
        sys.stdout = old_stdout
        output = captured_output.getvalue()

        self.assertIn("Status: [bold red]INSECURE[/bold red]", output)
        self.assertIn("File size is not 0 bytes", output)
        self.assertIn("not fully protected", output)

    def test_remove_script_error_handling(self):
        """
        Tests that the 'remove' script shows an error if it fails.
        """
        core.install()

        # Make the user decoy file immutable even for SYSTEM
        # This should cause the remove script's 'takeown' or 'icacls' to fail.
        # (This is an advanced ACL modification)
        psobj = subprocess.run([
            "powershell",
            "-Command",
            f'$acl = Get-Acl "{self.user_decoy_path}"; $ar = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "GenericAll", "Deny"); $acl.SetAccessRule($ar); Set-Acl "{self.user_decoy_path}" $acl'
        ], capture_output=True)
        self.assertEqual(psobj.returncode, 0, "Failed to set up the super-locked file for the test.")

        # Now, capture the output of the remove command
        from io import StringIO
        old_stdout = sys.stdout
        sys.stdout = captured_output = StringIO()

        # The python script will exit(1) on failure, so we catch that
        with self.assertRaises(SystemExit):
            core.remove()

        sys.stdout = old_stdout
        output = captured_output.getvalue()

        # Check that the PowerShell script's internal error handling was triggered
        self.assertIn("[FAIL] Failed to remove decoy", output)
        self.assertIn("Removal finished with one or more errors", output)

if __name__ == "__main__":
    unittest.main()
