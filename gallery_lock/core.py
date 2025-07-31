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

def check_status():
    """
    Checks the status of the Gallery-Lock decoys.
    """
    console.print("[bold cyan]Checking Gallery-Lock status...[/bold cyan]")
    user_file = os.path.expandvars(r"%APPDATA%\Gallery.exe")
    system_file = r"C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"

    if os.path.exists(user_file):
        console.print("[bold green]User decoy: INSTALLED[/bold green]")
    else:
        console.print("[bold yellow]User decoy: NOT INSTALLED[/bold yellow]")

    if os.path.exists(system_file):
        console.print("[bold green]System decoy: INSTALLED[/bold green]")
    else:
        console.print("[bold yellow]System decoy: NOT INSTALLED[/bold yellow]")
