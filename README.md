<p align="center">
  <img src="https://raw.githubusercontent.com/i-am-aka/readme-assets/main/gallery-exe-ultra-lock-banner.png" alt="Gallery.exe Ultra-Lock Banner" width="600"/>
</p>

<h1 align="center">🛡️ Gallery.exe Ultra-Lock — Pro Version</h1>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg" alt="PowerShell Version">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Status-Active-brightgreen.svg" alt="Status">
</p>

<p align="center">
  A powerful PowerShell script that creates <strong>indestructible decoy files</strong> to block malware reinfection and keep your system clean.
</p>

---

## 🚀 Key Features

- **Deletes Existing Threats**: Automatically removes old `Gallery.exe` files from both user and system locations.
- **Creates Decoy Files**: Generates zero-byte decoy files in common malware target directories:
  - `%APPDATA%\Gallery.exe` (User)
  - `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` (System)
- **Advanced ACL Hardening**:
  -  DENIES all access to `Everyone` (including Administrators).
  - GRANTS full control exclusively to `SYSTEM` or `TrustedInstaller`.
  - BLOCKS inherited permissions to prevent unauthorized changes.
- **Stealthy & Invisible**: Sets files as `Hidden` and `System` attributes, making them invisible in standard File Explorer views.
- **User-Friendly Logging**: Provides clear, color-coded status updates for every action.
- **Zero Dependencies**: A standalone, open-source PowerShell script.

---

## 🛠️ How to Use

### 1. Run as SYSTEM (Recommended for Maximum Protection)

For the script to apply the most robust security settings, it needs to run with `SYSTEM` privileges. The easiest way to achieve this is by using the **PsExec** tool from the official Windows Sysinternals suite.

> **Tip:** Download [PsExec](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec) and extract it to a known location.

1. **Open an Administrator Command Prompt or PowerShell window.**
2. **Navigate to the directory where you extracted `PsExec64.exe`.**
3. **Launch a new PowerShell instance as the SYSTEM user:**

   ```cmd
   .\PsExec64.exe -i -s powershell.exe
   ```

4. **In the new SYSTEM PowerShell window, run the script:**
   *First, you may need to bypass the execution policy for the current process.*
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\CreateUnkillableGallery.ps1
   ```

---

### 📁 Protected File Locations

| Profile Type     | Path                                                                 |
|------------------|----------------------------------------------------------------------|
| **User Profile** | `%APPDATA%\Gallery.exe`                                              |
| **System Profile** | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

## 🧱 How It Works: The Security Breakdown

This script provides a permanent, set-and-forget solution to prevent the `Gallery.exe` virus from reinfecting your system.

- **Proactive Deletion**: It starts by cleaning up any existing instances of the malware.
- **Decoy Placement**: It creates harmless, empty files in the exact locations the malware tries to infect.
- **Unbreakable Permissions**: By using Access Control Lists (ACLs), it builds a digital fortress around these decoy files.
  - No user, not even an Administrator, can modify, delete, or overwrite the file.
  - Only the highest-level system accounts (`SYSTEM` or `TrustedInstaller`) have control.
- **Isolation**: By removing inherited permissions, the file's security is self-contained and cannot be weakened by changes to parent folders.
- **Invisibility**: The `Hidden` and `System` attributes ensure that the decoy files are not accidentally discovered or tampered with.

The result is a permanent roadblock. Any future attempt by malware to create or modify `Gallery.exe` will be denied by the operating system at a fundamental level.

---

## ⚠️ Important Warnings

- **For Decoy Files Only!** Do not use this script on critical system files or applications. It is designed specifically for blocking malware with known filenames.
- **Admin Lockout**: Administrators cannot delete or modify these files without manually taking ownership and resetting permissions first.

### To Remove or Edit a Locked File

If you ever need to remove the decoy files, you must perform these steps as an Administrator:

1.  **Take Ownership of the file:**
    ```cmd
    takeown /f "C:\Path\To\Your\Gallery.exe"
    ```
2.  **Reset the file's permissions to inherit from the parent folder:**
    ```cmd
    icacls "C:\Path\To\Your\Gallery.exe" /reset
    ```

---

## 💣 Optional: Extreme Hardening

For an even higher level of protection, you can lock the file in memory. This creates an open handle to the file, which can prevent even some SYSTEM-level processes from deleting it.

Execute this in a PowerShell window that will remain open:
```powershell
$fs = [System.IO.File]::Open("$env:APPDATA\Gallery.exe", 'Open', 'Read', 'Read')
```
**Note:** This lock is temporary and only lasts as long as the PowerShell session is active.

---

## 🔎 Troubleshooting

| Problem                             | Solution                                                                                                   |
|-------------------------------------|------------------------------------------------------------------------------------------------------------|
| ❌ **"Access Denied" on `Set-Acl`** | This is expected if not running as SYSTEM. Use **PsExec** as described in the usage section for full access. |
| 🪟 **File doesn't appear**          | The file is hidden by default. In File Explorer, go to `View > Options > View` and select "Show hidden files, folders, and drives" and uncheck "Hide protected operating system files". |
| 💥 **Cannot delete the file**      | This is the intended behavior! To remove it, follow the steps in the **"To Remove or Edit a Locked File"** section. |

---

## 📜 License

This project is open-source and available under the [MIT License](https://github.com/i-am-aka/readme-assets/blob/main/LICENSE). Feel free to share, fork, and modify it responsibly.
