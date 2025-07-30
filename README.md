# Gallery.Exe Virus Remover — Pro Version

## 🛡️ What is this?

**Gallery.Exe Virus Remover (Pro Version)** is a PowerShell script that creates a hardened, zero-byte `Gallery.exe` file in your `%APPDATA%` folder. It then locks the file so that only the Windows TrustedInstaller account can delete or modify it. This prevents most malware from reinfecting your system with a malicious `Gallery.exe`.

---

## 🚀 Pro Features

- **Zero-byte decoy:** Creates a dummy `Gallery.exe` to block malware.
- **TrustedInstaller lock:** Only TrustedInstaller can remove or change the file.
- **Colorized output:** Console messages are color-coded for easy reading.
- **Comprehensive logging:** All actions are logged to your desktop.
- **Process killer:** Terminates any running `Gallery.exe` before hardening.
- **NTFS hardening:** Removes all permissions except TrustedInstaller.
- **Easy to use:** Just run as Administrator and you're protected.

---

## 📝 Usage

1. **Open PowerShell as Administrator.**
2. **Run the script:**
   ```powershell
   .\CreateUnkillableGallery.ps1
   ```
3. **Check the log:**  
   See `gallery_lock.log` on your Desktop for a full activity log.

---

## ⚠️ Requirements

- Windows 10/11
- PowerShell 5.1+
- Must be run as Administrator

---

## ❓ FAQ

**Q: Can I delete the dummy file?**  
A: Only if you take ownership as TrustedInstaller or manually reset permissions as an admin.

**Q: Why TrustedInstaller?**  
A: Most malware runs as SYSTEM or Administrator, but not as TrustedInstaller. This makes the file nearly impossible for malware to remove.

---

## 🏆 Credits

- Inspired by Windows hardening best practices.
- Script by [Your Name]
