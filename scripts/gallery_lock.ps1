#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates ultra-secure, zero-byte decoy files to block "Gallery.exe" malware, featuring a deep file search and live, persistent logging.
.DESCRIPTION
    This script vaccinates a system against "Gallery.exe" malware. It first performs a deep search of the C: drive
    to find and report any existing instances. It then pre-emptively creates empty, locked-down decoy files in
    common and potential malware drop locations. All actions are logged in real-time to both the console and a permanent log file.

    This version (7.1) includes compatibility fixes for older PowerShell environments to prevent errors with console output and formatting.
.NOTES
    Author: Opselon (github.com/Opselon)
    Upgraded by: Jules & Gemini
    Version: 7.1
#>

#================================================================================
# SCRIPT CONFIGURATION & LOGGING SETUP
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
    @{ Path = Join-Path $env:windir "Temp\Gallery.exe"; Description = "Windows Temp Folder" },
    @{ Path = "C:\Program Files\gallery\Gallery.exe"; Description = "Program Files (gallery)" },
    @{ Path = Join-Path $env:windir "Gallery.exe"; Description = "Windows Directory" }
)

# --- Professional Logging Setup ---
$logDirectory = "C:\ProgramData\Opselon\GalleryExeDecoyTool\Logs"
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $logDirectory "DecoyLog-$timestamp.log"


#================================================================================
# UI & LOGGING FUNCTIONS
#================================================================================

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "FATAL")]
        [string]$Level = "INFO",
        
        [switch]$ToFileOnly
    )

    $logTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$logTimestamp [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry

    if (-not $ToFileOnly) {
        $color = switch ($Level) {
            "SUCCESS" { "Green" }
            "WARN"    { "Yellow" }
            "ERROR"   { "Red" }
            "FATAL"   { "DarkRed" }
            default   { "Gray" }
        }
        # Simplified output for maximum compatibility
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Show-Header {
    Clear-Host
    $borderColor = "Magenta"
    $titleColor = "White"
    $textColor = "Gray"
    $authorColor = "Cyan"

    # This part remains visual and is not logged line-by-line.
    Write-Host "
    ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "         Gallery.exe Malware Decoy Tool v7.1            " -ForegroundColor $titleColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "           (Now with Live Professional Logging)           " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "                       by " -ForegroundColor $textColor; Write-Host "Opselon" -ForegroundColor $authorColor; Write-Host "                          ║" -ForegroundColor $borderColor
    Write-Host "    ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "  This script creates locked decoy files to block known    " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "  malware paths after performing a deep file search.     " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $borderColor
    Write-Host ""

    Write-Log -Message "Log session started. Log file: $logFile" -ToFileOnly
    Write-Log -Message "Running with Administrator privileges..." -Level "WARN"
}

function Write-SectionHeader {
    param([string]$Title)
    $borderColor = "Cyan"
    $titleText = " $Title "
    $paddingLength = [Math]::Floor((56 - $titleText.Length) / 2)
    $padding = "═" * $paddingLength
    $headerLine = "    ╔$($padding)$($titleText)$($padding)╗"
    
    Write-Host ""
    Write-Host $headerLine -ForegroundColor $borderColor
    Write-Host ""
    Write-Log -Message "================== $Title ==================" -ToFileOnly
}

#================================================================================
# CORE SCRIPT FUNCTIONS
#================================================================================

function Find-GalleryExe {
    Write-SectionHeader -Title "Deep Scan for Gallery.exe"
    Write-Log -Message "Starting a deep search for 'gallery.exe' on the C: drive. This may take a few moments..."
    try {
        $foundFiles = Get-ChildItem -Path "C:\" -Filter "gallery.exe" -Recurse -File -ErrorAction SilentlyContinue -Force
        if ($foundFiles) {
            Write-Log -Message "Found existing 'gallery.exe' files. These should be manually investigated and removed." -Level "WARN"
            $foundFiles.FullName | ForEach-Object { Write-Log -Message "  - Found at: $_" -Level "WARN" }
        } else {
            Write-Log -Message "No existing 'gallery.exe' files found on the C: drive." -Level "SUCCESS"
        }
    } catch {
        Write-Log -Message "An error occurred during the deep scan: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Lock-FileUltraSecure {
    param(
        [Parameter(Mandatory=$true)] [string]$TargetPath,
        [Parameter(Mandatory=$true)] [string]$Description
    )

    $result = [PSCustomObject]@{
        Path = $TargetPath
        Description = $Description
        Success = $false
        Message = ""
    }

    try {
        # Pre-flight Checks
        $drive = Get-PSDrive -Name ($TargetPath.Split(':')[0]) -ErrorAction Stop
        if ($drive.FileSystem -ne 'NTFS') { throw "Target path is not on an NTFS drive. ACLs cannot be applied." }
        
        $parentDir = Split-Path $TargetPath -Parent
        if (-not (Test-Path $parentDir)) {
            Write-Log -Message "Parent directory not found. Creating '$parentDir'."
            New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
        }

        # Delete Pre-existing File
        if (Test-Path $TargetPath -PathType Leaf) {
            Write-Log -Message "Existing file found at '$TargetPath'. Taking ownership and removing..." -Level "WARN"
            takeown /f $TargetPath /a | Out-Null
            icacls $TargetPath /reset /t /c /q | Out-Null
            Remove-Item -Path $TargetPath -Force -ErrorAction Stop
        }

        # Create Decoy and Apply Security
        Write-Log -Message "Creating 0-byte decoy file at '$TargetPath'."
        New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop | Out-Null
        
        Write-Log -Message "Setting Hidden & System attributes."
        Set-ItemProperty -Path $TargetPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force -ErrorAction Stop
        
        Write-Log -Message "Applying strict ACLs (Deny Everyone, Allow SYSTEM)."
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false) # Disable inheritance
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop

    } catch {
        $result.Message = "FAIL: $($_.Exception.Message)"
        return $result
    }

    # Final Verification
    if (Test-Path $TargetPath -PathType Leaf) {
        if ((Get-Item -Path $TargetPath -Force).Length -eq 0) {
            $result.Success = $true
            $result.Message = "Decoy created and secured."
        } else {
            $result.Message = "FAIL: Verification failed. File is not empty."
        }
    } else {
        $result.Message = "FAIL: File disappeared after creation. LIKELY AN ANTIVIRUS INTERFERENCE."
    }
    
    return $result
}

#================================================================================
# MAIN EXECUTION
#================================================================================

Show-Header

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Log -Message "This script must be run as an Administrator. Please re-launch from an elevated PowerShell prompt." -Level "FATAL"
    Start-Sleep -Seconds 7; exit 1
}

Find-GalleryExe

Write-Host "`nPress any key to begin the vaccination process..." -ForegroundColor "Yellow"
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
Write-Host "" # Newline after keypress

Write-SectionHeader -Title "Applying Decoy Files"

$allResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$processedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($target in $decoyTargets) {
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target.Path)
    Write-Log -Message "--- Processing Target: $($target.Description) ---"
    
    if ($processedPaths.Add($resolvedPath)) {
        $result = Lock-FileUltraSecure -TargetPath $resolvedPath -Description $target.Description
        if ($result.Success) {
            Write-Log -Message $result.Message -Level "SUCCESS"
        } else {
            Write-Log -Message $result.Message -Level "ERROR"
        }
        $allResults.Add($result)
    } else {
        Write-Log -Message "Path '$resolvedPath' has already been processed. Skipping." -Level "WARN"
    }
    Write-Host "" # Add a blank line for readability between targets
}

# --- Final Summary ---
Write-SectionHeader -Title "Execution Summary"

# COMPATIBILITY FIX: Removed dynamic coloring from the Format-Table definition.
$ft = @{
    Expression = { if ($_.Success) { "[SUCCESS]" } else { "[FAILURE]" } }
    Label = "Status"
    Width = 12
}

# Log summary to file
Write-Log -Message "================== Final Summary ==================" -ToFileOnly
foreach ($res in $allResults) {
    $status = if ($res.Success) { "SUCCESS" } else { "FAILURE" }
    Write-Log -Message "[$status] - $($res.Description) - $($res.Path) - $($res.Message)" -ToFileOnly
}

# Display summary table on console
$allResults | Format-Table $ft, Description, Path, Message -AutoSize -Wrap

$failedCount = ($allResults | Where-Object { -not $_.Success }).Count
if ($failedCount -eq 0) {
    Write-Log -Message "All decoys were created successfully! System is protected." -Level "SUCCESS"
} else {
    Write-Log -Message "One or more decoys failed. Please review the summary and log file for details." -Level "WARN"
}

Write-Log -Message "Script execution finished. A detailed log has been saved to: $logFile" -Level "INFO"

# --- GitHub Shoutout ---
$borderColor = "Magenta"; $textColor = "Gray"; $starColor = "Yellow"; $urlColor = "Cyan"
Write-Host "

    ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "   If you found this script useful, please give it a star " -ForegroundColor $textColor; Write-Host "★" -ForegroundColor $starColor; Write-Host "   ║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "                 on GitHub to show your support!           " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host " " -NoNewline; Write-Host "github.com/Opselon/Gallery.Exe.Virus.Remover" -ForegroundColor $urlColor; Write-Host "           ║" -ForegroundColor $borderColor
    Write-Host "    ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $borderColor

Write-Host "`n"
