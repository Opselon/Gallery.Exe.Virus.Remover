#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Gallery.exe (Grenam) Ultimate Killer Suite & Decoy Vaccinator.
.DESCRIPTION
    An enterprise-grade, all-in-one CLI tool to completely eradicate the Gallery.exe 
    (Grenam) malware. It features an interactive menu for discovering hidden files,
    restoring originals, cleaning fake executables, and deploying ultra-secure 
    0-byte decoy files to prevent future infections.
.FEATURES
    [1] Deep System Scan & CSV Reporting
    [2] Automatic Malware Eradication & File Restoration
    [3] Ultra-Secure File Vaccination (Hardcoded Decoys)
    [4] Windows Core System Repair (SFC & DISM)
.NOTES
    Version: 4.0 - Master CLI Edition
    Authors: Opselon, Jules & AI Assistant
#>

$ErrorActionPreference = "SilentlyContinue"
$Global:ReportPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Gallery_Infection_Report.csv"
$Global:ScanResults = @()

#================================================================================
# MODULE 1: UI & UX ENGINE
#================================================================================

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "STEP", "HEADER", "MENU")][string]$Level = "INFO",
        [Parameter(Mandatory=$false)][int]$Indent = 0
    )

    $colorMap = @{
        "INFO" = "Gray"; "SUCCESS" = "Green"; "WARN" = "Yellow"
        "ERROR" = "Red"; "STEP" = "Cyan"; "HEADER" = "Magenta"; "MENU" = "White"
    }
    $prefixMap = @{
        "INFO" = "[i]"; "SUCCESS" = "[✓]"; "WARN" = "[!]"; 
        "ERROR" = "[✗]"; "STEP" = "-->"; "HEADER" = "`n==="; "MENU" = ">>>"
    }

    $indentSpace = " " * ($Indent * 4)
    $prefix = $prefixMap[$Level]
    $color = $colorMap[$Level]
    Write-Host -ForegroundColor $color "$indentSpace$prefix $Message"
}

function Show-Banner {
    Clear-Host
    Write-Host @"

   ____      _ _                  _  ___ _ _           ____        _ _       
  / ___| __ _| | | ___ _ __ _   _| |/ (_) | | ___ _ __/ ___| _   _(_) |_ ___ 
 | |  _ / _` | | |/ _ \ '__| | | | ' /| | | |/ _ \ '__\___ \| | | | | __/ _ \
 | |_| | (_| | | |  __/ |  | |_| | . \| | | |  __/ |   ___) | |_| | | ||  __/
  \____|\__,_|_|_|\___|_|   \__, |_|\_\_|_|_|\___|_|  |____/ \__,_|_|\__\___|
                            |___/                                            
"@ -ForegroundColor Red

    Write-Host "┌────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ " -ForegroundColor Cyan -NoNewline; Write-Host " The Ultimate Remediation & Vaccination Suite for Grenam Malware  " -ForegroundColor White -NoNewline; Write-Host " │" -ForegroundColor Cyan
    Write-Host "├────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│  " -ForegroundColor Cyan -NoNewline; Write-Host "STATUS:" -ForegroundColor Gray -NoNewline; Write-Host " Ready | " -ForegroundColor Green -NoNewline; Write-Host "PRIVILEGES:" -ForegroundColor Gray -NoNewline; Write-Host " Administrator | " -ForegroundColor Green -NoNewline; Write-Host "VERSION:" -ForegroundColor Gray -NoNewline; Write-Host " 4.0 CLI Master   " -ForegroundColor Cyan -NoNewline; Write-Host "│" -ForegroundColor Cyan
    Write-Host "└────────────────────────────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
}

#================================================================================
# MODULE 2: DISCOVERY & REPORTING (SCANNER)
#================================================================================

function Invoke-Scan {
    Write-Log -Level HEADER -Message "INITIATING DEEP SCAN SEQUENCE"
    $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady } | ForEach-Object { $_.RootDirectory.FullName }
    $Global:ScanResults = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($drive in $drives) {
        Write-Log -Level INFO -Message "Scanning Volume: $drive ..."
        
        $gFiles = Get-ChildItem -Path $drive -Filter "g*.exe" -Recurse -File -Force | Where-Object { $_.Attributes -match "Hidden" }
        
        foreach ($file in $gFiles) {
            $originalName = $file.Name.Substring(1)
            $fakeExePath = Join-Path $file.DirectoryName $originalName
            $fakeIcoPath = Join-Path $file.DirectoryName ($file.BaseName + ".ico")

            $Global:ScanResults.Add([PSCustomObject]@{
                Directory      = $file.DirectoryName
                HiddenOriginal = $file.Name
                FakeExeName    = $originalName
                FakeExeExists  = (Test-Path $fakeExePath)
                FakeIcoExists  = (Test-Path $fakeIcoPath)
                Status         = "Infected"
            })
        }
    }

    if ($Global:ScanResults.Count -gt 0) {
        Write-Log -Level WARN -Message "Found $($Global:ScanResults.Count) infected items!"
        $Global:ScanResults | Export-Csv -Path $Global:ReportPath -NoTypeInformation -Encoding UTF8
        Write-Log -Level SUCCESS -Message "CSV Report generated at: $Global:ReportPath"
        Write-Log -Level INFO -Message "Proceed to Option [2] to clean and restore these files."
    } else {
        Write-Log -Level SUCCESS -Message "No hidden g*.exe clones found. Drives appear clean."
    }
    Pause-Execution
}

#================================================================================
# MODULE 3: REMEDIATION (CLEAN & RESTORE)
#================================================================================

function Invoke-CleanAndRestore {
    Write-Log -Level HEADER -Message "INITIATING CLEANSING AND RESTORATION"
    
    if (-not (Test-Path $Global:ReportPath) -and $Global:ScanResults.Count -eq 0) {
        Write-Log -Level ERROR -Message "No scan data found. Please run Option [1] first!"
        Pause-Execution
        return
    }

    # Load from CSV if memory is empty
    if ($Global:ScanResults.Count -eq 0) {
        $Global:ScanResults = Import-Csv -Path $Global:ReportPath
    }

    $restoredCount = 0
    $counter = 0

    foreach ($item in $Global:ScanResults) {
        $counter++
        $percent = [math]::Round(($counter / $Global:ScanResults.Count) * 100)
        Write-Progress -Activity "Eradicating Malware" -Status "Restoring: $($item.FakeExeName)" -PercentComplete $percent

        $hiddenPath = Join-Path $item.Directory $item.HiddenOriginal
        $fakeExePath = Join-Path $item.Directory $item.FakeExeName
        $fakeIcoPath = Join-Path $item.Directory ($item.HiddenOriginal.Replace(".exe", ".ico"))

        try {
            # 1. Kill Process
            $procName = [System.IO.Path]::GetFileNameWithoutExtension($fakeExePath)
            Stop-Process -Name $procName -Force 2>$null

            # 2. Obliterate Fakes
            if (Test-Path $fakeExePath) {
                attrib.exe -r -s -h "`"$fakeExePath`"" 2>$null
                Remove-Item -Path $fakeExePath -Force
            }
            if (Test-Path $fakeIcoPath) {
                attrib.exe -r -s -h "`"$fakeIcoPath`"" 2>$null
                Remove-Item -Path $fakeIcoPath -Force
            }

            # 3. Resurrect Original
            if (Test-Path $hiddenPath) {
                $hiddenItem = Get-Item $hiddenPath -Force
                $hiddenItem.Attributes = 'Archive'
                Rename-Item -Path $hiddenPath -NewName $item.FakeExeName -Force -ErrorAction Stop
                
                $item.Status = "Restored"
                $restoredCount++
            }
        } catch {
            $item.Status = "Failed"
            Write-Log -Level ERROR -Message "Failed to restore $($item.FakeExeName)"
        }
    }
    
    Write-Progress -Activity "Eradicating Malware" -Completed
    $Global:ScanResults | Export-Csv -Path $Global:ReportPath -NoTypeInformation -Encoding UTF8
    
    Write-Log -Level SUCCESS -Message "Restored $restoredCount out of $($Global:ScanResults.Count) files."
    Write-Log -Level INFO -Message "Updated CSV log saved to Desktop."
    Pause-Execution
}

#================================================================================
# MODULE 4: VACCINATION (HARDCODED DECOYS)
#================================================================================

function Invoke-Vaccination {
    Write-Log -Level HEADER -Message "INITIATING SYSTEM VACCINATION (HARDCODED DECOYS)"
    
    $decoyTargets = @(
        @{ Path = Join-Path $env:APPDATA "Gallery.exe"; Desc = "AppData\Roaming" },
        @{ Path = Join-Path $env:APPDATA "gallery\Gallery.exe"; Desc = "AppData\Roaming\gallery" },
        @{ Path = Join-Path $env:LOCALAPPDATA "Gallery.exe"; Desc = "AppData\Local" },
        @{ Path = Join-Path ([Environment]::GetFolderPath('Startup')) "Gallery.exe"; Desc = "Startup Folder" },
        @{ Path = Join-Path $env:TEMP "Gallery.exe"; Desc = "User Temp" },
        @{ Path = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"; Desc = "SysWOW64 Profile" },
        @{ Path = "C:\Windows\System32\config\systemprofile\AppData\Roaming\Gallery.exe"; Desc = "System32 Profile" },
        @{ Path = Join-Path $env:windir "Temp\Gallery.exe"; Desc = "Windows Temp" }
    )

    $successCount = 0

    foreach ($target in $decoyTargets) {
        Write-Log -Level STEP -Message "Locking: $($target.Desc)"
        $TargetPath = $target.Path

        # Check NTFS
        $drive = Get-PSDrive -Name ($TargetPath.Split(':')[0]) 2>$null
        if (-not $drive -or $drive.FileSystem -ne 'NTFS') {
            Write-Log -Level ERROR -Message "Skipped (Not NTFS): $TargetPath" -Indent 1
            continue
        }

        # Parent Dir
        $parentDir = Split-Path $TargetPath -Parent
        if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }

        # Delete existing & Create Decoy
        if (Test-Path $TargetPath -PathType Leaf) {
            takeown /f $TargetPath /a 2>$null | Out-Null
            icacls $TargetPath /reset /t /c /q 2>$null | Out-Null
            Remove-Item -Path $TargetPath -Force 2>$null
        }
        New-Item -ItemType File -Path $TargetPath -Force | Out-Null

        # Lock Down Attributes and ACL
        try {
            Set-ItemProperty -Path $TargetPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force
            
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
            Set-Acl -Path $TargetPath -AclObject $acl
            
            $successCount++
            Write-Log -Level SUCCESS -Message "Vaccine Deployed Successfully." -Indent 1
        } catch {
            Write-Log -Level ERROR -Message "ACL Lock Failed: $($_.Exception.Message)" -Indent 1
        }
    }

    Write-Log -Level INFO -Message "------------------------------------------------"
    if ($successCount -eq $decoyTargets.Count) {
        Write-Log -Level SUCCESS -Message "All $successCount decoys deployed! System is bulletproof."
    } else {
        Write-Log -Level WARN -Message "Deployed $successCount out of $($decoyTargets.Count) decoys. Some system paths may be restricted."
    }
    Pause-Execution
}

#================================================================================
# MODULE 5: SYSTEM REPAIR
#================================================================================

function Invoke-SystemRepair {
    Write-Log -Level HEADER -Message "INITIATING WINDOWS CORE REPAIR (DISM & SFC)"
    Write-Log -Level WARN -Message "This process may take 10-20 minutes. Do not close the window."
    
    Write-Log -Level STEP -Message "Running DISM (Deployment Image Servicing and Management)..."
    DISM.exe /Online /Cleanup-Image /RestoreHealth
    
    Write-Log -Level STEP -Message "Running SFC (System File Checker)..."
    sfc /scannow

    Write-Log -Level SUCCESS -Message "Core system verification complete!"
    Pause-Execution
}

#================================================================================
# HELPER & MENU
#================================================================================

function Pause-Execution {
    Write-Host "`nPress any key to return to the Main Menu..." -ForegroundColor DarkGray
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-Menu {
    Show-Banner
    Write-Host "  [1]" -ForegroundColor Yellow -NoNewline; Write-Host " Scan System for Infected/Hidden Files & Export CSV" -ForegroundColor White
    Write-Host "  [2]" -ForegroundColor Yellow -NoNewline; Write-Host " Clean Fakes & Restore Original Executables" -ForegroundColor White
    Write-Host "  [3]" -ForegroundColor Yellow -NoNewline; Write-Host " Deploy Hardcoded Decoy Vaccines (Lockdown)" -ForegroundColor White
    Write-Host "  [4]" -ForegroundColor Yellow -NoNewline; Write-Host " Run Windows System Repair (SFC & DISM)" -ForegroundColor White
    Write-Host "  [0]" -ForegroundColor Red -NoNewline; Write-Host " Exit Tool`n" -ForegroundColor DarkGray
}

#================================================================================
# MAIN CLI LOOP
#================================================================================

$isRunning = $true

while ($isRunning) {
    Show-Menu
    $choice = Read-Host "  Enter your choice (0-4)"

    switch ($choice) {
        '1' { Invoke-Scan }
        '2' { Invoke-CleanAndRestore }
        '3' { Invoke-Vaccination }
        '4' { Invoke-SystemRepair }
        '0' { 
            Write-Log -Level SUCCESS -Message "Exiting Gallery Killer Suite. Stay safe!"
            Start-Sleep -Seconds 2
            $isRunning = $false 
        }
        Default { 
            Write-Log -Level ERROR -Message "Invalid selection. Please enter a number between 0 and 4."
            Start-Sleep -Seconds 2
        }
    }
}
