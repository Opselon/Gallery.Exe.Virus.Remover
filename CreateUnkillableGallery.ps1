# ==============================
# 📁 HardLock-Gallery.ps1
# 🛡️ Create & Lock a Dummy Gallery.exe to Prevent Malware
# ==============================

# ===[ CONFIG ]===
$GalleryPath = "$env:APPDATA\Gallery.exe"
$LogFile = "$env:USERPROFILE\Desktop\gallery_lock.log"

# ===[ Logging Function ]===
function Log {
    param (
        [string]$msg,
        [string]$color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMsg = "$timestamp :: $msg"
    # Write to log file
    $fullMsg | Out-File -FilePath $LogFile -Append -Encoding utf8
    # Write to console with color
    Write-Host $fullMsg -ForegroundColor $color
}

# ===[ Kill Existing Process and Delete Old File ]===
function Kill-And-Remove {
    try {
        Log "Checking for existing 'Gallery.exe' process..."
        $proc = Get-Process -Name "Gallery" -ErrorAction SilentlyContinue
        if ($proc) {
            Log "Process found. Killing..."
            $proc | Stop-Process -Force
            Log "Process killed successfully."
        } else {
            Log "No running 'Gallery.exe' process found."
        }

        if (Test-Path $GalleryPath) {
            Log "Existing file found at $GalleryPath. Attempting to delete..."
            Remove-Item $GalleryPath -Force
            Log "Old file removed."
        } else {
            Log "No existing Gallery.exe file found."
        }
    } catch {
        Log "⚠️ Error during removal: $_" "Red"
    }
}

# ===[ Create Zero-byte Gallery.exe File ]===
function Create-Dummy {
    try {
        Log "Creating dummy Gallery.exe at: $GalleryPath"
        New-Item -Path $GalleryPath -ItemType File -Force | Out-Null
        Log "Dummy file created."
    } catch {
        Log "❌ Error creating dummy: $_" "Red"
    }
}

# ===[ Lock Down the File ]===
function Lock-File {
    try {
        Log "Taking ownership as TrustedInstaller..."

        # Set owner to TrustedInstaller (requires running as admin)
        $trustedInstaller = "NT SERVICE\TrustedInstaller"
        $file = Get-Item $GalleryPath
        $acl = Get-Acl $file.FullName
        $acl.SetOwner([System.Security.Principal.NTAccount]$trustedInstaller)
        Set-Acl -Path $file.FullName -AclObject $acl
        $acl.SetOwner($trustedInstaller)
        Log "Resetting permissions and removing inheritance..."
        $acl = Get-Acl $GalleryPath
        $acl.SetAccessRuleProtection($true, $false) # Disable inheritance, remove inherited rules

        Log "Removing all existing access rules..."
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

        Log "Granting full control to TrustedInstaller only..."
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT SERVICE\TrustedInstaller", "FullControl", "Allow")
        $acl.AddAccessRule($rule)
        Set-Acl -Path $GalleryPath -AclObject $acl

        Log "Validating Gallery.exe path before setting attributes..."
        if (-not (Test-Path $GalleryPath -PathType Leaf)) {
            throw "Gallery.exe path is invalid or does not exist: $GalleryPath"
        }

        Log "Setting file as read-only and hidden using Set-ItemProperty..."
        Set-ItemProperty -Path $GalleryPath -Name Attributes -Value ([System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Hidden)

        Log "Applying NTFS lock completed successfully. Only TrustedInstaller can remove the file."

        Log "Applying NTFS lock completed successfully. Only TrustedInstaller can remove the file."
    } catch {
        Log "🔒 Error locking file: $_" "Red"
    }
}

# ===[ Main Execution ]===
Log "==========================" "Cyan"
Log "🚀 Starting Gallery.exe Lockdown" "Green"
Log "Target path: $GalleryPath" "Yellow"

Kill-And-Remove
Create-Dummy
Lock-File

Log "✅ Operation complete. Gallery.exe is hardened." "Green"
Log "==========================`n" "Cyan"
