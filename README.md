# 🛡️ Gallery-Lock: The Indestructible Decoy

<p align="center">
  <strong>A "set-and-forget" PowerShell script that creates a permanent, indestructible roadblock to block the <code>Gallery.exe</code> malware and prevent reinfection.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell Version">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

---

## The Problem: The Annoying `Gallery.exe` Virus

Are you tired of removing the `Gallery.exe` malware, only for it to reappear after a restart? This common virus works by placing its executable in specific user and system folders. Even after cleaning your system, it often comes back because the original infection source (like a scheduled task or another hidden process) attempts to recreate it.

## The Solution: A Digital Fortress

**Gallery-Lock** doesn't just delete the virus; it builds a permanent fortress in its place. The script creates zero-byte (empty) decoy files named `Gallery.exe` in the exact locations the malware targets. It then applies extremely strict security permissions (ACLs) that make these decoys **impossible for the malware to overwrite or delete**.

The result? The malware's attempt to reinfect your system is blocked at the operating system level, every single time.

---
### Recommended Method: Run as SYSTEM with PsExec

This is the **most secure method** and guarantees the script can apply its strongest protections.

1.  **Download PsExec:**
    *   Download the official **Sysinternals Suite** from Microsoft: [**Download Here**](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec).
    *   Extract the ZIP file to a simple location, like `C:\Sysinternals`.

2.  **Open an Administrator Terminal:**
    *   Press `Win + X` and select **Terminal (Admin)** or **Windows PowerShell (Admin)**.

3.  **Navigate to the PsExec Folder:**
    *   In the terminal, go to the directory where you extracted PsExec.
      ```powershell
      cd C:\Sysinternals
      ```


### ⚡ Quick-Use: Single Command (from the internet)

For ultimate convenience, you can run Gallery-Lock directly from the web. Open a **SYSTEM-level PowerShell** (using the PsExec method above) and use one of the following commands.


ولی برای یک ابزار امنیتی مثل **Gallery.Exe.Virus.Remover** نسخه حرفه‌ای‌تر پیشنهاد می‌کنم این باشد:

```markdown
> [!WARNING]
> This command downloads and runs a PowerShell script from GitHub.
>
> Although the script is hosted in the official repository, always review the source code before execution.
>
> The command retrieves the latest version from the `main` branch and adds a cache-bypass parameter to prevent outdated CDN content.

*   **INSTALL / REPAIR Gallery Lock Protection**

```powershell
$url="https://raw.githubusercontent.com/Opselon/Gallery.Exe.Virus.Remover/refs/heads/main/gallery_lock.ps1?cache=$(Get-Random)"

$file="$env:TEMP\gallery_lock_latest.ps1"

Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $file

Get-FileHash $file -Algorithm SHA256

powershell.exe -ExecutionPolicy Bypass -File $file

    
### 🚨 Troubleshooting: Common Errors

#### Issue: My log is full of `FAIL: Target path is not on an NTFS drive` errors.

If your script output looks exactly like this, with repeated failures:

```
[INFO] --- Processing Target: User Profile (AppData\Roaming) ---
[ERROR] FAIL: Target path is not on an NTFS drive. ACLs cannot be applied.



... (and so on for all targets)
```

#### **Diagnosis: This log is absolute proof you are running the script in a standard Administrator PowerShell, NOT a SYSTEM-level PowerShell.**

This is the most common mistake. Even when "Run as Administrator," your PowerShell session does not have the required privileges to modify system-owned folders. The script tries to check the drive type, fails because it lacks permission, and incorrectly reports the "not on an NTFS drive" error.

#### **Solution: You MUST use PsExec.**

1.  **Close** your current PowerShell window to avoid confusion.
2.  Go back and follow the instructions in the **"How to Run This Script (The Right Way)"** section carefully.
3.  Launch a new PowerShell window using the `psexec.exe -s -i powershell.exe` command.
4.  **Confirm your identity.** Before running the decoy script, type `whoami` and press Enter. The output **must be** `nt authority\system`. If it says anything else, you are in the wrong window.
5.  Once you have confirmed you are `SYSTEM`, run the decoy script again. All errors will be resolved.


## 🚀 Key Features

| Feature | Description |
| :--- | :--- |
| ✅ **Eradicates Existing Infections** | Automatically finds and deletes any current `Gallery.exe` files from known malware locations. |
| 🛡️ **Creates Immutable Decoys** | Generates empty placeholder files and locks them down. |
| 🔒 **Advanced ACL Hardening** | Uses Access Control Lists (ACLs) to `DENY` all permissions to everyone, including Administrators. Only the core `SYSTEM` account retains control. |
| 🕵️ **Stealthy & Invisible** | Decoy files are set as `Hidden` and `System` files, making them invisible during normal use. |
| 📈 **Clear & Informative Logging** | Provides color-coded, real-time feedback in the console for every action taken. |
| 📦 **Zero Dependencies** | A standalone PowerShell script that runs on any modern Windows system without needing extra installations. |

---

## 🛠️ How to Use: The 2-Minute Guide

For maximum effectiveness, the script must be run as `SYSTEM`. This is the highest authority level on Windows, even above Administrator.

4.  **Launch a SYSTEM-Level PowerShell:**
    *   Run the following command. A new PowerShell window will open with `SYSTEM` privileges.
      ```powershell
      .\PsExec64.exe -i -s powershell.exe
      ```

5.  **Run the Gallery-Lock Script:**
    *   In the **new SYSTEM window**, navigate to where you saved `Gallery-Lock.ps1`.
    *   First, set the execution policy for this single session, then run the script.
      ```powershell
      # Allow script to run in this window only
      Set-ExecutionPolicy Bypass -Scope Process -Force
      
      # Run the script (use the correct path)
      .\Gallery-Lock.ps1
      ```

**That's it!** The decoy files are now in place and hardened. You can close all windows.

### How to Use with Python

This project includes a Python wrapper for easier use.

#### Installation

1.  **Ensure you have Python 3 installed.**
2.  **Install the required dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

#### Usage

You can use the Python wrapper to install, remove, or check the status of the Gallery-Lock decoys.

*   **Using Python directly:**
    ```bash
    python3 -m gallery_lock install
    python3 -m gallery_lock remove
    python3 -m gallery_lock status
    ```
    The `status` command performs a full security audit on the decoy files, checking not just for existence, but also for file size, ownership, and permissions to ensure they haven't been tampered with. It will report a clear `SECURE` or `INSECURE` status.

*   **Using Batch or CMD:**
    ```bash
    run.bat install
    run.cmd remove
    run.bat status
    ```

<details>
  <summary><strong>Alternative Method: Run as Administrator (Less Secure)</strong></summary>

  > [!NOTE]
  > This method works, but the file protection is not as strong because an Administrator can still take ownership more easily. It is only recommended if you cannot use PsExec.

  1. **Right-click** on the `Gallery-Lock.ps1` script file.
  2. Select **"Run with PowerShell"**.
  3. If prompted, approve the UAC (User Account Control) prompt to grant it administrator rights.

  The script will notify you that it's running as Admin and not SYSTEM.
</details>

---

## 🗺️ Protected File Locations

The script creates and protects decoys in the following standard malware paths:

| Profile Type | Path |
| :--- | :--- |
| **User Profile** | `%APPDATA%\Gallery.exe` |
| **System Profile** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 How It Works: A Technical Breakdown

The script's effectiveness comes from a multi-layered security strategy:

1.  **🔍 Scan & Clean:** It first checks for and deletes any existing `Gallery.exe` files in the target locations, ensuring a clean slate.
2.  **📝 Create the Decoy:** An empty, 0-byte file named `Gallery.exe` is created. It's harmless and takes up no space.
3.  **🛡️ Build the Fortress (ACL Hardening):** This is the most critical step. The script modifies the file's Access Control List (ACL):
    *   **Blocks Inheritance:** It stops the file from inheriting permissions from its parent folder. This isolates it from any future security changes.
    *   **Denies Everyone:** It adds an explicit `Deny FullControl` rule for the `Everyone` group. In Windows, an explicit `Deny` always overrides any `Allow` rules. This means no user, **not even an Administrator**, can write to, modify, or delete the file.
    *   **Grants SYSTEM Control:** It ensures that only the `NT AUTHORITY\SYSTEM` or `TrustedInstaller` account has `FullControl`. This is necessary for system integrity but is an account that malware (and users) cannot easily use.
4.  **👻 Go Invisible:** Finally, it sets the file attributes to `Hidden` and `System`, hiding it from standard view in File Explorer to prevent accidental discovery or tampering.

---

## ⚠️ Important Warnings & How to Undo

> [!WARNING]
> **This script creates a file that is *intentionally* difficult to remove, even for you.** Do not run this on any file you might need to access later. It is designed specifically for blocking known malware paths.

### How to Manually Remove a Locked Decoy File

If you ever need to remove the decoys, you must manually reverse the protection as an **Administrator**.

1.  **Open an Administrator Terminal** (`Win + X` > Terminal (Admin)).
2.  **Take Ownership** of the file. Replace the path with the correct one.
    *For the user file:*
    ```cmd
    takeown /f "%APPDATA%\Gallery.exe"
    ```
    *For the system file:*
    ```cmd
    takeown /f "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    ```
3.  **Reset Permissions** to inherit from the parent folder.
    *For the user file:*
    ```cmd
    icacls "%APPDATA%\Gallery.exe" /reset
    ```
    *For the system file:*
    ```cmd
    icacls "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe" /reset
    ```
4.  You can now **delete the file** normally.
    ```powershell
    Remove-Item -Path "$env:APPDATA\Gallery.exe" -Force
    ```

---

## 🔎 Troubleshooting & FAQ

| Symptom / Question | Solution / Explanation |
| :--- | :--- |
| ❌ **"Access is denied" error during script execution.** | This is expected if you are running as Administrator instead of SYSTEM. The script cannot set `SYSTEM` as the owner. **Use the PsExec method for full protection.** |
| 📜 **"Running scripts is disabled on this system." error.** | This is a PowerShell Execution Policy error. You can bypass it for the current process by running `Set-ExecutionPolicy Bypass -Scope Process -Force` before running the main script. |
| 🪟 **I can't see the `Gallery.exe` file in File Explorer.** | This is intended. The file is hidden. To view it, go to File Explorer > `View` > `Options` > `View` tab, and check **"Show hidden files..."** and uncheck **"Hide protected operating system files"**. |
| 🗑️ **I can't delete the file, even as an Admin!** | This is the script working correctly! It's designed to block everyone, including you. Follow the steps in the **[How to Undo](#️-important-warnings--how-to-undo)** section to remove it. |
| 🤔 **Why is running as `SYSTEM` so important?** | The `SYSTEM` account is the ultimate authority on Windows. By making `SYSTEM` the owner of the decoy, it prevents even an Administrator from easily modifying it without explicitly taking ownership first. Malware running with admin rights will be blocked, which is a huge security win. |

---

## 📜 License

This project is open-source and distributed under the [MIT License](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). You are free to use, share, and modify it.

---

## 🐍 SafeRemover - Python Malware Scanner

**SafeRemover.py** is a cautious, interactive Python script designed to scan for and neutralize a wider range of threats beyond just `Gallery.exe`. It uses a customizable JSON database for threat signatures and prioritizes user safety with a multi-tiered approach.

### ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🛡️ **Signature-Based Scanning** | Uses a human-readable `threat_database.json` to detect threats by filename, file size, or SHA256 hash. |
| 🕵️ **Comprehensive Scan** | Scans common malware locations, including AppData folders, Temp folders, user Startup folders, and persistence vectors like Registry Run keys and Scheduled Tasks. |
| 🚫 **Read-Only Default Mode** | The default `--scan` mode is strictly read-only and makes **no changes** to your system. It only reports what it finds. |
| ✅ **Interactive Cleaning** | The `--clean` mode requires user confirmation for **every single action**. Nothing is removed or changed automatically. |
| 📦 **Safe Quarantine** | Files are moved to a secure quarantine folder (`C:\SafeRemover\Quarantine`), not permanently deleted. |
| 📜 **Registry Backups** | Before removing a suspicious registry key, the script automatically backs up the parent key to a `.reg` file for easy restoration. |
| ✍️ **Detailed Logging** | All actions (scans, findings, user approvals, errors) are recorded in `SafeRemover_Activity.log` for a full audit trail. |

### 🛠️ How to Use

The script is run from the command line (Terminal or PowerShell).

1.  **Open a Terminal:**
    *   Open your preferred terminal (e.g., `cmd.exe`, `powershell.exe`, or Windows Terminal).
    *   Navigate to the directory where `SafeRemover.py` is located.

2.  **To Perform a Read-Only Scan:**
    *   This command will scan the system and report findings without making any changes.
    ```bash
    python SafeRemover.py --scan
    ```
    *(Note: `--scan` is the default action, so you can also just run `python SafeRemover.py`)*

3.  **To Perform an Interactive Clean:**
    *   This command requires **Administrator privileges**. Right-click your terminal application and select "Run as administrator".
    *   The script will scan for threats and then prompt you one-by-one to approve or deny each action.
    ```bash
    python SafeRemover.py --clean
    ```

### ⚙️ The Threat Database

The tool's power comes from the `threat_database.json` file. You can easily add your own threat definitions.

*   **File-based threats:**
    ```json
    {
      "name": "ExampleThreat.exe",
      "type": "file",
      "signatures": {
        "filenames": ["ExampleThreat.exe", "evil.exe"],
        "hashes": ["sha256_hash_goes_here"],
        "file_sizes": [12345]
      }
    }
    ```
*   **Registry-based threats:**
    ```json
    {
      "name": "Suspicious Run Key",
      "type": "registry",
      "signatures": {
        "value_patterns": ["C:\\Users\\.*\\AppData\\Roaming\\evil.exe"]
      }
    }
    ```
    The `value_patterns` field uses regular expressions to match suspicious paths in registry values.
