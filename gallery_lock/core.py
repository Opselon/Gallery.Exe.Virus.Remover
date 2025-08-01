import ctypes
import os
import subprocess
import sys
from rich.console import Console

console = Console()

def is_admin():
    """
    Checks if the script is running with administrative privileges.
    """
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def run_powershell_script(script_path):
    """
    Runs a PowerShell script.
    """
    if not os.path.exists(script_path):
        console.print(f"[bold red]Error: The script '{script_path}' was not found.[/bold red]")
        sys.exit(1)

    try:
        subprocess.run(
            ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        console.print(f"[bold red]An error occurred while running the PowerShell script: {e}[/bold red]")
        console.print(f"[bold red]{e.stderr}[/bold red]")
        sys.exit(1)
    except FileNotFoundError:
        console.print("[bold red]Error: PowerShell is not installed or not in the system's PATH.[/bold red]")
        sys.exit(1)

from rich.progress import Progress

def install():
    """
    Installs the Gallery-Lock decoys.
    """
    if not is_admin():
        console.print("[bold red]This action requires administrator privileges.[/bold red]")
        sys.exit(1)
    console.print("[bold cyan]Installing Gallery-Lock decoys...[/bold cyan]")
    with Progress() as progress:
        task = progress.add_task("[green]Installing...", total=1)
        run_powershell_script(os.path.join("scripts", "gallery_lock.ps1"))
        progress.update(task, advance=1)
    console.print("[bold green]Installation complete.[/bold green]")

def remove():
    """
    Removes the Gallery-Lock decoys.
    """
    if not is_admin():
        console.print("[bold red]This action requires administrator privileges.[/bold red]")
        sys.exit(1)
    console.print("[bold cyan]Removing Gallery-Lock decoys...[/bold cyan]")
    with Progress() as progress:
        task = progress.add_task("[green]Removing...", total=1)
        run_powershell_script(os.path.join("scripts", "remove_gallery_lock.ps1"))
        progress.update(task, advance=1)
    console.print("[bold green]Removal complete.[/bold green]")

def run_powershell_check_script(script_path, file_path):
    """
    Runs a PowerShell check script and returns its standard output.
    Returns an error string if the script fails.
    """
    command = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path, "-Path", file_path]
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
            encoding='utf-8'
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return f"POWERSHELL_ERROR: {e.stderr.strip()}"
    except FileNotFoundError:
        return "PYTHON_ERROR: PowerShell is not installed or not in the system's PATH."


def check_status():
    """
    Checks the detailed security status of the Gallery-Lock decoys.
    """
    console.print("[bold cyan]Performing detailed security check of Gallery-Lock decoys...[/bold cyan]")

    paths_to_check = {
        "User Decoy": os.path.expandvars(r"%APPDATA%\Gallery.exe"),
        "System Decoy": r"C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    }

    script_path = os.path.join("scripts", "check_status.ps1")
    overall_secure = True

    for name, path in paths_to_check.items():
        console.print(f"\n[bold]--- {name} ---[/bold]")
        console.print(f"Path: {path}")

        # Ensure the check script exists before running it
        if not os.path.exists(script_path):
            console.print("Status: [bold red]ERROR[/bold red]")
            console.print(f"Details: The check script was not found at '{script_path}'")
            overall_secure = False
            continue

        status = run_powershell_check_script(script_path, path)

        if status == "SECURE":
            console.print("Status: [bold green]SECURE[/bold green]")
            console.print("Details: Decoy is correctly installed, locked, and owned by SYSTEM.")
        elif status == "NOT_FOUND":
            console.print("Status: [bold yellow]NOT INSTALLED[/bold yellow]")
            overall_secure = False
        elif status.startswith("INSECURE:"):
            reason = status.replace("INSECURE:", "").strip()
            console.print("Status: [bold red]INSECURE[/bold red]")
            console.print(f"Details: Decoy is present but misconfigured. {reason}")
            overall_secure = False
        else:
            console.print("Status: [bold red]UNKNOWN[/bold red]")
            console.print(f"Details: An unexpected error occurred. Raw output: {status}")
            overall_secure = False

    console.print("\n[bold]--- Overall Summary ---[/bold]")
    if overall_secure:
        console.print("[bold green]✅ System is fully protected by Gallery-Lock.[/bold green]")
    else:
        console.print("[bold red]⚠️ Your system is not fully protected. Please run the 'install' command.[/bold red]")
