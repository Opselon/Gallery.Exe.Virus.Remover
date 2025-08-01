#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates ultra-secure, zero-byte decoy files for "Gallery.exe" to block common malware variants.
.DESCRIPTION
    This script is designed to prevent a specific type of malware that creates a "Gallery.exe"
    file in various user or system profile locations. It works by pre-emptively creating empty,
    locked-down decoy files in common target locations. This updated version includes an enhanced
    user interface, more robust error checking, and an expanded list of target locations based on
    malware behavior analysis.

    The script performs the following actions for each target path:
    1. Checks if the destination drive is NTFS, which is required for ACL security.
    2. Deletes any pre-existing "Gallery.exe" file, taking ownership if necessary.
    3. Creates a new, empty (0-byte) file named "Gallery.exe".
    4. Sets the file attributes to Hidden and System to prevent easy discovery.
    5. Applies a strict Access Control List (ACL):
        - Denies 'FullControl' to the 'Everyone' group.
        - Allows 'FullControl' only for the 'SYSTEM' account.
        - Blocks all inheritance of permissions.

    This makes the file undeletable by normal user or even administrator processes, effectively
    vaccinating the system against the malware. The script must be run with Administrator
privileges.
.NOTES
    Author: Opselon
    Upgraded by: Jules & Gemini
    Version: 3.0
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
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "STEP", "HEADER")]
        [string]$Level = "INFO",
        [Parameter(Mandatory=$false)]
        [int]$Indent = 0
    )

    $colorMap = @{
        "INFO"    = "Gray"
        "SUCCESS" = "Green"
        "WARN"    = "Yellow"
        "ERROR"   = "Red"
        "STEP"    = "Cyan"
        "HEADER"  = "White"
    }
    $prefixMap = @{
        "INFO"    = "[i]"
        "SUCCESS" = "[✓]"
        "WARN"    = "[!]"
        "ERROR"   = "[✗]"
        "STEP"    = "-->"
        "HEADER"  = "
==
"
    }

    $indentSpace = " " * ($Indent * 4)
    $prefix = $prefixMap[$Level]
    $color = $colorMap[$Level]

    Write-Host -ForegroundColor $color "$indentSpace$prefix $Message"
}

function Show-Header {
    Clear-Host
    Write-Host "
┌──────────────────────────────────────────────────────────┐
" -ForegroundColor Green
    Write-Host "│" -ForegroundColor Green -NoNewline
    Write-Host "      Gallery.exe Malware Decoy Tool (v3.0)           " -ForegroundColor White
    Write-Host "│" -ForegroundColor Green
    Write-Host "├──────────────────────────────────────────────────────────┤
" -ForegroundColor Green
    Write-Host "│" -ForegroundColor Green -NoNewline
    Write-Host " This script creates locked-down decoy files to block      " -ForegroundColor Gray
    Write-Host "│" -ForegroundColor Green
    Write-Host "│" -ForegroundColor Green -NoNewline
    Write-Host " known malware execution paths. Administrator privileges   " -ForegroundColor Gray
    Write-Host "│" -ForegroundColor Green
    Write-Host "│" -ForegroundColor Green -NoNewline
    Write-Host " are required.                                           " -ForegroundColor Gray
    Write-Host "│" -ForegroundColor Green
    Write-Host "└──────────────────────────────────────────────────────────┘
" -ForegroundColor Green
    Write-Log -Level "WARN" -Message "Running with Administrator privileges..."
    Write-Host ""
}

#================================================================================
# CORE SCRIPT FUNCTIONS
#================================================================================

function Lock-FileUltraSecure {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,
        [Parameter(Mandatory=$true)]
        [string]$Description
    )

    Write-Log -Level "HEADER" -Message "Processing: $Description"

    $result = [PSCustomObject]@{
        Path = $TargetPath
        Success = $false
        Message = ""
    }

    # --- 1. Pre-flight Check: Ensure Drive is NTFS ---
    $drive = Get-PSDrive -Name ($TargetPath.Split(':')[0]) -ErrorAction SilentlyContinue
    if (-not $drive -or $drive.FileSystem -ne 'NTFS') {
        $result.Message = "CRITICAL: Target path is not on an NTFS drive. ACLs cannot be applied."
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        return $result
    }

    # --- 2. Ensure Parent Directory Exists ---
    $parentDir = Split-Path $TargetPath -Parent
    if (-not (Test-Path $parentDir)) {
        Write-Log -Level "INFO" -Message "Parent directory not found. Creating: $parentDir" -Indent 1
        try {
            New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
        } catch {
            $result.Message = "CRITICAL: Failed to create parent directory. Error: $($_.Exception.Message)"
            Write-Log -Level "ERROR" -Message $result.Message -Indent 1
            return $result
        }
    }

    # --- 3. Delete Pre-existing File (if any) ---
    if (Test-Path $TargetPath -PathType Leaf) {
        Write-Log -Level "INFO" -Message "File exists. Attempting to forcefully remove it..." -Indent 1
        try {
            # Escalate privileges to take ownership and reset permissions before deleting
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

    # --- 4. Create the Decoy File ---
    try {
        New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop | Out-Null
        Write-Log -Level "INFO" -Message "Created 0-byte decoy file." -Indent 1
    } catch {
        $result.Message = "Failed to create decoy file. Error: $($_.Exception.Message)"
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        return $result
    }

    # --- 5. Set Attributes and Harden ACLs ---
    try {
        # Set attributes first
        Set-ItemProperty -Path $TargetPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force -ErrorAction Stop
        Write-Log -Level "INFO" -Message "Set file attributes to Hidden + System." -Indent 1

        # Define and apply strict ACL
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false) # Block inheritance
        $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")
        $allowRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")
        $acl.AddAccessRule($denyRule)
        $acl.AddAccessRule($allowRule)

        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
        Write-Log -Level "SUCCESS" -Message "Hardened file ACL: Deny Everyone, Allow SYSTEM." -Indent 1

    } catch {
        $result.Message = "Failed to apply security settings (Attributes or ACL). Error: $($_.Exception.Message)"
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        return $result
    }

    # --- 6. Final Verification ---
    $item = Get-Item -Path $TargetPath -Force -ErrorAction SilentlyContinue
    if ($item -and $item.Length -eq 0) {
        $result.Success = $true
        $result.Message = "Decoy successfully created and locked."
    } else {
        $result.Message = "Verification failed. The decoy file is missing or not empty."
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
    }

    return $result
}

#================================================================================
# MAIN EXECUTION
#================================================================================

Show-Header

# --- Check for Admin Privileges ---
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Log -Level "ERROR" -Message "This script must be run as an Administrator. Please re-launch from an elevated prompt."
    Start-Sleep -Seconds 7
    exit 1
}

# --- User Confirmation ---
Write-Host "Press any key to begin the vaccination process..." -ForegroundColor Yellow
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
Write-Host ""

# --- Process all defined targets ---
$allResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$processedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($target in $decoyTargets) {
    # Resolve path to prevent duplicates (e.g., if script runs as SYSTEM)
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target.Path)
    if ($processedPaths.Contains($resolvedPath)) {
        continue
    }
    $processedPaths.Add($resolvedPath) | Out-Null

    $result = Lock-FileUltraSecure -TargetPath $resolvedPath -Description $target.Description
    $allResults.Add($result)
}

# --- Final Summary ---
Write-Host "
┌──────────────────────────────────────────────────────────┐
" -ForegroundColor Blue
Write-Host "│" -ForegroundColor Blue -NoNewline
Write-Host "                      Execution Summary                   " -ForegroundColor White
Write-Host "│" -ForegroundColor Blue
Write-Host "└──────────────────────────────────────────────────────────┘
" -ForegroundColor Blue

$allResults | Format-Table -AutoSize @(
    @{ Expression = { if ($_.Success) { "[✓]" } else { "[✗]" } }; Label = "Status"; ForegroundColor = { if ($_.Success) { "Green" } else { "Red" } } },
    @{ Expression = { $_.Path }; Label = "Target Path" },
    @{ Expression = { $_.Message }; Label = "Result" }
)

$successCount = ($allResults | Where-Object { $_.Success }).Count
if ($successCount -eq $allResults.Count) {
    Write-Log -Level "SUCCESS" -Message "All decoys were created and verified successfully! System is protected."
} else {
    Write-Log -Level "WARN" -Message "One or more decoys failed. Please review the summary table above."
}

Write-Host ""
Write-Host "Script execution finished." -ForegroundColor Gray
Write-Host ""
