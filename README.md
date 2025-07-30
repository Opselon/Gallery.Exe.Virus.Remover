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
