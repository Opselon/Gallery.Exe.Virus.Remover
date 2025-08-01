# =================================================================
# SCRIPT-LEVEL PRE-CHECKS
# =================================================================
# --- 1. REQUIRE ADMINISTRATOR ---
# This script requires elevation to set ACLs and write to system folders.
Write-Verbose "Checking for Administrator privileges..."
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "PERMISSION DENIED: This script must be run as an Administrator. Please right-click the PowerShell window or script and select 'Run as Administrator'."
    # Pause to allow the user to read the error before the window closes.
    if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit" }
    exit 1
}
Write-Verbose "✔️ Administrator privileges confirmed."


# =================================================================
# FUNCTION DEFINITION
# =================================================================
<#
.SYNOPSIS
    Checks for or creates an "ultra-secure" lock file with enhanced security.
.DESCRIPTION
    This function ensures a file exists that is difficult for a standard user to remove.
    It now runs an initial check. If the file is already secure, it reports success.
    Otherwise, it creates the file and applies multiple layers of security:
    - Sets attributes to Hidden and System.
    - Sets the file owner to the NT AUTHORITY\SYSTEM account.
    - Adds an ACL audit rule to log modification or deletion attempts.
    - Applies a restrictive ACL that denies 'Everyone' and only allows 'SYSTEM'.
.PARAMETER TargetPath
    The full path, including the filename, of the lock file.
.RETURNS
    [bool] Returns $true if the file is successfully secured. Returns $false on failure.
#>
function Lock-FileUltraSecure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$TargetPath
    )

    # Check if file is already perfectly locked
    if (Test-Path $TargetPath) {
        try {
            $acl = Get-Acl $TargetPath -ErrorAction Stop
            $isDenied = $acl.Access | Where-Object { $_.IdentityReference -eq 'Everyone' -and $_.AccessControlType -eq 'Deny' }
            $isOwnedBySystem = $acl.Owner -eq 'NT AUTHORITY\SYSTEM'
            
            if ($isDenied -and $isOwnedBySystem) {
                Write-Verbose "✔️ File at '$TargetPath' is already fully secured."
                return $true # SUCCESS
            }
        } catch {
            Write-Warning "Could not read existing file state for '$TargetPath'. Proceeding with locking process."
        }
    }

    # Create/Overwrite File
    Write-Verbose "🧱 Attempting to create/overwrite file at: $TargetPath"
    try {
        New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop | Out-Null
        Write-Verbose "✔️ File created/overwritten."
    } catch {
        Write-Error "❌ CRITICAL: Failed to create file at '$TargetPath'. Error: $($_.Exception.Message)"
        return $false # FAILURE
    }

    # Apply Security Layers
    try {
        Write-Verbose "👻 Setting file attributes to Hidden + System."
        Attrib.exe +H +S $TargetPath
        
        $acl = Get-Acl $TargetPath
        
        Write-Verbose "👑 Setting file owner to SYSTEM."
        $owner = New-Object System.Security.Principal.NTAccount("SYSTEM")
        $acl.SetOwner($owner)

        Write-Verbose "✍️ Adding audit rule to log modification/deletion attempts."
        # Log failures and successes for any attempt by Anyone to Modify or Delete the file.
        $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Everyone", "Modify, Delete", "Failure, Success")
        $acl.AddAuditRule($auditRule)

        Write-Verbose "🔒 Applying hardened Access Control List (ACL)."
        $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")

        $acl.SetAccessRuleProtection($true, $false) # Block inheritance, remove existing rules
        $acl.AddAccessRule($denyRule)
        $acl.AddAccessRule($systemRule)

        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
        Write-Verbose "✔️ All security layers applied successfully."
    } catch {
        Write-Error "❌ CRITICAL: Failed to apply security layers to '$TargetPath'. The file was created but is NOT secure. Error: $($_.Exception.Message)"
        return $false # FAILURE
    }
    
    return $true # SUCCESS
}

# =================================================================
# G.E.N. UNIVERSAL PAYLOAD - V5.0 // ALL-PLATFORM COMPATIBLE
# =================================================================
# --- 1. SYSTEM INTEGRITY CHECK & PERMISSION ESCALATION ---
$Host.UI.RawUI.WindowTitle = "G.E.N. // Universal Payload Engaged"
Clear-Host

# Helper function for "typing" effect
function Write-Typing {
    param(
        [string]$Text,
        [int]$Delay = 15,
        [ConsoleColor]$Color = 'Green'
    )
    Write-Host -NoNewline "`n"
    $Text.ToCharArray() | ForEach-Object {
        Write-Host -NoNewline $_ -ForegroundColor $Color
        if (',.!'.Contains($_)) { Start-Sleep -Milliseconds 200 }
        else { Start-Sleep -Milliseconds $Delay }
    }
    Write-Host
}

Write-Typing -Text "Attempting to acquire necessary system privileges..." -Color "Yellow"
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Typing -Text "[FATAL ERROR] :: ELEVATED PERMISSIONS DENIED. CANNOT BREACH SYSTEM CORE." -Color "Red"
    if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to disengage..." }
    exit 1
}
Write-Typing -Text "[SUCCESS] :: ROOT ACCESS GRANTED. ENGAGING MAIN PAYLOAD."
Start-Sleep -Seconds 2
Clear-Host

# =================================================================
# CORE FUNCTION :: DO NOT MODIFY
# =================================================================
function Lock-FileUltraSecure {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory = $true)][string]$TargetPath)
    if (Test-Path $TargetPath) {
        try {
            $acl = Get-Acl $TargetPath -ErrorAction Stop
            if (($acl.Access | Where-Object { $_.IdentityReference -eq 'Everyone' -and $_.AccessControlType -eq 'Deny' }) -and $acl.Owner -eq 'NT AUTHORITY\SYSTEM') {
                Write-Verbose "[DEFENSE ACTIVE] :: '$TargetPath'"
                return $true
            }
        } catch {
            if ($_.Exception.Message -like "*Access to the path*is denied*") { Write-Verbose "[DEFENSE ACTIVE] :: '$TargetPath' (Hardened Lock Confirmed)" ; return $true }
            else { Write-Error ":: UNEXPECTED KERNEL FAULT AT '$TargetPath': $($_.Exception.Message)" ; return $false }
        }
    }
    Write-Verbose ":: Deploying quarantine protocol at '$TargetPath'"
    try {
        if (Test-Path $TargetPath) { Remove-Item -Path $TargetPath -Force -ErrorAction SilentlyContinue }
        $null = New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop
        Attrib.exe +H +S $TargetPath ; $acl = Get-Acl $TargetPath
        $acl.SetOwner([System.Security.Principal.NTAccount]"SYSTEM")
        $acl.AddAuditRule([System.Security.AccessControl.FileSystemAuditRule]::new("Everyone", "Modify, Delete", "Failure, Success"))
        $acl.SetAccessRuleProtection($true, $false)
        $acl.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new("Everyone", "FullControl", "Deny"))
        $acl.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new("SYSTEM", "FullControl", "Allow"))
        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
    } catch {
        if ($_.Exception.Message -like "*Access to the path*is denied*") { Write-Verbose "[DEFENSE ACTIVE] :: Confirmed by re-application failure." ; return $true }
        else { Write-Error ":: CRITICAL FAILURE TO LOCK '$TargetPath': $($_.Exception.Message)" ; return $false }
    }
    return $true
}

# =================================================================
# SCRIPT EXECUTION :: OPERATION "GALLERY PURGE"
# =================================================================

# --- ASCII ART BANNER ---
Write-Host @"

   ██████╗ ███████╗███╗   ██╗     ██╗   ██╗███████╗██╗   ██╗██╗   ██╗
  ██╔════╝ ██╔════╝████╗  ██║     ██║   ██║██╔════╝╚██╗ ██╔╝██║   ██║
  ██║  ███╗█████╗  ██╔██╗ ██║     ██║   ██║█████╗   ╚████╔╝ ██║   ██║
  ██║   ██║██╔══╝  ██║╚██╗██║     ██║   ██║██╔══╝    ╚██╔╝  ██║   ██║
  ╚██████╔╝███████╗██║ ╚████║     ╚██████╔╝███████╗   ██║   ╚██████╔╝
   ╚═════╝ ╚══════╝╚═╝  ╚═══╝      ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝ 
                      [ Gallery.exe Extermination Neutralizer ]

"@ -ForegroundColor Green

Write-Typing -Text "Initializing G.E.N. protocols..."
$processedPaths = [System.Collections.Generic.List[string]]::new()
$overallSuccess = $true

# --- PHASE 1: DEPLOYING COUNTERMEASURES ---
Write-Typing -Text "`n--- PHASE 1 :: DEPLOYING COUNTERMEASURES ON PRIORITY-ZERO TARGETS ---" -Color "Cyan"

# *** UPGRADE #1: UNIVERSAL SYSTEM PATH ***
# This dynamically finds the correct system path for both 32-bit and 64-bit Windows.
$systemProfilePath = Join-Path -Path (Join-Path -Path $env:SystemRoot -ChildPath 'System32') -ChildPath 'config\systemprofile\AppData\Roaming\Gallery.exe'

$primaryPaths = @(
    (Join-Path -Path $env:APPDATA -ChildPath "Gallery.exe"),
    $systemProfilePath
)

foreach ($path in $primaryPaths) {
    Write-Host "`n[TARGET ACQUIRED]" -ForegroundColor Yellow -NoNewline; Write-Host " :: $path"
    $parentFolder = Split-Path $path
    if (-not (Test-Path $parentFolder)) {
        Write-Typing -Text "  -> Anomaly detected. Reconstructing missing directory structure..." -Color "Gray"
        $null = New-Item -ItemType Directory -Path $parentFolder -Force -ErrorAction SilentlyContinue
    }

    if (Lock-FileUltraSecure -TargetPath $path) {
        Write-Typing -Text "  [LOCKED] :: Target hardened. Threat vector neutralized."
        $processedPaths.Add($path.ToLower())
    } else {
        Write-Typing -Text "  [FAILURE] :: Countermeasures failed to deploy on target." -Color "Red"
        $overallSuccess = $false
    }
}

# --- PHASE 2: HUNTER-KILLER MODE ---
Write-Typing -Text "`n--- PHASE 2 :: ENGAGING HUNTER-KILLER MODE. SYSTEM-WIDE SWEEP INITIATED ---" -Color "Cyan"

try {
    # *** UPGRADE #2: MAX COMPATIBILITY CMDLET ***
    # Using Get-WmiObject for compatibility with PowerShell 2.0 (Windows 7) and newer.
    $localDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
} catch {
    Write-Typing -Text "[CRITICAL SENSOR FAILURE] :: Cannot enumerate local drives. Aborting deep scan." -Color "Red"
    $localDrives = @()
}

foreach ($drive in $localDrives) {
    $driveRoot = $drive.DeviceID + "\"
    Write-Typing -Text "`n[SCANNING SECTOR] :: $($driveRoot)... Analyzing file system for hostile signatures." -Color "Magenta"
    
    $foundFiles = Get-ChildItem -Path $driveRoot -Recurse -Filter "Gallery.exe" -File -ErrorAction SilentlyContinue
    
    if (-not $foundFiles) {
        Write-Typing -Text "  [CLEAR] :: No hostile signatures detected in this sector."
        continue
    }

    foreach ($file in $foundFiles) {
        if ($processedPaths.Contains($file.FullName.ToLower())) { Write-Verbose ":: Skipping previously neutralized target: $($file.FullName)" ; continue }

        Write-Host "`n[THREAT DETECTED]" -ForegroundColor Yellow -NoNewline; Write-Host " :: $($file.FullName)"
        Write-Typing -Text "  -> Deploying purge and quarantine protocol..." -Color "Magenta"

        if (Lock-FileUltraSecure -TargetPath $file.FullName) {
            Write-Typing -Text "  [NEUTRALIZED] :: Hostile entity purged and path quarantined."
            $processedPaths.Add($file.FullName.ToLower())
        } else {
            Write-Typing -Text "  [FAILURE] :: Could not neutralize this instance." -Color "Red"
            $overallSuccess = $false
        }
    }
}

# --- Final Summary ---
Write-Typing -Text "`n--- MISSION SUMMARY ---" -Color "Cyan"
if ($overallSuccess) {
    Write-Typing -Text "[ALL CLEAR] :: System integrity restored. All hostile signatures have been neutralized." -Color "Yellow"
} else {
    Write-Typing -Text "[WARNING] :: HOSTILE REMNANTS DETECTED. Full system purge was unsuccessful. Review logs for failed operations." -Color "Red"
}


# --- Call to Action ---
Write-Host @"

---------------------------------------------------------------------
⭐ If this script helped you, please consider starring the project! ⭐

It tells the developers that their work is valued and encourages
more updates and improvements.

➡️ GitHub Link: https://github.com/Opselon/Gallery.Exe.Virus.Remover

Thank you for your support!
---------------------------------------------------------------------
"@ -ForegroundColor Cyan
