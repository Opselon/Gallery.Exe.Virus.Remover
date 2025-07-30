# 🛡️ Gallery.exe Lockdown Script

## Overview

This PowerShell project is designed to **neutralize a known malware vector** — `Gallery.exe` — by **preemptively creating and locking** a benign file at the targeted execution path. This technique is effective for preventing re-creation of the file by malware or unauthorized users, even with elevated privileges.

The script employs **NTFS permission hardening, ownership obfuscation**, and **access control denial** to make the file tamper-resistant and virtually unremovable under normal circumstances.

---

## 🎯 Use Case

Malware families such as `Win32/Delf.QJF` and others often attempt to drop or hijack `Gallery.exe` within sensitive user or system directories, especially:

- `%APPDATA%\Gallery.exe`
- `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe`

This script defends those vectors by creating a **zero-byte decoy** `Gallery.exe` and locking it at the filesystem level.

---

## ✅ Features

- Creates decoy executable at common malware target locations
- Applies non-reversible ACL rules preventing:
  - File deletion
  - Modification or overwrite
  - Execution by unauthorized users
- Restricts all accounts including:
  - `Administrators`
  - `SYSTEM`
  - `TrustedInstaller`
- Can optionally remove an existing file and replace it with a hardened version

---

## 🔐 Technical Details

- Ownership is reassigned using `takeown.exe`
- NTFS ACLs are reset using `icacls.exe`
- Write, delete, and change permissions are removed
- Deny permissions override allow rules
- Execution context is elevated to `NT AUTHORITY\SYSTEM` using Sysinternals PsExec

---

## 🧰 Prerequisites

| Component       | Requirement                          |
|----------------|--------------------------------------|
| OS              | Windows 10 / 11 / Server 2016+       |
| PowerShell      | 5.1 or newer                          |
| PsExec          | Sysinternals PsExec (64-bit)         |
| Access Level    | Administrator privileges             |

---

## 🚀 Usage Instructions

1. Download [PsExec](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec) and place it in a known directory.
2. Open PowerShell **as Administrator**.
3. Launch elevated PowerShell as `SYSTEM`:
   ```powershell
   cd "C:\Path\To\PSTools"
   .\PsExec64.exe -accepteula -i -s powershell.exe
