#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates ultra-secure, zero-byte decoy files for "Gallery.exe" to block malware.
.DESCRIPTION
    This script is designed to prevent a specific type of malware that creates a "Gallery.exe"
    file in user or system profile locations. It works by pre-emptively creating empty,
    locked-down decoy files in common target locations.

    The script performs the following actions for each target path:
    1. Deletes any pre-existing "Gallery.exe" file.
    2. Creates a new, empty (0-byte) file named "Gallery.exe".
    3. Sets the file attributes to Hidden and System to prevent easy discovery.
    4. Applies a strict Access Control List (ACL):
        - Denies 'FullControl' to the 'Everyone' group.
        - Allows 'FullControl' only for the 'SYSTEM' account.
        - Blocks all inheritance of permissions.

    This makes the file undeletable by normal user or even administrator processes, effectively
    vaccinating the system against the malware. The script must be run with Administrator
    privileges to modify system locations and set security permissions.
.NOTES
    Author: Opselon
    Upgraded by: Jules
    Version: 2.0
#>

#================================================================================
# SCRIPT CONFIGURATION
#================================================================================

# Define the target locations for the decoy files.
# These are common paths where the Gallery.exe malware may appear.
# Based on user feedback, targeting only the paths observed in logs.
$decoyTargets = @(
    @{
        Path = Join-Path $env:APPDATA "Gallery.exe"
        Description = "Current User Profile Decoy"
    }
    @{
        Path = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
        Description = "System Profile (32-bit) Decoy"
    }
)

#================================================================================
# SCRIPT BODY
#================================================================================

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "STEP")]
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
    }
    $prefixMap = @{
        "INFO"    = "[i]"
        "SUCCESS" = "[✓]"
        "WARN"    = "[!]"
        "ERROR"   = "[✗]"
        "STEP"    = "==>"
    }

    $indentSpace = " " * ($Indent * 2)
    $prefix = $prefixMap[$Level]
    $color = $colorMap[$Level]

    Write-Host -ForegroundColor $color "$indentSpace$prefix $Message"
}

function Lock-FileUltraSecure {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,
        [Parameter(Mandatory=$true)]
        [string]$Description
    )

    Write-Log -Level "STEP" -Message "Processing: $Description"

    $result = [PSCustomObject]@{
        Path = $TargetPath
        Description = $Description
        Success = $false
        Message = ""
    }

    # --- 1. Ensure Parent Directory Exists ---
    $parentDir = Split-Path $TargetPath
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

    # --- 2. Delete Pre-existing File (if any) ---
    if (Test-Path $TargetPath) {
        Write-Log -Level "INFO" -Message "File already exists. Attempting to remove it..." -Indent 1
        try {
            # Force removal, including taking ownership and resetting ACLs if needed.
            # These commands are chained to escalate privileges if simple removal fails.
            takeown /f $TargetPath /a | Out-Null
            icacls $TargetPath /reset /t /c /q | Out-Null
            Remove-Item -Path $TargetPath -Force -ErrorAction Stop
            Write-Log -Level "SUCCESS" -Message "Successfully removed pre-existing file." -Indent 1
        } catch {
            $result.Message = "CRITICAL: Failed to delete pre-existing file at $TargetPath. Error: $($_.Exception.Message)"
            Write-Log -Level "ERROR" -Message $result.Message -Indent 1
            # Do not proceed if we can't remove the old file.
            return $result
        }
    }

    # --- 3. Create the Decoy File ---
    try {
        New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop | Out-Null
        Write-Log -Level "INFO" -Message "Created new 0-byte decoy file." -Indent 1
    } catch {
        $result.Message = "Failed to create decoy file. Error: $($_.Exception.Message)"
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        return $result
    }

    # --- 4. Set Attributes to Hidden + System ---
    try {
        Set-ItemProperty -Path $TargetPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force -ErrorAction Stop
        Write-Log -Level "INFO" -Message "Set file attributes to Hidden + System." -Indent 1
    } catch {
        $result.Message = "Failed to set file attributes. Error: $($_.Exception.Message)"
        Write-Log -Level "WARN" -Message $result.Message -Indent 1
        # This might not be critical, so we continue but will report it.
    }

    # --- 5. Harden ACLs ---
    try {
        $acl = New-Object System.Security.AccessControl.FileSecurity
        # Block permission inheritance
        $acl.SetAccessRuleProtection($true, $false)
        # Deny Everyone FullControl
        $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")
        $acl.AddAccessRule($denyRule)
        # Allow SYSTEM FullControl
        $allowRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")
        $acl.AddAccessRule($allowRule)

        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
        Write-Log -Level "INFO" -Message "Hardened file ACL: Deny Everyone, Allow SYSTEM." -Indent 1
    } catch {
        $result.Message = "Failed to apply security ACLs. Error: $($_.Exception.Message)"
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        return $result
    }

    # --- 6. Final Verification ---
    try {
        $item = Get-Item -Path $TargetPath -Force -ErrorAction Stop
        if ($item.Length -eq 0) {
            $result.Success = $true
            $result.Message = "Decoy successfully created and verified."
            Write-Log -Level "SUCCESS" -Message $result.Message -Indent 1
        } else {
            $result.Message = "Verification failed: File exists but is not empty."
            Write-Log -Level "ERROR" -Message $result.Message -Indent 1
        }
    } catch {
        $result.Message = "Verification failed: Could not find the created file. Error: $($_.Exception.Message)"
        Write-Log -Level "ERROR" -Message $result.Message -Indent 1
    }

    return $result
}

#================================================================================
# MAIN EXECUTION
#================================================================================

# --- Display Header ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "      Gallery.exe Decoy File Creator (Upgraded v2.0)        " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "This script will create locked-down decoy files to prevent malware."
Write-Host "Running with Administrator privileges..." -ForegroundColor Yellow
Write-Host ""

# --- Check for Admin Privileges ---
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Log -Level "ERROR" -Message "This script must be run as an Administrator. Please re-launch from an elevated prompt."
    # Pause for 5 seconds before exiting so the user can read the message.
    Start-Sleep -Seconds 5
    exit 1
}

# --- Process all defined targets ---
$allResults = @()
foreach ($target in $decoyTargets) {
    # Deduplicate paths - $env:APPDATA could resolve to one of the system paths if run as SYSTEM
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target.Path)
    if ($allResults.Path -contains $resolvedPath) {
        Write-Log -Level "INFO" -Message "Skipping duplicate target path: $resolvedPath"
        continue
    }
    $allResults += Lock-FileUltraSecure -TargetPath $target.Path -Description $target.Description
    Write-Host "" # Add spacing between processing blocks
}

# --- Final Summary ---
Write-Host "============================================================" -ForegroundColor Blue
Write-Host "                       FINAL SUMMARY                        " -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

$successCount = 0
foreach ($res in $allResults) {
    if ($res.Success) {
        $successCount++
        Write-Log -Level "SUCCESS" -Message "($($res.Description)): $($res.Message)"
    } else {
        Write-Log -Level "ERROR" -Message "($($res.Description)): $($res.Message)"
    }
    Write-Log -Level "INFO" -Message " -> Path: $($res.Path)" -Indent 1
}

Write-Host "------------------------------------------------------------"
if ($successCount -eq $allResults.Count) {
    Write-Log -Level "SUCCESS" -Message "All decoys were created and verified successfully!"
} else {
    Write-Log -Level "WARN" -Message "One or more decoys failed to be created. Please review the log above."
}
Write-Host ""
Write-Host "Script execution finished."
Write-Host ""
