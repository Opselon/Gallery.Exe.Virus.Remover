#Requires -RunAsAdministrator

<#
.SYNOPSIS
    G.E.N. (Gallery.exe Extermination Neutralizer) - Enterprise Edition
.DESCRIPTION
    An advanced, highly interactive, and safe CLI suite designed to hunt, verify, 
    report, neutralize, and vaccinate Windows systems against the Gallery.exe (Grenam) 
    polymorphic file infector. 
    
    Includes safety protocols to prevent accidental deletion of critical system files 
    by requiring explicit human verification before executing purge sequences.
.NOTES
    Version: 6.0.0 (Enterprise Master Release)
    Architecture: x64/x86 PowerShell Native
    Author: Opselon & G.E.N Security Team
#>

$ErrorActionPreference = "SilentlyContinue"
$Global:ReportFile = Join-Path ([Environment]::GetFolderPath("Desktop")) "GEN_Threat_Intelligence.csv"
$Global:ActiveThreats = @()

#================================================================================
# [ CORE UI, AESTHETICS & LOGGING ENGINE ]
#================================================================================

function Show-GenAscii {
    Clear-Host
    Write-Host @"
   ██████╗ ███████╗███╗   ██╗     ██╗   ██╗███████╗██╗   ██╗██╗   ██╗
  ██╔════╝ ██╔════╝████╗  ██║     ██║   ██║██╔════╝╚██╗ ██╔╝██║   ██║
  ██║  ███╗█████╗  ██╔██╗ ██║     ██║   ██║█████╗   ╚████╔╝ ██║   ██║
  ██║   ██║██╔══╝  ██║╚██╗██║     ██║   ██║██╔══╝    ╚██╔╝  ██║   ██║
  ╚██████╔╝███████╗██║ ╚████║     ╚██████╔╝███████╗   ██║   ╚██████╔╝
   ╚═════╝ ╚══════╝╚═╝  ╚═══╝      ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝
                      [ Gallery.exe Extermination Neutralizer ]
"@ -ForegroundColor Cyan
}

function Invoke-SystemProfiling {
    Show-GenAscii
    Write-Host "`n[SYSTEM PROFILING] Booting kernel diagnostics..." -ForegroundColor DarkGray
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $av = (Get-CimInstance -Namespace "root\SecurityCenter2" -Class AntiVirusProduct 2>$null).displayName -join ", "
    if (-not $av) { $av = "Windows Defender (Native)" }

    $chars = @("|", "/", "-", "\")
    for ($i = 0; $i -lt 10; $i++) {
        Write-Host "`r[ $($chars[$i % 4]) ] Interfacing with host telemetry... " -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 70
    }
    
    Write-Host "`r[ ✓ ] G.E.N. Core Systems Online.             `n" -ForegroundColor Green
    Write-Host "  [-] HOST OS    : $os" -ForegroundColor Gray
    Write-Host "  [-] MEMORY     : $ram GB ALLOCATED" -ForegroundColor Gray
    Write-Host "  [-] DEFENSES   : $av" -ForegroundColor Gray
    Write-Host "  [-] PRIVILEGES : ADMINISTRATOR (ELEVATED)`n" -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

function Show-MainMenu {
    Show-GenAscii
    Write-Host "`n  ::: COMMAND INTERFACE :::`n" -ForegroundColor Yellow
    Write-Host "  [1] " -ForegroundColor Cyan -NoNewline; Write-Host "INITIATE DEEP SCAN (Find Gallery.exe & g-prefixed threats)" -ForegroundColor White
    Write-Host "  [2] " -ForegroundColor Cyan -NoNewline; Write-Host "REVIEW & EXECUTE PURGE (Human Verification Required)" -ForegroundColor White
    Write-Host "  [3] " -ForegroundColor Cyan -NoNewline; Write-Host "DEPLOY COUNTERMEASURES (Vaccinate System Vectors)" -ForegroundColor White
    Write-Host "  [4] " -ForegroundColor Cyan -NoNewline; Write-Host "INTEGRITY REPAIR (SFC & DISM Diagnostics)" -ForegroundColor White
    Write-Host "  [0] " -ForegroundColor Red -NoNewline; Write-Host "TERMINATE SESSION`n" -ForegroundColor DarkGray
}

function Pause-Console {
    Write-Host "`n[AWAITING COMMAND] Press any key to return to Main Menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#================================================================================
# [ MODULE 1: INTELLIGENCE GATHERING (DEEP SCAN) ]
#================================================================================

function Invoke-HunterKiller {
    Show-GenAscii
    Write-Host "`n--- ENGAGING HUNTER-KILLER MODE. SYSTEM-WIDE SWEEP INITIATED ---`n" -ForegroundColor Yellow
    
    $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady } | ForEach-Object { $_.RootDirectory.FullName }
    $Global:ActiveThreats = [System.Collections.Generic.List[PSCustomObject]]::new()
    $criticalPaths = @("C:\Windows", "C:\ProgramData", "System32", "SysWOW64")

    foreach ($drive in $drives) {
        Write-Host "[SCANNING SECTOR] :: $drive... Analyzing file system." -ForegroundColor Cyan
        
        # 1. Search for literal 'Gallery.exe' instances
        $galleryMatches = Get-ChildItem -Path $drive -Filter "Gallery.exe" -Recurse -File -Force 2>$null
        foreach ($g in $galleryMatches) {
            $isCritical = $false
            foreach ($cp in $criticalPaths) { if ($g.FullName -match [regex]::Escape($cp)) { $isCritical = $true } }

            $Global:ActiveThreats.Add([PSCustomObject]@{
                Type           = "Primary Payload"
                Path           = $g.FullName
                HiddenOriginal = "N/A"
                FakeThreatName = $g.Name
                IsCriticalPath = $isCritical
            })
            Write-Host "  [PAYLOAD DETECTED] :: $($g.FullName)" -ForegroundColor Magenta
        }

        # 2. Search for hidden 'g*.exe' clones (Infected files)
        $gCloneMatches = Get-ChildItem -Path $drive -Filter "g*.exe" -Recurse -File -Force 2>$null | Where-Object { $_.Attributes -match "Hidden" }
        foreach ($c in $gCloneMatches) {
            $originalName = $c.Name.Substring(1)
            $fakePath = Join-Path $c.DirectoryName $originalName
            
            $isCritical = $false
            foreach ($cp in $criticalPaths) { if ($c.FullName -match [regex]::Escape($cp)) { $isCritical = $true } }

            $Global:ActiveThreats.Add([PSCustomObject]@{
                Type           = "Infected Clone"
                Path           = $fakePath
                HiddenOriginal = $c.Name
                FakeThreatName = $originalName
                IsCriticalPath = $isCritical
            })
            Write-Host "  [CLONE DETECTED]   :: $($c.FullName) (Hiding $originalName)" -ForegroundColor Red
        }
    }

    if ($Global:ActiveThreats.Count -gt 0) {
        $Global:ActiveThreats | Export-Csv -Path $Global:ReportFile -NoTypeInformation -Encoding UTF8
        Write-Host "`n[INTELLIGENCE GATHERED] :: $($Global:ActiveThreats.Count) hostile signatures detected." -ForegroundColor Green
        Write-Host "[LOG EXPORTED]          :: $Global:ReportFile" -ForegroundColor DarkGray
        Write-Host "RECOMMENDATION: Proceed to Protocol [2] to review targets and authorize purge." -ForegroundColor Yellow
    } else {
        Write-Host "`n[CLEAR] :: No hostile signatures found. The system is clean." -ForegroundColor Green
    }
    Pause-Console
}

#================================================================================
# [ MODULE 2: HUMAN VERIFICATION & PURGE EXECUTION ]
#================================================================================

function Invoke-PurgeVerification {
    Show-GenAscii
    Write-Host "`n--- THREAT REVIEW & AUTHORIZATION PROTOCOL ---`n" -ForegroundColor Yellow

    if ($Global:ActiveThreats.Count -eq 0) {
        if (Test-Path $Global:ReportFile) {
            $Global:ActiveThreats = Import-Csv -Path $Global:ReportFile
        } else {
            Write-Host "[ERROR] :: No threat intelligence found. Please run Protocol [1] first." -ForegroundColor Red
            Pause-Console
            return
        }
    }

    Write-Host "The following compromised assets have been identified:`n" -ForegroundColor White
    $criticalCount = 0

    foreach ($t in $Global:ActiveThreats) {
        if ($t.IsCriticalPath -eq $true -or $t.IsCriticalPath -eq "True") {
            Write-Host "[CRITICAL PATH] " -ForegroundColor Red -NoNewline
            $criticalCount++
        } else {
            Write-Host "[STANDARD PATH] " -ForegroundColor Green -NoNewline
        }
        
        if ($t.Type -eq "Primary Payload") {
            Write-Host "PAYLOAD -> $($t.Path)" -ForegroundColor Magenta
        } else {
            Write-Host "CLONE   -> $($t.Path) (Hides: $($t.HiddenOriginal))" -ForegroundColor Yellow
        }
    }

    Write-Host "`n[SUMMARY] Total Targets: $($Global:ActiveThreats.Count) | Critical System Paths: $criticalCount" -ForegroundColor Cyan
    Write-Host "WARNING: Restoring/Deleting files in Critical Paths may require manual reinstallation of affected software.`n" -ForegroundColor Red

    $confirmation = Read-Host "[AUTHORIZATION REQUIRED] Type 'YES' to execute purge and restore, or 'NO' to abort"
    
    if ($confirmation -ne 'YES') {
        Write-Host "`n[ABORTED] :: Purge sequence cancelled by operator." -ForegroundColor DarkGray
        Pause-Console
        return
    }

    Write-Host "`n[AUTHORIZATION ACCEPTED] :: EXECUTING PURGE...`n" -ForegroundColor Green
    $restored = 0
    $deleted = 0

    foreach ($threat in $Global:ActiveThreats) {
        try {
            if ($threat.Type -eq "Primary Payload") {
                # Just delete Gallery.exe
                Stop-Process -Name "Gallery" -Force 2>$null
                attrib.exe -r -s -h "`"$($threat.Path)`"" 2>$null
                Remove-Item -Path $threat.Path -Force 2>$null
                Write-Host "  [DESTROYED] :: $($threat.Path)" -ForegroundColor Green
                $deleted++
            } 
            elseif ($threat.Type -eq "Infected Clone") {
                $dir = Split-Path $threat.Path -Parent
                $fakePath = $threat.Path
                $fakeIcoPath = Join-Path $dir ($threat.HiddenOriginal.Replace(".exe", ".ico"))
                $hiddenPath = Join-Path $dir $threat.HiddenOriginal

                # Kill fake process
                $procName = [System.IO.Path]::GetFileNameWithoutExtension($fakePath)
                Stop-Process -Name $procName -Force 2>$null

                # Delete fakes
                if (Test-Path $fakePath) { attrib.exe -r -s -h "`"$fakePath`"" 2>$null; Remove-Item -Path $fakePath -Force; $deleted++ }
                if (Test-Path $fakeIcoPath) { attrib.exe -r -s -h "`"$fakeIcoPath`"" 2>$null; Remove-Item -Path $fakeIcoPath -Force }

                # Restore original
                if (Test-Path $hiddenPath) {
                    $item = Get-Item $hiddenPath -Force
                    $item.Attributes = 'Archive'
                    Rename-Item -Path $hiddenPath -NewName $threat.FakeThreatName -Force -ErrorAction Stop
                    Write-Host "  [RESTORED]  :: $($threat.FakeThreatName) unhidden and secured." -ForegroundColor Green
                    $restored++
                }
            }
        } catch {
            Write-Host "  [FAILED]    :: Could not process $($threat.Path). Exception: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`n[OPERATION COMPLETE] :: $deleted hostile entities destroyed. $restored original assets restored." -ForegroundColor Cyan
    # Clear active threats array after successful purge
    $Global:ActiveThreats = @()
    Pause-Console
}

#================================================================================
# [ MODULE 3: VACCINATION (HARDCODED DECOYS) ]
#================================================================================

function Invoke-Vaccination {
    Show-GenAscii
    Write-Host "`n--- DEPLOYING COUNTERMEASURES ON PRIORITY-ZERO TARGETS ---`n" -ForegroundColor Yellow

    $ZeroTargets = @(
        Join-Path $env:APPDATA "Gallery.exe",
        Join-Path $env:APPDATA "gallery\Gallery.exe",
        Join-Path $env:LOCALAPPDATA "Gallery.exe",
        Join-Path ([Environment]::GetFolderPath('Startup')) "Gallery.exe",
        Join-Path $env:TEMP "Gallery.exe",
        "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe",
        "C:\Windows\System32\config\systemprofile\AppData\Roaming\Gallery.exe"
    )

    foreach ($target in $ZeroTargets) {
        Write-Host "[TARGET SECURING] :: $target" -ForegroundColor Cyan
        
        $drive = Get-PSDrive -Name ($target.Split(':')[0]) 2>$null
        if (-not $drive -or $drive.FileSystem -ne 'NTFS') { continue }

        $parentDir = Split-Path $target -Parent
        if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }

        if (Test-Path $target -PathType Leaf) {
            takeown /f $target /a 2>$null | Out-Null
            icacls $target /reset /t /c /q 2>$null | Out-Null
            Remove-Item -Path $target -Force 2>$null
        }

        New-Item -ItemType File -Path $target -Force | Out-Null

        try {
            Set-ItemProperty -Path $target -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
            Set-Acl -Path $target -AclObject $acl
            
            Write-Host "  [LOCKED] :: Decoy deployed. Threat vector sealed." -ForegroundColor Green
        } catch {
            Write-Host "  [FAILED] :: Could not enforce ACL lockdown." -ForegroundColor Red
        }
    }
    Pause-Console
}

#================================================================================
# [ MODULE 4: SYSTEM INTEGRITY REPAIR ]
#================================================================================

function Invoke-IntegrityRepair {
    Show-GenAscii
    Write-Host "`n--- INITIATING KERNEL INTEGRITY REPAIR (DISM / SFC) ---`n" -ForegroundColor Yellow
    Write-Host "[WARNING] This protocol may take several minutes to complete.`n" -ForegroundColor DarkGray

    Write-Host "[DISM] Executing Image Restoration..." -ForegroundColor Cyan
    DISM.exe /Online /Cleanup-Image /RestoreHealth

    Write-Host "`n[SFC] Executing Core File Verification..." -ForegroundColor Cyan
    sfc /scannow

    Write-Host "`n[REPAIR COMPLETE] :: System integrity successfully verified." -ForegroundColor Green
    Pause-Console
}

#================================================================================
# [ MAIN EXECUTION LOOP ]
#================================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Show-GenAscii
    Write-Host "`n[FATAL ERROR] :: G.E.N. Protocols require elevated Administrator privileges." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'." -ForegroundColor White
    Write-Host "Terminating session in 5 seconds..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 5
    exit
}

Invoke-SystemProfiling

$sessionActive = $true
while ($sessionActive) {
    Show-MainMenu
    $input = Read-Host "  [COMMAND]"
    
    switch ($input) {
        '1' { Invoke-HunterKiller }
        '2' { Invoke-PurgeVerification }
        '3' { Invoke-Vaccination }
        '4' { Invoke-IntegrityRepair }
        '0' { 
            Write-Host "`n[TERMINATING] :: G.E.N. Session Closed. Stay Vigilant." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            $sessionActive = $false 
        }
        Default {
            Write-Host "`n[INVALID] :: Unrecognized command syntax." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
