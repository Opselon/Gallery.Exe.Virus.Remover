import argparse
import sys
from colorama import Fore
from . import core

def main():
    """
    Main function to handle command-line arguments.
    """
    if sys.platform != "win32":
        print(Fore.RED + "This script is only compatible with Windows.")
        sys.exit(1)

    parser = argparse.ArgumentParser(
        description="Gallery-Lock: A tool to block the Gallery.exe malware.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("action", choices=["install", "remove", "status"], help="The action to perform.\n\n"
                        "install: Creates and locks the decoy files.\n"
                        "remove:  Removes the decoy files.\n"
                        "status:  Checks if the decoy files are installed.")
    args = parser.parse_args()

    if args.action == "install":
        core.install()
    elif args.action == "remove":
        core.remove()
    elif args.action == "status":
        core.check_status()

if __name__ == "__main__":
    main()
