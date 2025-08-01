import argparse
import sys
import os
import json
import hashlib
import subprocess
import re
import tempfile
import shutil
import datetime
import logging

# Platform-specific imports
try:
    import winreg
except ImportError:
    winreg = None
try:

    import ctypes
except ImportError:
    ctypes = None
try:
    import csv
except ImportError:
    csv = None

# --- Main Functions ---

def setup_logging():
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    if logger.hasHandlers():
        logger.handlers.clear()
    file_handler = logging.FileHandler("SafeRemover_Activity.log", mode='w')
    file_handler.setLevel(logging.INFO)
    file_formatter = logging.Formatter("%(asctime)s [%(levelname)s] - %(message)s")
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.WARNING)
    console_formatter = logging.Formatter('[%(levelname)s] %(message)s')
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

def load_threat_database(db_path="threat_database.json"):
    logging.info(f"Loading threat database from '{db_path}'.")
    if not os.path.exists(db_path):
        logging.error(f"Threat database '{db_path}' not found.")
        print(f"Error: Threat database '{db_path}' not found.")
        sys.exit(1)
    try:
        with open(db_path, 'r') as f:
            return json.load(f)
    except Exception as e:
        logging.error(f"Could not load or parse threat database: {e}", exc_info=True)
        print(f"Error: Could not load or parse threat database. See log for details.")
        sys.exit(1)

def get_scan_paths():
    paths = []
    temp_dir = tempfile.gettempdir()
    if temp_dir and os.path.isdir(temp_dir):
        paths.append(temp_dir)
    if os.name == 'nt':
        env_vars = ['APPDATA', 'LOCALAPPDATA', 'PROGRAMDATA']
        for var in env_vars:
            path = os.getenv(var)
            if path and os.path.isdir(path):
                paths.append(path)
        appdata = os.getenv('APPDATA')
        if appdata:
            startup_path = os.path.join(appdata, 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
            if os.path.isdir(startup_path):
                paths.append(startup_path)
    logging.info(f"Generated {len(paths)} scan paths.")
    return list(set(paths))

def get_file_hash(filepath):
    sha256_hash = hashlib.sha256()
    try:
        with open(filepath, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    except (IOError, PermissionError) as e:
        logging.warning(f"Could not read file {filepath} to hash: {e}")
        return None

def scan_filesystem(paths_to_scan, db):
    findings = []
    file_threats = [t for t in db.get('threats', []) if t.get('type') == 'file']
    if not file_threats: return findings
    all_filenames = {fn.lower() for t in file_threats for fn in t['signatures'].get('filenames', [])}
    all_hashes = {h.lower() for t in file_threats for h in t['signatures'].get('hashes', [])}
    all_sizes = {s for t in file_threats for s in t['signatures'].get('file_sizes', [])}
    for path in paths_to_scan:
        logging.info(f"Scanning directory: {path}")
        for root, _, files in os.walk(path, topdown=True):
            for filename in files:
                filepath = os.path.join(root, filename)
                match_reason = []
                try:
                    if filename.lower() in all_filenames:
                        match_reason.append(f"Filename ('{filename}')")
                    file_size = os.path.getsize(filepath)
                    if file_size in all_sizes:
                        match_reason.append(f"File size ({file_size} bytes)")
                    if match_reason and all_hashes:
                        file_hash = get_file_hash(filepath)
                        if file_hash and file_hash in all_hashes:
                            match_reason.append(f"SHA256 Hash")
                    if match_reason:
                        reason_str = ", ".join(match_reason)
                        logging.warning(f"Found suspicious file: {filepath} | Reason: {reason_str}")
                        findings.append({"type": "Suspicious File", "location": filepath, "reason": reason_str})
                except (os.error, PermissionError) as e:
                    logging.warning(f"Could not access file {filepath}: {e}")
    return findings

# --- Action Functions ---
QUARANTINE_DIR = (r"C:\SafeRemover\Quarantine" if os.name == 'nt'
                else os.path.join(os.path.expanduser("~"), "SafeRemover", "Quarantine"))

def quarantine_file(filepath):
    if not os.path.exists(filepath):
        logging.error(f"File '{filepath}' not found for quarantine.")
        return False
    try:
        os.makedirs(QUARANTINE_DIR, exist_ok=True)
        base_filename = os.path.basename(filepath)
        dest_path = os.path.join(QUARANTINE_DIR, base_filename)
        counter = 1
        while os.path.exists(dest_path):
            name, ext = os.path.splitext(base_filename)
            dest_path = os.path.join(QUARANTINE_DIR, f"{name}_{counter}{ext}")
            counter += 1
        shutil.move(filepath, dest_path)
        logging.info(f"Successfully quarantined '{filepath}' to '{dest_path}'")
        return True
    except Exception as e:
        logging.error(f"Could not quarantine file '{filepath}'.", exc_info=True)
        return False

# --- Platform-Specific Functions ---
if os.name == 'nt' and winreg:
    REGISTRY_BACKUP_DIR = r"C:\SafeRemover\RegistryBackups"

    def hkey_to_str(hkey):
        if hkey == winreg.HKEY_CURRENT_USER: return "HKCU"
        if hkey == winreg.HKEY_LOCAL_MACHINE: return "HKLM"
        return "UNKNOWN_HKEY"

    def is_admin():
        try:
            return ctypes.windll.shell32.IsUserAnAdmin() != 0
        except Exception:
            return False

    def scan_registry(db):
        findings = []
        registry_threats = [t for t in db.get('threats', []) if t.get('type') == 'registry']
        if not registry_threats: return findings
        run_keys = [
            (winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Run"),
            (winreg.HKEY_LOCAL_MACHINE, r"Software\Microsoft\Windows\CurrentVersion\Run"),
        ]
        value_patterns = [p for t in registry_threats for p in t['signatures'].get('value_patterns', [])]
        for hkey, key_path in run_keys:
            logging.info(f"Scanning registry key: {hkey_to_str(hkey)}\\{key_path}")
            try:
                for access_mask in [winreg.KEY_WOW64_64KEY, winreg.KEY_WOW64_32KEY]:
                    with winreg.OpenKey(hkey, key_path, 0, winreg.KEY_READ | access_mask) as key:
                        i = 0
                        while True:
                            try:
                                value_name, value_data, _ = winreg.EnumValue(key, i)
                                for pattern in value_patterns:
                                    if re.search(pattern, value_data, re.IGNORECASE):
                                        full_path = f"{hkey_to_str(hkey)}\\{key_path}"
                                        reason_str = f"Value data '{value_data}' matches pattern '{pattern}'"
                                        logging.warning(f"Found suspicious registry value: {full_path}\\{value_name} | Reason: {reason_str}")
                                        findings.append({
                                            "type": "Suspicious Registry Value", "hkey": hkey, "key_path": key_path,
                                            "value_name": value_name, "location": f"{full_path}\\{value_name}", "reason": reason_str
                                        })
                                i += 1
                            except OSError: break
            except FileNotFoundError: pass
            except PermissionError:
                logging.error(f"Could not scan registry key '{hkey_to_str(hkey)}\\{key_path}' due to insufficient permissions.")
        return findings

    def backup_registry_key(hkey, key_path):
        try:
            os.makedirs(REGISTRY_BACKUP_DIR, exist_ok=True)
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            sanitized_key_name = key_path.replace('\\', '_').replace('/', '_')
            backup_filename = f"backup_{sanitized_key_name}_{timestamp}.reg"
            backup_filepath = os.path.join(REGISTRY_BACKUP_DIR, backup_filename)
            full_reg_path = f"{hkey_to_str(hkey)}\\{key_path}"
            cmd = ['reg', 'export', full_reg_path, backup_filepath, '/y']
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if result.returncode == 0:
                logging.info(f"Successfully backed up registry key '{full_reg_path}' to '{backup_filepath}'")
                return True
            else:
                logging.error(f"Failed to back up registry key '{full_reg_path}'. Stderr: {result.stderr.strip()}")
                return False
        except Exception as e:
            logging.error(f"An unexpected error occurred during registry backup.", exc_info=True)
            return False

    def remove_registry_value(hkey, key_path, value_name):
        try:
            for access_mask in [winreg.KEY_WOW64_64KEY, winreg.KEY_WOW64_32KEY]:
                try:
                    with winreg.OpenKey(hkey, key_path, 0, winreg.KEY_SET_VALUE | access_mask) as key:
                        winreg.DeleteValue(key, value_name)
                        logging.info(f"Successfully removed registry value '{value_name}'")
                        return True
                except FileNotFoundError:
                    continue
            logging.error(f"Could not find registry key to remove value: {hkey_to_str(hkey)}\\{key_path}")
            return False
        except Exception as e:
            logging.error(f"An unexpected error occurred during registry value removal.", exc_info=True)
            return False

    def disable_scheduled_task(task_name):
        try:
            cmd = ['schtasks', '/change', '/tn', task_name, '/disable']
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            result = subprocess.run(cmd, capture_output=True, text=True, check=False, startupinfo=startupinfo)
            if result.returncode == 0:
                logging.info(f"Successfully disabled scheduled task: '{task_name}'")
                return True
            else:
                logging.error(f"Failed to disable scheduled task '{task_name}'. Output: {result.stderr.strip() or result.stdout.strip()}")
                return False
        except Exception as e:
            logging.error(f"An unexpected error occurred during scheduled task disabling.", exc_info=True)
            return False

    def scan_scheduled_tasks(db):
        findings = []
        file_threats = [t for t in db.get('threats', []) if t.get('type') == 'file']
        if not file_threats: return findings
        all_filenames = {fn.lower() for t in file_threats for fn in t['signatures'].get('filenames', [])}
        try:
            cmd = ['schtasks', '/query', '/fo', 'csv', '/nh']
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='ignore', startupinfo=startupinfo)
            if result.returncode != 0:
                logging.warning(f"'schtasks' query failed with return code {result.returncode}.")
                return findings
            reader = csv.reader(result.stdout.strip().split('\n'))
            for row in reader:
                if len(row) > 7:
                    task_name, task_command = row[1], row[7]
                    if not task_command or task_command == 'N/A': continue
                    try:
                        executable = task_command.strip('"').split()[0]
                        command_fname = os.path.basename(executable).lower()
                        if command_fname in all_filenames:
                            reason_str = f"Command '{task_command}' may execute suspicious file '{command_fname}'."
                            logging.warning(f"Found suspicious scheduled task: {task_name} | Reason: {reason_str}")
                            findings.append({"type": "Suspicious Scheduled Task", "location": task_name, "reason": reason_str})
                    except Exception: continue
        except (FileNotFoundError, subprocess.CalledProcessError):
            logging.error("'schtasks' command not found. Skipping scheduled task scan.")
        return findings

else:
    # Define dummy functions for non-Windows platforms to prevent NameErrors
    def is_admin(): return False
    def scan_registry(db): return []
    def backup_registry_key(hkey, key_path): return False
    def remove_registry_value(hkey, key_path, value_name): return False
    def disable_scheduled_task(task_name): return False
    def scan_scheduled_tasks(db): return []

def scan_and_report(threat_db):
    logging.info("Starting system scan.")
    all_findings = []
    all_findings.extend(scan_filesystem(get_scan_paths(), threat_db))
    all_findings.extend(scan_registry(threat_db))
    all_findings.extend(scan_scheduled_tasks(threat_db))
    logging.info(f"Scan complete. Found {len(all_findings)} potential threats.")
    print("\n--- Scan Report ---")
    if all_findings:
        print(f"Found {len(all_findings)} potential threat(s):")
        for i, finding in enumerate(all_findings, 1):
            print(f"\n[{i}] Type:     {finding['type']}\n    Location: {finding['location']}\n    Reason:   {finding['reason']}")
    else:
        print("No potential threats found.")
    print("-------------------")
    return all_findings

def prompt_for_action(finding):
    print("\n----------------------------------------")
    print(f"Potential Threat Found:")
    print(f"  Type:     {finding['type']}\n  Location: {finding['location']}\n  Reason:   {finding['reason']}")
    print("----------------------------------------")
    while True:
        try:
            response = input(f"[?] Do you want to take action on this item? (y/n): ").lower().strip()
            if response in ['y', 'yes']:
                logging.info(f"User approved action for: {finding['location']}")
                return True
            if response in ['n', 'no']:
                logging.info(f"User denied action for: {finding['location']}")
                return False
            print("Invalid input. Please enter 'y' or 'n'.")
        except (EOFError, KeyboardInterrupt):
            logging.warning("User cancelled interactive session.")
            print("\nUser cancelled. Exiting interactive session.")
            return False

def scan_and_clean(threat_db):
    findings = scan_and_report(threat_db)
    if not findings:
        print("\nNo threats found to clean.")
        return
    print(f"\n--- Interactive Cleaning ---")
    print("You will be prompted to take action on each item.")
    actions_taken = 0
    actions_skipped = 0
    for finding in findings:
        if prompt_for_action(finding):
            actions_taken += 1
            if finding['type'] == 'Suspicious File':
                if not quarantine_file(finding['location']):
                    logging.error(f"Action FAILED for file: {finding['location']}")
            elif finding['type'] == 'Suspicious Registry Value':
                if backup_registry_key(finding['hkey'], finding['key_path']):
                    if not remove_registry_value(finding['hkey'], finding['key_path'], finding['value_name']):
                        logging.error(f"Removal FAILED for registry value: {finding['location']}")
                else:
                    logging.error(f"Backup FAILED. Aborting removal for '{finding['location']}'.")
            elif finding['type'] == 'Suspicious Scheduled Task':
                if not disable_scheduled_task(finding['location']):
                    logging.error(f"Disabling FAILED for scheduled task: {finding['location']}")
            else:
                logging.warning(f"No action defined for threat type '{finding['type']}'")
        else:
            actions_skipped += 1
    logging.info(f"Cleaning summary: {actions_taken} actions approved, {actions_skipped} actions skipped.")
    print("\n--- Cleaning Summary ---")
    print(f"Finished. {actions_taken} action(s) approved, {actions_skipped} action(s) skipped.")

def main():
    setup_logging()
    if not winreg:
        logging.warning("'winreg' module not found. Registry scanning will be disabled.")
    if not csv:
        logging.warning("'csv' module not found. Scheduled task parsing may be affected.")

    logging.info("SafeRemover session started.")
    parser = argparse.ArgumentParser(
        description="A cautious, interactive tool to scan for and neutralize specific malware threats.",
        epilog="Designed with user safety as the top priority.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('--scan', action='store_true', help='Perform a read-only scan.')
    parser.add_argument('--clean', action='store_true', help='Perform an interactive scan and clean.')
    args = parser.parse_args()
    logging.info(f"Arguments: {vars(args)}")

    if not args.clean and not args.scan:
        args.scan = True
        logging.info("Defaulting to --scan.")

    try:
        threat_db = load_threat_database()
        if not threat_db: sys.exit(1)
        if args.clean:
            logging.info("Starting --clean operation.")
            if os.name == 'nt' and not is_admin():
                logging.error("Clean operation requires administrator privileges. Aborting.")
                print("Error: The --clean operation requires administrator privileges.")
                sys.exit(1)
            scan_and_clean(threat_db)
            logging.info("Cleaning process complete.")
        elif args.scan:
            logging.info("Starting --scan operation.")
            scan_and_report(threat_db)
            logging.info("Read-only scan complete.")
    except Exception as e:
        logging.critical("An unhandled exception occurred in main.", exc_info=True)
        print(f"A critical error occurred. See SafeRemover_Activity.log for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()
