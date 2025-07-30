# 🛡️ Gallery.exe Ultra-Lock — Pro Version

A PowerShell script to create **indestructible decoy files** (`Gallery.exe`) in both user and system locations, using advanced NTFS and ACL tricks. Block malware reinfection and keep your system clean!

---

## 🚀 Features

- **Deletes old Gallery.exe** in both user and systemprofile locations
- **Creates zero-byte decoy files** at:
  - `%APPDATA%\Gallery.exe` (User)
  - `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` (System)
- **Applies hardcore ACLs:**
  - ❌ Deny Everyone (even Admins) all access
  - ✅ Allow only SYSTEM (or TrustedInstaller, if you choose) full control
  - 🔒 Removes inherited permissions
- **Sets Hidden + System attributes** (invisible to Explorer)
- **Colorized logging** and clear status output
- **Open-source, no dependencies**

---

## 🛠️ Usage

### 1. Run as SYSTEM (Recommended for full protection)

> **Tip:** Use [PsExec](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec) to launch PowerShell as SYSTEM:

```cmd
.\PsExec64.exe -i -s powershell.exe
```

In the new SYSTEM PowerShell window:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\CreateUnkillableGallery.ps1
```

---

### 📁 File Locations

| Location        | Path                                                                 |
|-----------------|----------------------------------------------------------------------|
| User Profile    | `%APPDATA%\Gallery.exe`                                              |
| System Profile  | `C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe` |

---

### 🧱 Security Details

| Feature             | Description                                                      |
|---------------------|------------------------------------------------------------------|
| 🔒 ACL Lock         | Denies all access to Everyone, even Admins                       |
| ✅ SYSTEM-only      | Only `NT AUTHORITY\SYSTEM` (or TrustedInstaller) can manage file |
| 🚫 No Inheritance   | No inherited permissions from parent folders                     |
| 🧙 Hidden + System  | File is invisible in Explorer by default                         |

---

## ⚠️ Warnings

- **Do NOT lock critical system or app files!**  
  This script is for decoy/fake files only.
- **Even Admins cannot delete or change these files** without taking ownership and resetting ACLs.

### To Remove or Edit the File

1. **Take ownership:**
   ```cmd
   takeown /f "C:\Path\To\Gallery.exe"
   ```
2. **Reset permissions:**
   ```cmd
   icacls "C:\Path\To\Gallery.exe" /reset
   ```

---

## 💣 Optional: Extra Hardening

- **Keep file locked in memory:**  
  Open a handle to the file to block deletion, even by SYSTEM:
  ```powershell
  $fs = [System.IO.File]::Open("$env:APPDATA\Gallery.exe", 'Open', 'Read', 'Read')
  ```

---

## 🔎 Troubleshooting

| Problem                        | Solution                                              |
|---------------------------------|------------------------------------------------------|
| ❌ “Access Denied” on Set-Acl   | Run script as SYSTEM using PsExec                    |
| 🪟 File doesn’t show up         | Enable viewing hidden/system files in Explorer        |
| 💥 Can't delete                 | Use `takeown` and `icacls` as shown above            |

---

## 📜 License

Open-source and free to use. Share, fork, and modify — responsibly!

