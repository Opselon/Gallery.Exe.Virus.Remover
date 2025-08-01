#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates ultra-secure, zero-byte decoy files to block "Gallery.exe" malware.
.DESCRIPTION
    This script vaccinates a system against malware that creates a "Gallery.exe" file. It works by
    pre-emptively creating empty, locked-down decoy files in common malware drop locations. This
    version features a complete UI overhaul, more robust error checking, expanded target locations,
    and intelligent detection of Antivirus interference.

    The script performs the following actions for each target path:
    1. Checks if the destination drive is NTFS (required for ACL security).
    2. Deletes any pre-existing "Gallery.exe" file, taking ownership if necessary.
    3. Creates a new, empty (0-byte) file named "Gallery.exe".
    4. Sets the file attributes to Hidden and System.
    5. Applies a strict Access Control List (ACL): Denies 'FullControl' to 'Everyone' and allows
       'FullControl' only for the 'SYSTEM' account, blocking all permission inheritance.
.NOTES
    Author: Opselon (github.com/Opselon)
    Upgraded by: Jules & Gemini
    Version: 4.0
#>

#================================================================================
# SCRIPT CONFIGURATION
#================================================================================

# Define the target locations for the decoy files.
$decoyTargets = @(
    @{ Path = Join-Path $env:APPDATA "Gallery.exe"; Description = "User Profile (AppData\Roaming)" },
    @{ Path = Join-Path $env:APPDATA "gallery\Gallery.exe"; Description = "User Profile (AppData\Roaming\gallery)" },
    @{ Path = Join-Path $env:LOCALAPPDATA "Gallery.exe"; Description = "User Profile (AppData\Local)" },
    @{ Path = Join-Path ([Environment]::GetFolderPath('Startup')) "Gallery.exe"; Description = "User Startup Folder" },
    @{ Path = Join-Path $env:TEMP "Gallery.exe"; Description = "User Temp Folder" },
    @{ Path = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"; Description = "System Profile (32-bit)" },
    @{ Path = "C:\Windows\System32\config\systemprofile\AppData\Roaming\Gallery.exe"; Description = "System Profile (64-bit)" },
    @{ Path = Join-Path $env:windir "Temp\Gallery.exe"; Description = "Windows Temp Folder" }
)

#================================================================================
# UI & LOGGING FUNCTIONS
#================================================================================

function Show-Header {
    Clear-Host
    $borderColor = "Magenta"
    $titleColor = "White"
    $textColor = "Gray"
    $authorColor = "Cyan"

    Write-Host "
    ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "           Gallery.exe Malware Decoy Tool v4.0          " -ForegroundColor $titleColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "                       by " -ForegroundColor $textColor; Write-Host "Opselon" -ForegroundColor $authorColor; Write-Host "                          ║" -ForegroundColor $borderColor
    Write-Host "    ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "  This script creates locked decoy files to block known    " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "  malware execution paths. Administrator rights required.  " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $borderColor
    Write-Host ""
    Write-Host " [!]" -ForegroundColor Yellow -NoNewline; Write-Host " Running with Administrator privileges..." -ForegroundColor Gray
    Write-Host ""
}

function Write-SectionHeader {
    param([string]$Title)
    $borderColor = "Cyan"
    $titleText = " $Title "
    $paddingLength = [Math]::Floor((56 - $titleText.Length) / 2)
    $padding = "═" * $paddingLength
    Write-Host ""
    Write-Host "    ╔$($padding)$($titleText)$($padding)╗" -ForegroundColor $borderColor
    Write-Host ""
}

#================================================================================
# CORE SCRIPT FUNCTIONS
#================================================================================

function Lock-FileUltraSecure {
    param(
        [Parameter(Mandatory=$true)] [string]$TargetPath,
        [Parameter(Mandatory=$true)] [string]$Description
    )

    Write-Host "🔹" -ForegroundColor "Cyan" -NoNewline; Write-Host " Processing: $Description" -ForegroundColor "White"
    $result = [PSCustomObject]@{ Path = $TargetPath; Success = $false; Message = "" }
    $indent = "   "

    try {
        # --- Pre-flight Checks ---
        $drive = Get-PSDrive -Name ($TargetPath.Split(':')[0]) -ErrorAction Stop
        if ($drive.FileSystem -ne 'NTFS') { throw "Target path is not on an NTFS drive. ACLs cannot be applied." }
        $parentDir = Split-Path $TargetPath -Parent
        if (-not (Test-Path $parentDir)) {
            Write-Host "$indent[i] Parent directory not found. Creating..." -ForegroundColor "Gray"
            New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
        }

        # --- Delete Pre-existing File ---
        if (Test-Path $TargetPath -PathType Leaf) {
            Write-Host "$indent[i] File exists. Attempting to forcefully remove..." -ForegroundColor "Gray"
            takeown /f $TargetPath /a | Out-Null
            icacls $TargetPath /reset /t /c /q | Out-Null
            Remove-Item -Path $TargetPath -Force -ErrorAction Stop
        }

        # --- Create Decoy and Apply Security ---
        New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop | Out-Null
        Write-Host "$indent[✓] Created 0-byte decoy file." -ForegroundColor "Green"
        Set-ItemProperty -Path $TargetPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force -ErrorAction Stop
        Write-Host "$indent[✓] Set attributes to Hidden + System." -ForegroundColor "Green"
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
        Write-Host "$indent[✓] Hardened file ACLs." -ForegroundColor "Green"

    } catch {
        $result.Message = "FAIL: $($_.Exception.Message)"
        return $result
    }

    # --- Final Verification ---
    if (Test-Path $TargetPath -PathType Leaf) {
        if ((Get-Item -Path $TargetPath -Force).Length -eq 0) {
            $result.Success = $true
            $result.Message = "SUCCESS: Decoy created and locked."
        } else {
            $result.Message = "FAIL: Verification failed. File is not empty."
        }
    } else {
        $result.Message = "FAIL: File disappeared. LIKELY AN ANTIVIRUS. Add path to AV exclusion list and re-run."
    }
    Write-Host ""
    return $result
}

#================================================================================
# MAIN EXECUTION
#================================================================================

Show-Header

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "[✗] FATAL: This script must be run as an Administrator." -ForegroundColor "Red"
    Write-Host "   Please re-launch from an elevated PowerShell prompt." -ForegroundColor "Gray"
    Start-Sleep -Seconds 7; exit 1
}

Write-Host "Press any key to begin the vaccination process..." -ForegroundColor "Yellow"
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null

Write-SectionHeader -Title "Applying Decoy Files"

$allResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$processedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($target in $decoyTargets) {
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target.Path)
    if ($processedPaths.Add($resolvedPath)) {
        $result = Lock-FileUltraSecure -TargetPath $resolvedPath -Description $target.Description
        $allResults.Add($result)
    }
}

# --- Final Summary ---
Write-SectionHeader -Title "Execution Summary"

$failedCount = 0
foreach ($res in $allResults) {
    if ($res.Success) {
        Write-Host "  [✓] " -ForegroundColor Green -NoNewline
        Write-Host "$($res.Message) " -ForegroundColor "Gray" -NoNewline
    } else {
        $failedCount++
        Write-Host "  [✗] " -ForegroundColor Red -NoNewline
        Write-Host "$($res.Message) " -ForegroundColor "Yellow" -NoNewline
    }
    Write-Host "($($res.Path))" -ForegroundColor "DarkGray"
}

if ($failedCount -eq 0) {
    Write-Host "`n  [✓] All decoys were created successfully! System is protected." -ForegroundColor "Green"
} else {
    Write-Host "`n  [!] One or more decoys failed. Please review the summary above." -ForegroundColor "Yellow"
}

# --- GitHub Shoutout ---
$borderColor = "Magenta"
$textColor = "Gray"
$starColor = "Yellow"
$urlColor = "Cyan"

Write-Host "

    ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "   If you found this script useful, please give it a star " -ForegroundColor $textColor; Write-Host "★" -ForegroundColor $starColor; Write-Host "   ║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "                 on GitHub to show your support!           " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host " " -NoNewline; Write-Host "github.com/Opselon/Gallery.Exe.Virus.Remover" -ForegroundColor $urlColor; Write-Host "           ║" -ForegroundColor $borderColor
    Write-Host "    ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $borderColor

Write-Host "`nScript execution finished.`n" -ForegroundColor "Gray"
