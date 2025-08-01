#Requires -RunAsAdministrator

<#
.SYNOPSIS
    A comprehensive tool to find, remove, and block the "Gallery.exe" malware.
.DESCRIPTION
    This all-in-one script systematically neutralizes and eradicates the "Gallery.exe" Trojan from a system.
    It follows a multi-phase approach:
    1.  NEUTRALIZE: Terminates active malware processes, services, and scheduled tasks.
    2.  REMOVE: Scans the entire C: drive for the executable, cleans malicious registry entries, and sanitizes browser shortcuts.
    3.  PREVENT & CLEAN: Creates ultra-secure, zero-byte decoy files in common malware locations to block re-infection and clears system temp files.
    
    All actions are logged in real-time to the console and a permanent log file for auditing.
.NOTES
    Author: Opselon (github.com/Opselon)
    Upgraded by: Jules & Gemini
    Version: 8.1 (Fixed critical bug in scheduled task detection logic)
#>

#================================================================================
# SCRIPT CONFIGURATION
#================================================================================

# --- Malware Definition ---
$malwareFileName = "Gallery.exe"
$malwareBaseName = "Gallery"

# --- Decoy File Targets ---
$decoyTargets = @(
    @{ Path = Join-Path $env:APPDATA $malwareFileName; Description = "User Profile (AppData\Roaming)" },
    @{ Path = Join-Path $env:APPDATA "gallery\$malwareFileName"; Description = "User Profile (AppData\Roaming\gallery)" },
    @{ Path = Join-Path $env:LOCALAPPDATA $malwareFileName; Description = "User Profile (AppData\Local)" },
    @{ Path = Join-Path ([Environment]::GetFolderPath('Startup')) $malwareFileName; Description = "User Startup Folder" },
    @{ Path = Join-Path $env:TEMP $malwareFileName; Description = "User Temp Folder" },
    @{ Path = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\$malwareFileName"; Description = "System Profile (32-bit)" },
    @{ Path = "C:\Windows\System32\config\systemprofile\AppData\Roaming\$malwareFileName"; Description = "System Profile (64-bit)" },
    @{ Path = Join-Path $env:windir "Temp\$malwareFileName"; Description = "Windows Temp Folder" },
    @{ Path = "C:\Program Files\gallery\$malwareFileName"; Description = "Program Files (gallery)" },
    @{ Path = Join-Path $env:windir $malwareFileName; Description = "Windows Directory" }
)

# --- Professional Logging Setup ---
$logDirectory = "C:\ProgramData\Opselon\GalleryExeRemovalTool\Logs"
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $logDirectory "RemovalLog-$timestamp.log"

#================================================================================
# UI & LOGGING FUNCTIONS
#================================================================================

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "ACTION", "FATAL")]
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
            "ACTION"  { "Magenta" }
            default   { "Gray" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Show-Header {
    Clear-Host
    $borderColor = "Magenta"
    $titleColor = "White"
    $textColor = "Gray"
    $authorColor = "Cyan"

    Write-Host "
    ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "     Gallery.exe Full Removal & Protection Tool v8.1      " -ForegroundColor $titleColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "           (CRITICAL BUG FIXED in Task Detection)         " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "                       by " -ForegroundColor $textColor; Write-Host "Opselon, Jules & Gemini" -ForegroundColor $authorColor; Write-Host "         ║" -ForegroundColor $borderColor
    Write-Host "    ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "  This script will Neutralize, Remove, and Block the     " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "  $($malwareFileName) malware from all known locations.             " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
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
# CORE REMOVAL & PREVENTION FUNCTIONS
#================================================================================

# Corresponds to Manual Step 3
function Terminate-MaliciousProcesses {
    Write-SectionHeader -Title "Phase 1.1: Terminating Malicious Processes"
    Write-Log -Message "Searching for active processes named '$malwareBaseName'."
    $processes = Get-Process -Name $malwareBaseName -ErrorAction SilentlyContinue
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                $path = $proc.Path
                Write-Log -Message "Malicious process found: $($proc.Name) (PID: $($proc.Id)) at '$path'." -Level "WARN"
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Write-Log -Message "Successfully terminated process PID: $($proc.Id)." -Level "SUCCESS"
            } catch {
                Write-Log -Message "Failed to terminate process PID: $($proc.Id). Reason: $($_.Exception.Message)" -Level "ERROR"
            }
        }
    } else {
        Write-Log -Message "No active malicious processes found." -Level "SUCCESS"
    }
}

# Corresponds to Manual Step 4
function Remove-MaliciousServices {
    Write-SectionHeader -Title "Phase 1.2: Removing Malicious Services"
    Write-Log -Message "Searching for services related to '$malwareBaseName'."
    $services = Get-CimInstance -ClassName Win32_Service | Where-Object { $_.Name -like "*$malwareBaseName*" -or $_.DisplayName -like "*$malwareBaseName*" -or $_.PathName -like "*$malwareFileName*" }
    if ($services) {
        foreach ($service in $services) {
            $serviceName = $service.Name
            Write-Log -Message "Malicious service found: '$($service.DisplayName)' (Name: $serviceName)." -Level "WARN"
            try {
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                Write-Log -Message "Service '$serviceName' stopped." -Level "ACTION"
                Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
                Write-Log -Message "Service '$serviceName' startup type set to Disabled." -Level "ACTION"
                # For complete removal, we use sc.exe
                sc.exe delete "$serviceName" | Out-Null
                Write-Log -Message "Successfully removed service '$serviceName'." -Level "SUCCESS"
            } catch {
                Write-Log -Message "Failed to remove service '$serviceName'. Reason: $($_.Exception.Message)" -Level "ERROR"
            }
        }
    } else {
        Write-Log -Message "No malicious services found." -Level "SUCCESS"
    }
}

# Corresponds to Manual Step 5
function Remove-MaliciousScheduledTasks {
    Write-SectionHeader -Title "Phase 1.3: Removing Malicious Scheduled Tasks"
    Write-Log -Message "Searching for scheduled tasks specifically related to '$malwareFileName'."
    
    # [FIXED in v8.1] This corrected logic properly checks if any of the properties contain the malware strings.
    # It will no longer produce false positives on all system tasks.
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $task = $_ # Use a temporary variable for clarity inside the script block
        ( $task.TaskName -like "*$malwareBaseName*" ) -or
        ( $task.Actions | Where-Object { $_.Execute -like "*$malwareFileName*" } ) -or
        ( $task.Triggers | Where-Object { $_.Id -like "*$malwareBaseName*" } )
    }

    if ($tasks) {
        foreach ($task in $tasks) {
            Write-Log -Message "Malicious scheduled task found: '$($task.TaskPath)$($task.TaskName)'." -Level "WARN"
            try {
                Unregister-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
                Write-Log -Message "Successfully removed scheduled task '$($task.TaskName)'." -Level "SUCCESS"
            } catch {
                Write-Log -Message "Failed to remove scheduled task '$($task.TaskName)'. Reason: $($_.Exception.Message)" -Level "ERROR"
            }
        }
    } else {
        Write-Log -Message "No malicious scheduled tasks found." -Level "SUCCESS"
    }
}

# Corresponds to Manual Step 6
function Clean-RegistryPersistence {
    Write-SectionHeader -Title "Phase 2.1: Cleaning Registry Persistence"
    Write-Log -Message "Scanning common registry autorun locations."
    $removedCount = 0
    $runKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    )

    foreach ($key in $runKeys) {
        if (Test-Path $key) {
            try {
                $properties = Get-ItemProperty -Path $key -ErrorAction Stop
                foreach ($prop in $properties.PSObject.Properties) {
                    $propName = $prop.Name
                    $propValue = $prop.Value
                    if ($propValue -like "*$malwareFileName*") {
                        Write-Log -Message "Found malicious registry value '$propName' in key '$key'." -Level "WARN"
                        Remove-ItemProperty -Path $key -Name $propName -Force -ErrorAction Stop
                        Write-Log -Message "Successfully removed registry value '$propName'." -Level "SUCCESS"
                        $removedCount++
                    }
                }
            } catch {
                Write-Log -Message "Could not access or process registry key '$key'. Reason: $($_.Exception.Message)" -Level "ERROR"
            }
        }
    }
    
    if ($removedCount -eq 0) {
        Write-Log -Message "No malicious autorun entries found in the registry." -Level "SUCCESS"
    }
}

# Corresponds to Manual Step 1
function Sanitize-BrowserShortcuts {
    Write-SectionHeader -Title "Phase 2.2: Sanitizing Shortcuts"
    $locations = @(
        [Environment]::GetFolderPath("Desktop"),
        [Environment]::GetFolderPath("StartMenu"),
        [Environment]::GetFolderPath("CommonStartMenu"),
        "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    )
    $shell = New-Object -ComObject WScript.Shell
    $sanitizedCount = 0

    foreach ($location in $locations) {
        if (Test-Path $location) {
            $shortcuts = Get-ChildItem -Path $location -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue
            foreach ($shortcutFile in $shortcuts) {
                try {
                    $link = $shell.CreateShortcut($shortcutFile.FullName)
                    if ($link.TargetPath -like "*$malwareFileName*" -or $link.Arguments -like "*$malwareFileName*") {
                        Write-Log -Message "Found malicious shortcut: $($shortcutFile.FullName)" -Level "WARN"
                        Write-Log -Message "Original Target: $($link.TargetPath)" -Level "WARN"
                        Write-Log -Message "Original Arguments: $($link.Arguments)" -Level "WARN"
                        
                        # Attempt to fix by removing the malware part
                        $originalTargetPath = $link.TargetPath
                        $link.TargetPath = ($link.TargetPath -split "$malwareFileName")[0]
                        $link.Arguments = ($link.Arguments -replace "(?i)$malwareFileName", "").Trim()

                        # If the path now points to a fake browser, delete the shortcut
                        if ($link.TargetPath -notlike "*\chrome.exe" -and $link.TargetPath -notlike "*\msedge.exe" -and $link.TargetPath -notlike "*\firefox.exe") {
                             Remove-Item -Path $shortcutFile.FullName -Force
                             Write-Log -Message "Shortcut pointed to fake browser. DELETED: $($shortcutFile.FullName)" -Level "SUCCESS"
                        } else {
                            $link.Save()
                            Write-Log -Message "Sanitized shortcut. New Target: $($link.TargetPath)" -Level "SUCCESS"
                        }
                        $sanitizedCount++
                    }
                } catch {
                    Write-Log -Message "Could not process shortcut '$($shortcutFile.FullName)'. It might be broken." -Level "ERROR"
                }
            }
        }
    }
    if ($sanitizedCount -eq 0) {
        Write-Log -Message "No infected browser or application shortcuts found." -Level "SUCCESS"
    }
}

# Corresponds to deep scan part of manual analysis
function FindAndRemove-MaliciousFiles {
    Write-SectionHeader -Title "Phase 2.3: Deep Scan & Removal of Malicious Files"
    Write-Log -Message "Starting deep scan for '$malwareFileName' on drive C:\. This may take time."
    try {
        $foundFiles = Get-ChildItem -Path "C:\" -Filter $malwareFileName -Recurse -File -ErrorAction SilentlyContinue -Force
        if ($foundFiles) {
            Write-Log -Message "Found existing '$malwareFileName' files. Attempting removal." -Level "WARN"
            foreach ($file in $foundFiles) {
                Write-Log -Message "  - Found at: $($file.FullName)" -Level "WARN"
                try {
                    # Attempt to take ownership and reset permissions before deleting
                    takeown /f $file.FullName /a | Out-Null
                    icacls $file.FullName /reset /t /c /q | Out-Null
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    Write-Log -Message "  - Successfully DELETED file: $($file.FullName)" -Level "SUCCESS"
                } catch {
                    Write-Log -Message "  - FAILED to delete file: $($file.FullName). Reason: $($_.Exception.Message)" -Level "ERROR"
                }
            }
        } else {
            Write-Log -Message "No existing '$malwareFileName' files found on the C: drive." -Level "SUCCESS"
        }
    } catch {
        Write-Log -Message "An error occurred during the deep scan: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Corresponds to Manual Step 10
function Clear-SystemJunk {
    Write-SectionHeader -Title "Phase 3.1: Clearing System Cache & Temp Files"
    try {
        Write-Log -Message "Clearing user temp folder..." -Level "ACTION"
        Remove-Item -Path (Join-Path $env:TEMP '*') -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log -Message "Clearing Windows temp folder..." -Level "ACTION"
        Remove-Item -Path (Join-Path $env:windir 'Temp\*') -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log -Message "Clearing Recycle Bin..." -Level "ACTION"
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log -Message "System junk files cleared successfully." -Level "SUCCESS"
    } catch {
        Write-Log -Message "An error occurred while clearing junk files: $($_.Exception.Message)" -Level "ERROR"
    }
}

# The original script's core function, now part of the prevention phase
function Apply-DecoyProtection {
    Write-SectionHeader -Title "Phase 3.2: Applying Decoy File Protection"
    $processedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($target in $decoyTargets) {
        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target.Path)
        Write-Log -Message "--- Processing Target: $($target.Description) ---"
        
        if ($processedPaths.Add($resolvedPath)) {
            $result = Lock-FileUltraSecure -TargetPath $resolvedPath
            if ($result.Success) {
                Write-Log -Message $result.Message -Level "SUCCESS"
            } else {
                Write-Log -Message $result.Message -Level "ERROR"
            }
        } else {
            Write-Log -Message "Path '$resolvedPath' has already been processed. Skipping." -Level "WARN"
        }
    }
}

# Helper for the decoy function
function Lock-FileUltraSecure {
    param([Parameter(Mandatory=$true)] [string]$TargetPath)

    $result = [PSCustomObject]@{ Success = $false; Message = "" }
    try {
        $parentDir = Split-Path $TargetPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
        }
        if (Test-Path $TargetPath) { Remove-Item -Path $TargetPath -Force -ErrorAction SilentlyContinue }
        
        New-Item -ItemType File -Path $TargetPath -Force -ErrorAction Stop | Out-Null
        Set-ItemProperty -Path $TargetPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force
        
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
        Set-Acl -Path $TargetPath -AclObject $acl -ErrorAction Stop
        
        $result.Success = $true
        $result.Message = "Decoy created and secured at '$TargetPath'."
    } catch {
        $result.Message = "FAIL: Could not create decoy at '$TargetPath'. Reason: $($_.Exception.Message)"
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

Write-Host "`nThis script will perform a full system scan and removal for '$malwareFileName'." -ForegroundColor "Yellow"
Write-Host "It is recommended to save all work and close other applications." -ForegroundColor "Yellow"
Write-Host "`nPress any key to begin the full removal process..." -ForegroundColor "Yellow"
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
Write-Host ""

# --- PHASE 1: NEUTRALIZE ---
Terminate-MaliciousProcesses
Remove-MaliciousServices
Remove-MaliciousScheduledTasks

# --- PHASE 2: REMOVE ---
Clean-RegistryPersistence
Sanitize-BrowserShortcuts
FindAndRemove-MaliciousFiles

# --- PHASE 3: PREVENT & CLEAN ---
Clear-SystemJunk
Apply-DecoyProtection

# --- FINAL SUMMARY & RECOMMENDATION ---
Write-SectionHeader -Title "Scan & Removal Complete"
Write-Log -Message "All removal and protection steps have been executed." -Level "SUCCESS"
Write-Log -Message "A detailed log has been saved to: $logFile" -Level "INFO"
Write-Log -Message "For the changes to take full effect and to ensure all remnants are gone, a system REBOOT is strongly recommended." -Level "WARN"

# --- GitHub Shoutout ---
$borderColor = "Magenta"; $textColor = "Gray"; $starColor = "Yellow"; $urlColor = "Cyan"
Write-Host "

    ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "   If you found this script useful, please give it a star " -ForegroundColor $textColor; Write-Host "★" -ForegroundColor $starColor; Write-Host "   ║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host "                 on GitHub to show your support!           " -ForegroundColor $textColor; Write-Host "║" -ForegroundColor $borderColor
    Write-Host "    ║" -NoNewline -ForegroundColor $borderColor; Write-Host " " -NoNewline; Write-Host "github.com/Opselon/Gallery.Exe.Virus.Remover" -ForegroundColor $urlColor; Write-Host "           ║" -ForegroundColor $borderColor
    Write-Host "    ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $borderColor

Write-Host "`n"
