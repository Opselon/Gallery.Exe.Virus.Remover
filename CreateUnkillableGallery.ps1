# --- File: CreateUnkillableGallery.ps1 ---
# Paths to lock down
$paths = @(
    "$env:APPDATA\Gallery.exe",
    "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
)

# TrustedInstaller SID
$trustedInstaller = "NT SERVICE\TrustedInstaller"

foreach ($path in $paths) {
    # Ensure directory exists
    $dir = Split-Path $path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Remove any existing file (in case permissions allow)
    if (Test-Path $path) {
        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
    }

    # Create a zero-byte file
    New-Item -ItemType File -Path $path -Force | Out-Null

    # Give ownership to TrustedInstaller
    icacls $path /setowner "$trustedInstaller" /T /C | Out-Null

    # Disable inheritance and remove all inherited ACEs
    icacls $path /inheritance:r /T /C | Out-Null

    # Remove any explicit permissions (just in case)
    icacls $path /remove "Administrators" /T /C | Out-Null
    icacls $path /remove "Users" /T /C | Out-Null
    icacls $path /remove "SYSTEM" /T /C | Out-Null
    icacls $path /remove "Everyone" /T /C | Out-Null

    # Deny FullControl to Everyone
    icacls $path /deny "Everyone:(F)" /T /C | Out-Null

    Write-Host "🔒 Locked down $path"
}
# ----------------------------------------