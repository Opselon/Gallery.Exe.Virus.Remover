import argparse
import sys
from rich.console import Console
from . import core

console = Console()

def main():
    """
    Main function to handle command-line arguments.
    """
    if sys.platform != "win32":
        console.print("[bold red]This script is only compatible with Windows.[/bold red]")
        sys.exit(1)

    parser = argparse.ArgumentParser(
        description="[bold cyan]Gallery-Lock[/bold cyan]: A tool to block the Gallery.exe malware.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("action", choices=["install", "remove", "status"], help="The action to perform.\n\n"
                        "[bold green]install[/bold green]: Creates and locks the decoy files with a robust, multi-step process.\n"
                        "[bold yellow]remove[/bold yellow]:  Removes the decoy files with enhanced error handling.\n"
                        "[bold blue]status[/bold blue]:  Performs a detailed security audit of the decoy files.")
    args = parser.parse_args()

    if args.action == "install":
        core.install()
    elif args.action == "remove":
        core.remove()
    elif args.action == "status":
        core.check_status()

if __name__ == "__main__":
    main()
