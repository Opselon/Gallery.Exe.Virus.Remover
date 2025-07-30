import os
import subprocess
import sys
from colorama import Fore, Style, init

init(autoreset=True)

def run_powershell_script(script_path):
    """
    Runs a PowerShell script.
    """
    if not os.path.exists(script_path):
        print(Fore.RED + f"Error: The script '{script_path}' was not found.")
        sys.exit(1)

    try:
        subprocess.run(
            ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(Fore.RED + f"An error occurred while running the PowerShell script: {e}")
        print(Fore.RED + e.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(Fore.RED + "Error: PowerShell is not installed or not in the system's PATH.")
        sys.exit(1)

def install():
    """
    Installs the Gallery-Lock decoys.
    """
    print(Fore.CYAN + "Installing Gallery-Lock decoys...")
    run_powershell_script(os.path.join("scripts", "gallery_lock.ps1"))
    print(Fore.GREEN + "Installation complete.")

def remove():
    """
    Removes the Gallery-Lock decoys.
    """
    print(Fore.CYAN + "Removing Gallery-Lock decoys...")
    run_powershell_script(os.path.join("scripts", "remove_gallery_lock.ps1"))
    print(Fore.GREEN + "Removal complete.")

def check_status():
    """
    Checks the status of the Gallery-Lock decoys.
    """
    print(Fore.CYAN + "Checking Gallery-Lock status...")
    user_file = os.path.expandvars(r"%APPDATA%\Gallery.exe")
    system_file = r"C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"

    if os.path.exists(user_file):
        print(Fore.GREEN + "User decoy: INSTALLED")
    else:
        print(Fore.YELLOW + "User decoy: NOT INSTALLED")

    if os.path.exists(system_file):
        print(Fore.GREEN + "System decoy: INSTALLED")
    else:
        print(Fore.YELLOW + "System decoy: NOT INSTALLED")
