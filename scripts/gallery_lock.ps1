#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates ultra-secure, zero-byte decoy files for "Gallery.exe" to block common malware variants.
.DESCRIPTION
    This script vaccinates a system against malware that creates a "Gallery.exe" file. It works by
    pre-emptively creating empty, locked-down decoy files in common malware drop locations. This
    version includes an enhanced UI, more target locations, and intelligent detection of Antivirus
    interference.

    The script performs the following actions for each target path:
    1. Checks if the destination drive is NTFS (required for ACL security).
    2. Deletes any pre-existing "Gallery.exe" file, taking ownership if necessary.
    3. Creates a new, empty (0-byte) file named "Gallery.exe".
    4. Sets the file attributes to Hidden and System.
    5. Applies a strict Access Control List (ACL): Denies 'FullControl' to 'Everyone' and allows
       'FullControl' only for the 'SYSTEM' account, blocking all permission inheritance.
.NOTES
    Author: Opselon
    Upgraded by: Jules & Gemini
    Version: 3.1
#>

#================================================================================
# SCRIPT CONFIGURATION
#================================================================================

# Define the target locations for the decoy files.
# Based on analysis of common malware drop locations.
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

function Write-Log {
    param(
        [Parameter(Mandatory=$true)] [string]$Message,
        [Parameter(Mandatory=$false)] [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "STEP", "HEADER")] [string]$Level = "INFO",
        [Parameter(Mandatory=$false)] [int]$Indent = 0
    )
    $colorMap = @{ INFO="Gray"; SUCCESS="Green"; WARN="Yellow"; ERROR="Red"; STEP="Cyan"; HEADER="White" }
    $prefixMap = @{ INFO="[i]"; SUCCESS="[✓]"; WARN="[!]"; ERROR="[✗]"; STEP="-->"; HEADER="===" }
    $indentSpace = " " * ($Indent * 4)
    Write-Host -ForegroundColor $colorMap[$Level] "$indentSpace$($prefixMap[$Level]) $Message"
}

function Show-Header {
    Clear-Host
    $borderColor = "Green"
    Write-Host "
┌──────────────────────────────────────────────────────────┐" -ForegroundColor $borderColor
    Write-Host "│" -ForegroundColor $borderColor -NoNewline; Write-Host "      Gallery.exe Malware Decoy Tool (v3.1)           " -ForegroundColor White; Write-Host "│" -ForegroundColor $borderColor
    Write-Host "├──────────────────────────────────────────────────────────┤" -ForegroundColor $borderColor
    Write-Host "│" -ForegroundColor $borderColor -NoNewline; Write-Host " This script creates locked-down decoy files to block      " -ForegroundColor Gray; Write-Host "│" -ForegroundColor $borderColor
    Write-Host "│" -ForegroundColor $borderColor -NoNewline; Write-Host " known malware execution paths. Administrator privileges   " -ForegroundColor Gray; Write-Host "│" -ForegroundColor $borderColor
    Write-Host "│" -ForegroundColor $borderColor -NoNewline; Write-Host " are required.                                           " -ForegroundColor Gray; Write-Host "│" -ForegroundColor $borderColor
    Write-Host "└──────────────────────────────────────────────────────────┘
" -ForegroundColor $borderColor
    Write-Log -Level "WARN" -Message "Running with Administrator privileges..."
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

    Write-Log -Level "HEADER" -Message "Processing: $Description"
    $result = [PSCustomObject]@{ Path = $TargetPath; Success = $false; Message = "" }

    # --- Pre-flight Checks ---
    try {
        $drive = Get-PSDrive -Name ($TargetPath.Split(':')[0]) -ErrorAction Stop
        if ($drive.FileSystem -ne 'NTFS') { throw "Target path is not on an NTFS drive. ACLs cannot be applied." }

        $parentDir = Split-Path $TargetPath -Parent
        if (-not (Test-Path $parentDir)) {
            Write-Log -Level "INFO" -Message "Parent directory not found. Creating: $parentDir" -Indent 1
            New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        $result.Message = "CRITICAL SETUP FAILED: $($_.Exception.Message)"
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        return $result
    }

    # --- Delete Pre-existing File (if any) ---
    if (Test-Path $TargetPath -PathType Leaf) {
        Write-Log -Level "INFO" -Message "File exists. Attempting to forcefully remove it..." -Indent 1
        try {
            takeown /f $TargetPath /a | Out-Null
            icacls $TargetPath /reset /t /c /q | Out-Null
            Remove-Item -Path $TargetPath -Force -ErrorAction Stop
            Write-Log -Level "SUCCESS" -Message "Successfully removed pre-existing file." -Indent 1
        } catch {
            $result.Message = "CRITICAL: Could not delete pre-existing file. Error: $($_.Exception.Message)"
            Write-Log -Level "ERROR" -Message $result.Message -Indent 1
            return $result
        }
    }

    # --- Create Decoy and Apply Security ---
    try {
        New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop | Out-Null
        Write-Log -Level "INFO" -Message "Created 0-byte decoy file." -Indent 1
        Set-ItemProperty -Path $TargetPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force -ErrorAction Stop
        Write-Log -Level "INFO" -Message "Set file attributes to Hidden + System." -Indent 1
        
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
        Write-Log -Level "SUCCESS" -Message "Hardened file ACL: Deny Everyone, Allow SYSTEM." -Indent 1
    } catch {
        $result.Message = "Failed to create or secure decoy. Error: $($_.Exception.Message)"
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        return $result
    }

    # --- Final Verification ---
    if (Test-Path $TargetPath -PathType Leaf) {
        $item = Get-Item -Path $TargetPath -Force
        if ($item.Length -eq 0) {
            $result.Success = $true
            $result.Message = "SUCCESS: Decoy created and locked."
        } else {
            $result.Message = "FAIL: Verification failed. File exists but is not empty."
            Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        }
    } else {
        $result.Message = "FAIL: File disappeared after creation. LIKELY AN ANTIVIRUS. Please add path to AV exclusion list and re-run."
        Write-Log -Level "ERROR" -Message "Verification failed. The file was likely deleted by Antivirus software." -Indent 1
    }
    return $result
}

#================================================================================
# MAIN EXECUTION
#================================================================================

Show-Header

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Log -Level "ERROR" -Message "This script must be run as an Administrator. Please re-launch from an elevated prompt."
    Start-Sleep -Seconds 7; exit 1
}

Write-Host "Press any key to begin the vaccination process..." -ForegroundColor Yellow
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; Write-Host ""

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
$borderColor = "Blue"
Write-Host "
┌──────────────────────────────────────────────────────────┐" -ForegroundColor $borderColor
Write-Host "│" -ForegroundColor $borderColor -NoNewline; Write-Host "                      Execution Summary                   " -ForegroundColor White; Write-Host "│" -ForegroundColor $borderColor
Write-Host "└──────────────────────────────────────────────────────────┘
" -ForegroundColor $borderColor

$allResults | Format-Table -AutoSize @(
    @{ Expression = { if ($_.Success) { "[✓]" } else { "[✗]" } }; Label = "Status"; ForegroundColor = { if ($_.Success) { "Green" } else { "Red" } } },
    @{ Expression = { $_.Path }; Label = "Target Path" },
    @{ Expression = { $_.Message }; Label = "Result" }
)

if (($allResults | Where-Object { -not $_.Success }).Count -eq 0) {
    Write-Log -Level "SUCCESS" -Message "All decoys were created and verified successfully! System is protected."
} else {
    Write-Log -Level "WARN" -Message "One or more decoys failed. Please review the summary table above for details."
}

Write-Host "`nScript execution finished.`n" -ForegroundColor Gray
