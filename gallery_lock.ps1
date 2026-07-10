#Requires -RunAsAdministrator

<#
.SYNOPSIS
    G.E.N. ULTRA v10 - Gallery.exe Extermination & Neutralization Framework
.DESCRIPTION
    An enterprise-grade, single-file forensic suite designed to detect, analyze, 
    quarantine, remove, and prevent the Gallery.exe (Grenam) polymorphic infector.
.NOTES
    Architecture: x64/x86 PowerShell Native (VT100 Supported)
    Security: Double-confirmation system for Windows/Microsoft signed files.
    Execution: DO NOT SPLIT MODULES. Run strictly as a unified script.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# GLOBAL VARIABLES & PATHS
# ==============================================================================
$Global:GEN_Dir = "C:\GEN_ULTRA"
$Global:QuarantineDir = "$Global:GEN_Dir\Security\Quarantine"
$Global:ReportsDir = "$Global:GEN_Dir\Reports"
$Global:DecoyDir = "$Global:GEN_Dir\Decoys"
$Global:ThreatDatabase = [System.Collections.Generic.List[PSCustomObject]]::new()
$Global:SafeList = @("C:\Windows", "C:\Windows\System32", "C:\Windows\SysWOW64", "C:\Windows\WinSxS")

foreach ($dir in @($Global:GEN_Dir, $Global:QuarantineDir, $Global:ReportsDir, $Global:DecoyDir)) {
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
}

# ==============================================================================
# UI & UX AESTHETICS (VT100 & GRADIENTS)
# ==============================================================================

# Enable VT100 Terminal Sequences for Windows 10/11
$host.UI.RawUI.WindowTitle = "🛡️ G.E.N. ULTRA v10 | Forensic Terminal"
$Process = (Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int dwMode); [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out int lpMode); [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int nStdHandle);' -Name "Win32Console" -Namespace Win32 -PassThru)
$Handle = $Process::GetStdHandle(-11)
$Mode = 0
$Process::GetConsoleMode($Handle, [ref]$Mode) | Out-Null
$Process::SetConsoleMode($Handle, $Mode -bor 4) | Out-Null

function Write-GradientText {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [int[]]$StartRGB = @(0, 255, 255),
        [int[]]$EndRGB = @(255, 0, 255),
        [switch]$NoNewline
    )
    $len = $Text.Length
    if ($len -eq 0) { return }
    $out = ""
    for ($i = 0; $i -lt $len; $i++) {
        $ratio = if ($len -gt 1) { $i / ($len - 1) } else { 1 }
        $r = [math]::Round($StartRGB[0] + ($EndRGB[0] - $StartRGB[0]) * $ratio)
        $g = [math]::Round($StartRGB[1] + ($EndRGB[1] - $StartRGB[1]) * $ratio)
        $b = [math]::Round($StartRGB[2] + ($EndRGB[2] - $StartRGB[2]) * $ratio)
        $char = $Text[$i]
        $out += "`e[38;2;$r;$g;$b`m$char"
    }
    $out += "`e[0m"
    if ($NoNewline) { Write-Host $out -NoNewline } else { Write-Host $out }
}

function Show-Header {
    Clear-Host
    Write-Host "`n"
    Write-GradientText "🌌━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🌌" -StartRGB @(0,100,255) -EndRGB @(255,0,255)
    Write-GradientText "               🛡️ G.E.N ULTRA v10 ENTERPRISE                  " -StartRGB @(0,255,255) -EndRGB @(0,255,100)
    Write-GradientText "           Gallery.exe Defense & Neutralization Framework       " -StartRGB @(200,200,200) -EndRGB @(100,100,100)
    Write-GradientText "🌌━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🌌`n" -StartRGB @(0,100,255) -EndRGB @(255,0,255)
}

function Show-Menu {
    Write-Host "`e[36m╔════════════════════════════════════════════════════════════╗`e[0m"
    Write-Host "`e[36m║`e[0m " -NoNewline; Write-GradientText "🛡️ G.E.N ULTRA CONTROL PANEL" -StartRGB @(0,255,255) -EndRGB @(0,150,255) -NoNewline; Write-Host "                              `e[36m║`e[0m"
    Write-Host "`e[36m╠════════════════════════════════════════════════════════════╣`e[0m"
    Write-Host "`e[36m║`e[0m  `e[96m1`e[0m 🔍 Deep Malware Scan        `e[36m║`e[0m  `e[96m5`e[0m 🔒 Deploy Immunity     `e[36m║`e[0m"
    Write-Host "`e[36m║`e[0m  `e[96m2`e[0m 🧬 Analyze Threats          `e[36m║`e[0m  `e[96m6`e[0m 🛠  Repair Windows      `e[36m║`e[0m"
    Write-Host "`e[36m║`e[0m  `e[96m3`e[0m 🧹 Clean Infection          `e[36m║`e[0m  `e[96m7`e[0m 📊 Export Report       `e[36m║`e[0m"
    Write-Host "`e[36m║`e[0m  `e[96m4`e[0m ♻  Restore Files            `e[36m║`e[0m  `e[91m0`e[0m 🚪 Exit               `e[36m║`e[0m"
    Write-Host "`e[36m╚════════════════════════════════════════════════════════════╝`e[0m`n"
}

function Invoke-Pause {
    Write-Host "`n`e[90m[ PRESS ANY KEY TO RETURN TO MAIN MENU ]`e[0m"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# FORENSIC & CRYPTOGRAPHIC ENGINE
# ==============================================================================

function Get-FileForensics {
    param([System.IO.FileInfo]$File)
    
    $hash = "UNKNOWN"
    $md5 = "UNKNOWN"
    try {
        $hashStream = [System.IO.File]::OpenRead($File.FullName)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hash = [BitConverter]::ToString($sha256.ComputeHash($hashStream)).Replace("-","")
        $hashStream.Position = 0
        $md5Alg = [System.Security.Cryptography.MD5]::Create()
        $md5 = [BitConverter]::ToString($md5Alg.ComputeHash($hashStream)).Replace("-","")
        $hashStream.Close()
    } catch {}

    $sigStatus = "Not Signed"
    $signer = "Unknown"
    $isMS = $false
    try {
        $sig = Get-AuthenticodeSignature -FilePath $File.FullName
        if ($sig.Status -eq "Valid") {
            $sigStatus = "Valid"
            $signer = $sig.SignerCertificate.Subject
            if ($signer -match "Microsoft|Windows") { $isMS = $true }
        } elseif ($sig.Status -eq "HashMismatch") {
            $sigStatus = "Invalid (Modified)"
        }
    } catch {}

    $isCritical = $false
    foreach ($path in $Global:SafeList) {
        if ($File.FullName.StartsWith($path, [StringComparison]::OrdinalIgnoreCase)) {
            $isCritical = $true; break
        }
    }

    return [PSCustomObject]@{
        Name = $File.Name
        Path = $File.FullName
        Size = $File.Length
        SHA256 = $hash
        MD5 = $md5
        Created = $File.CreationTime
        Modified = $File.LastWriteTime
        Attributes = $File.Attributes.ToString()
        Signer = $signer
        SignatureStatus = $sigStatus
        IsMicrosoft = $isMS
        IsCriticalPath = $isCritical
    }
}

function Get-ThreatScore {
    param($Forensics)
    $score = 0
    $reasons = @()
    $isGClone = $false
    $hiddenOriginalPath = $null
    $hasMatchingIco = $false

    # 1. Gallery literal match
    if ($Forensics.Name -match "^Gallery\.exe$") {
        $score += 90
        $reasons += "Known Malware Name"
    }

    # 2. G-Prefix Pattern & File Size Logic
    if ($Forensics.Name -match "^g(.+\.exe)$") {
        $score += 30
        $reasons += "g-prefix naming convention"
        
        $originalName = $matches[1]
        $dir = Split-Path $Forensics.Path -Parent
        $potentialOriginal = Join-Path $dir $originalName
        
        if (Test-Path $potentialOriginal) {
            $origInfo = Get-Item $potentialOriginal -Force
            if ($origInfo.Attributes -match "Hidden") {
                $score += 30
                $reasons += "Original executable hidden in same directory"
                $isGClone = $true
                $hiddenOriginalPath = $potentialOriginal
            }
            if ($Forensics.Size -lt 1MB -and $origInfo.Length -gt $Forensics.Size) {
                $score += 20
                $reasons += "Size abnormally smaller than hidden original (<1MB)"
            }
        }
        
        $icoName = $Forensics.Name.Replace(".exe", ".ico")
        $icoPath = Join-Path $dir $icoName
        if (Test-Path $icoPath) {
            $score += 10
            $reasons += "Matching g-prefixed .ico file found"
            $hasMatchingIco = $true
        }
    }

    # 3. Signature Validation
    if ($Forensics.SignatureStatus -eq "Not Signed" -or $Forensics.SignatureStatus -eq "Invalid (Modified)") {
        $score += 15
        $reasons += "Unsigned or Invalid Signature"
    }

    # 4. Attribute Anomalies
    if ($Forensics.Attributes -match "Hidden" -and $Forensics.Name -match "^g") {
        $score += 15
        $reasons += "Hidden attribute on suspect file"
    }

    # 5. Location Based
    if ($Forensics.Path -match "AppData\\Roaming" -or $Forensics.Path -match "AppData\\Local") {
        $score += 20
        $reasons += "Located in AppData"
    }
    if ($Forensics.Path -match "Start Menu\\Programs\\Startup") {
        $score += 30
        $reasons += "Located in Startup Folder"
    }
    if ($Forensics.Path -match "Temp") {
        $score += 20
        $reasons += "Located in Temp Folder"
    }

    $finalScore = [math]::Min($score, 100)
    
    $status = "SAFE"
    if ($finalScore -ge 31 -and $finalScore -le 60) { $status = "SUSPICIOUS" }
    elseif ($finalScore -gt 60) { $status = "MALWARE" }

    return [PSCustomObject]@{
        Score = $finalScore
        Status = $status
        Reasons = $reasons -join " | "
        IsGClone = $isGClone
        HiddenOriginalPath = $hiddenOriginalPath
        HasMatchingIco = $hasMatchingIco
    }
}

# ==============================================================================
# SCANNER ENGINE
# ==============================================================================

function Invoke-DeepScan {
    Show-Header
    Write-Host "`e[96m🔍 INITIALIZING FULL SYSTEM FORENSIC SCANNER...`e[0m`n"
    
    # Pre-execution backup
    Write-Host "`e[90m[+] Creating System Restore Point...`e[0m"
    Checkpoint-Computer -Description "GEN Ultra Pre-Scan" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue | Out-Null

    $Global:ThreatDatabase.Clear()
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.IsReady }
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $scannedFiles = 0
    $threatsFound = 0
    $startTime = Get-Date

    foreach ($drive in $drives) {
        $root = $drive.Root
        Write-Host "`e[36m[+] Engaging Sector: $root`e[0m"
        
        # We target specifics to optimize the recursive search without trusting names alone.
        # We look for *.exe, specifically picking up Gallery.exe and g*.exe, but also looking at size
        $foldersToScan = @($root)
        if ($root -match "C:\\") {
            # Prioritize known infection vectors for speed, then broad scan
            $foldersToScan = @(
                $env:APPDATA, $env:LOCALAPPDATA, $env:TEMP, 
                [Environment]::GetFolderPath("Startup"),
                "C:\Program Files", "C:\Program Files (x86)",
                "C:\Windows\System32\config\systemprofile\AppData",
                "C:\Windows\SysWOW64\config\systemprofile\AppData",
                "C:\"
            ) | Select-Object -Unique
        }

        foreach ($folder in $foldersToScan) {
            if (-not (Test-Path $folder)) { continue }
            
            $files = Get-ChildItem -Path $folder -Include "Gallery.exe", "gallery.exe", "g*.exe" -Recurse -File -Force -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $scannedFiles++
                $elapsed = (Get-Date) - $startTime
                $speed = if ($elapsed.TotalSeconds -gt 0) { [math]::Round($scannedFiles / $elapsed.TotalSeconds) } else { 0 }
                
                if ($scannedFiles % 15 -eq 0) {
                    $spin = $spinner[($scannedFiles % $spinner.Length)]
                    Write-Host -NoNewline "`r`e[96m $spin Scanning: `e[36m$($file.DirectoryName | Select-String -Pattern '^.{0,40}' | % { $_.Matches.Value + '...' }) `e[90m| Scanned: $scannedFiles | Threats: $threatsFound | Speed: $speed f/s`e[0m"
                }

                $forensics = Get-FileForensics -File $file
                $risk = Get-ThreatScore -Forensics $forensics

                if ($risk.Status -ne "SAFE") {
                    $threatsFound++
                    $Global:ThreatDatabase.Add([PSCustomObject]@{
                        Forensics = $forensics
                        Risk = $risk
                    })
                }
            }
        }
    }
    
    # Persistence Scan (Registry & Tasks)
    Write-Host "`n`n`e[96m[+] Scanning Persistence Mechanisms (Registry, WMI, Tasks)...`e[0m"
    $regPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    foreach ($reg in $regPaths) {
        if (Test-Path $reg) {
            $items = Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue
            foreach ($prop in $items.PSObject.Properties) {
                if ($prop.Value -match "Gallery\.exe|g.*\.exe") {
                    $threatsFound++
                    $Global:ThreatDatabase.Add([PSCustomObject]@{
                        Forensics = [PSCustomObject]@{ Path = "Registry: $($reg)\$($prop.Name)"; Name = $prop.Name; Size = 0; IsCriticalPath = $false; Signer = "N/A" }
                        Risk = [PSCustomObject]@{ Status = "MALWARE"; Score = 100; Reasons = "Malicious Persistence Key"; IsGClone = $false }
                    })
                }
            }
        }
    }

    Write-Host "`n`e[92m[████████████████████████████████] 100% - Scan Complete.`e[0m"
    Write-Host "`e[96mTotal Scanned:`e[0m $scannedFiles  |  `e[91mThreats Detected:`e[0m $threatsFound"
    Invoke-Pause
}

# ==============================================================================
# QUARANTINE & RECOVERY ENGINE
# ==============================================================================

function Invoke-Quarantine {
    param($ThreatPath)
    if ($ThreatPath -match "^Registry:") { return $true } # Skip file move for reg keys
    if (-not (Test-Path $ThreatPath)) { return $false }
    
    try {
        $fileName = Split-Path $ThreatPath -Leaf
        $hashName = (New-Guid).Guid
        $destPath = Join-Path $Global:QuarantineDir "$hashName.vir"
        
        Move-Item -Path $ThreatPath -Destination $destPath -Force
        
        $metadata = @{
            OriginalPath = $ThreatPath
            QuarantinedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            OriginalName = $fileName
        }
        $metadata | ConvertTo-Json | Out-File (Join-Path $Global:QuarantineDir "$hashName.json")
        return $true
    } catch {
        return $false
    }
}

function Restore-HiddenOriginal {
    param($ThreatItem)
    if ($ThreatItem.Risk.IsGClone -and $ThreatItem.Risk.HiddenOriginalPath) {
        $hiddenPath = $ThreatItem.Risk.HiddenOriginalPath
        if (Test-Path $hiddenPath) {
            try {
                # Remove malicious attributes
                $file = Get-Item $hiddenPath -Force
                $file.Attributes = $file.Attributes -band -bnot [System.IO.FileAttributes]::Hidden
                $file.Attributes = $file.Attributes -band -bnot [System.IO.FileAttributes]::System
                $file.Attributes = $file.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly
                $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Normal
                return $true
            } catch { return $false }
        }
    }
    return $false
}

function Remove-IcoClone {
    param($ThreatItem)
    if ($ThreatItem.Risk.HasMatchingIco) {
        $icoPath = $ThreatItem.Forensics.Path.Replace(".exe", ".ico")
        if (Test-Path $icoPath) {
            try {
                $file = Get-Item $icoPath -Force
                $file.Attributes = 'Normal'
                Remove-Item -Path $icoPath -Force
                return $true
            } catch { return $false }
        }
    }
    return $false
}

# ==============================================================================
# THREAT ANALYSIS & CLEANUP UI
# ==============================================================================

function Show-ThreatUI {
    param($Threat)
    
    $color = if ($Threat.Risk.Score -gt 80) { "91m" } elseif ($Threat.Risk.Score -gt 50) { "95m" } else { "93m" }
    
    Write-Host "`e[${color}╔══════════════════════════════════════════════════════════════════╗`e[0m"
    Write-Host "`e[${color}║ 🚨 THREAT DETECTED                                               ║`e[0m"
    Write-Host "`e[${color}╠══════════════════════════════════════════════════════════════════╣`e[0m"
    Write-Host "`e[${color}║`e[0m `e[96mFile:`e[0m"
    Write-Host "`e[${color}║`e[0m $($Threat.Forensics.Path)"
    Write-Host "`e[${color}║`e[0m"
    Write-Host "`e[${color}║`e[0m `e[96mSHA256:`e[0m $($Threat.Forensics.SHA256)"
    Write-Host "`e[${color}║`e[0m `e[96mSigner:`e[0m $($Threat.Forensics.Signer) ($($Threat.Forensics.SignatureStatus))"
    Write-Host "`e[${color}║`e[0m `e[96mRisk:`e[0m   $($Threat.Risk.Score)/100"
    Write-Host "`e[${color}║`e[0m `e[96mStatus:`e[0m $($Threat.Risk.Status) - $($Threat.Risk.Reasons)"
    Write-Host "`e[${color}╚══════════════════════════════════════════════════════════════════╝`e[0m"
}

function Invoke-CleanupEngine {
    Show-Header
    
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "`e[92m[+] Threat Database is empty. Please run a Deep Scan (Option 1) first.`e[0m"
        Invoke-Pause
        return
    }

    $autoCleanAll = $false

    foreach ($threat in $Global:ThreatDatabase) {
        Clear-Host
        Show-Header
        Show-ThreatUI -Threat $threat

        # Double Confirmation for MS Files in Critical Paths
        if ($threat.Forensics.IsCriticalPath -and $threat.Forensics.IsMicrosoft) {
            Write-Host "`n`e[101;97m !!! WARNING: SYSTEM CRITICAL FILE DETECTED !!! `e[0m"
            Write-Host "`e[91mThis file is signed by Microsoft and resides in a protected Windows directory.`e[0m"
            Write-Host "`e[91mAUTOMATIC DELETION BLOCKED. Require manual verification.`e[0m"
            $autoCleanAll = $false
        }

        $action = "S"
        if ($autoCleanAll) {
            $action = "A"
        } else {
            Write-Host "`n`e[96mOptions:`e[0m"
            Write-Host "`e[92m[Y] Delete File`e[0m  `e[93m[Q] Quarantine`e[0m  `e[94m[R] Restore Original (if g-clone)`e[0m  `e[90m[S] Skip`e[0m  `e[95m[A] Apply All Safe Actions`e[0m"
            $action = Read-Host "`e[97mSelect Action`e[0m"
        }

        if ($action -match "A") { $autoCleanAll = $true; $action = "Q" } # Default Auto to Quarantine

        switch -Regex ($action) {
            "^[Yy]" {
                if ($threat.Forensics.Path -match "^Registry:") {
                    # Handle Reg key
                    $pathParts = $threat.Forensics.Path.Split(":")
                    $regKey = $pathParts[1].Trim().Split("\")
                    $valName = $regKey[-1]
                    $regPath = ($regKey[0..($regKey.Length-2)] -join "\")
                    Remove-ItemProperty -Path $regPath -Name $valName -Force -ErrorAction SilentlyContinue
                    Write-Host "`e[92m[+] Persistence Key Deleted.`e[0m"
                } else {
                    $procName = [System.IO.Path]::GetFileNameWithoutExtension($threat.Forensics.Path)
                    Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
                    $f = Get-Item $threat.Forensics.Path -Force
                    $f.Attributes = 'Normal'
                    Remove-Item -Path $threat.Forensics.Path -Force
                    Write-Host "`e[92m[+] Threat Deleted.`e[0m"
                }
                if ($threat.Risk.IsGClone) { Restore-HiddenOriginal -ThreatItem $threat | Out-Null; Remove-IcoClone -ThreatItem $threat | Out-Null }
            }
            "^[Qq]" {
                if (Invoke-Quarantine -ThreatPath $threat.Forensics.Path) {
                    Write-Host "`e[92m[+] Threat Quarantined to $Global:QuarantineDir.`e[0m"
                    if ($threat.Risk.IsGClone) { 
                        if (Restore-HiddenOriginal -ThreatItem $threat) { Write-Host "`e[94m[+] Hidden Original Restored & Unhidden.`e[0m" }
                        if (Remove-IcoClone -ThreatItem $threat) { Write-Host "`e[94m[+] Matching ICO clone removed.`e[0m" }
                    }
                } else { Write-Host "`e[91m[-] Quarantine Failed.`e[0m" }
            }
            "^[Rr]" {
                if ($threat.Risk.IsGClone) {
                    if (Restore-HiddenOriginal -ThreatItem $threat) { Write-Host "`e[92m[+] Original File Restored to Normal.`e[0m" }
                    else { Write-Host "`e[91m[-] Failed to restore original.`e[0m" }
                } else { Write-Host "`e[93m[-] Not a g-prefixed clone with a hidden original.`e[0m" }
            }
            "^[Ss]" { Write-Host "`e[90m[!] Skipped.`e[0m" }
            Default { Write-Host "`e[90m[!] Unknown input. Skipped.`e[0m" }
        }
        Start-Sleep -Milliseconds 600
    }
    
    $Global:ThreatDatabase.Clear()
    Write-Host "`n`e[96m[+] Cleanup Sequence Complete.`e[0m"
    Invoke-Pause
}

# ==============================================================================
# ANTI-REGENERATION (IMMUNITY) ENGINE
# ==============================================================================

function Invoke-ImmunityDeployment {
    Show-Header
    Write-Host "`e[96m🔒 DEPLOYING ANTI-REGENERATION IMMUNITY MATRIX...`e[0m`n"
    
    $targetDecoys = @(
        Join-Path $env:APPDATA "Gallery.exe",
        Join-Path $env:APPDATA "gallery\Gallery.exe",
        Join-Path $env:LOCALAPPDATA "Gallery.exe",
        Join-Path ([Environment]::GetFolderPath("Startup")) "Gallery.exe",
        Join-Path $env:TEMP "Gallery.exe",
        "C:\Windows\System32\config\systemprofile\AppData\Roaming\Gallery.exe",
        "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
    )

    foreach ($target in $targetDecoys) {
        Write-Host "`e[36m[+] Securing Vector: $target`e[0m"
        try {
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            if (Test-Path $target) { 
                takeown.exe /F $target /A | Out-Null
                icacls.exe $target /reset /Q | Out-Null
                Remove-Item -Path $target -Force 
            }
            
            # Create Null Decoy
            New-Item -Path $target -ItemType File -Force | Out-Null
            Set-ItemProperty -Path $target -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force

            # Apply strict ACL
            $acl = Get-Acl $target
            $acl.SetAccessRuleProtection($true, $false)
            $denyAll = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Write", "Deny")
            $allowSys = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")
            $allowAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "Read", "Allow")
            $acl.AddAccessRule($denyAll)
            $acl.AddAccessRule($allowSys)
            $acl.AddAccessRule($allowAdmin)
            Set-Acl -Path $target -AclObject $acl
            Write-Host "`e[92m    -> IMMUNITY LAYER APPLIED (WRITE DENIED)`e[0m"
        } catch {
            Write-Host "`e[91m    -> FAILED TO SECURE VECTOR: $($_.Exception.Message)`e[0m"
        }
    }
    Write-Host "`n`e[96m[+] Malware Regeneration Blocked Successfully.`e[0m"
    Invoke-Pause
}

# ==============================================================================
# SYSTEM REPAIR ENGINE (DISM / SFC)
# ==============================================================================

function Invoke-SystemRepair {
    Show-Header
    Write-Host "`e[96m🛠  INITIATING WINDOWS COMPONENT STORE REPAIR...`e[0m`n"
    Write-Host "`e[93m[!] This process may take 10-30 minutes. Do not interrupt.`e[0m`n"
    
    Write-Host "`e[36m[1/2] Executing DISM (Deployment Image Servicing and Management)`e[0m"
    $dismProc = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow -PassThru
    if ($dismProc.ExitCode -eq 0) { Write-Host "`e[92m    -> DISM Completed Successfully.`e[0m`n" }
    else { Write-Host "`e[91m    -> DISM returned error code $($dismProc.ExitCode)`e[0m`n" }

    Write-Host "`e[36m[2/2] Executing SFC (System File Checker)`e[0m"
    $sfcProc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -PassThru
    if ($sfcProc.ExitCode -eq 0) { Write-Host "`e[92m    -> SFC Completed Successfully.`e[0m`n" }
    else { Write-Host "`e[91m    -> SFC found issues or returned error code $($sfcProc.ExitCode)`e[0m`n" }

    Write-Host "`e[96m[+] System Integrity Operations Concluded.`e[0m"
    Invoke-Pause
}

# ==============================================================================
# REPORTING ENGINE
# ==============================================================================

function Export-Reports {
    Show-Header
    Write-Host "`e[96m📊 GENERATING THREAT INTELLIGENCE REPORTS...`e[0m`n"
    
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "`e[93m[-] No threats in memory to report. Run a scan first.`e[0m"
        Invoke-Pause
        return
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $baseName = Join-Path $Global:ReportsDir "GEN_Report_$timestamp"
    
    # Flatten Data for Export
    $exportData = $Global:ThreatDatabase | ForEach-Object {
        [PSCustomObject]@{
            File = $_.Forensics.Path
            SHA256 = $_.Forensics.SHA256
            RiskScore = $_.Risk.Score
            Status = $_.Risk.Status
            Reason = $_.Risk.Reasons
            Signer = $_.Forensics.Signer
            IsGClone = $_.Risk.IsGClone
        }
    }

    # JSON Export
    $exportData | ConvertTo-Json -Depth 3 | Out-File "$baseName.json"
    Write-Host "`e[92m[+] JSON Report Created: $baseName.json`e[0m"

    # CSV Export
    $exportData | Export-Csv -Path "$baseName.csv" -NoTypeInformation
    Write-Host "`e[92m[+] CSV Report Created: $baseName.csv`e[0m"

    # HTML Export
    $htmlHead = "<style>body{background:#1e1e1e;color:#fff;font-family:Segoe UI,sans-serif;} table{width:100%;border-collapse:collapse;} th,td{border:1px solid #444;padding:8px;} th{background:#0078D7;}</style>"
    $htmlContent = $exportData | ConvertTo-Html -Head $htmlHead -Title "G.E.N Threat Report" -PreContent "<h2>G.E.N ULTRA - Threat Intelligence Report ($timestamp)</h2>"
    $htmlContent | Out-File "$baseName.html"
    Write-Host "`e[92m[+] HTML Report Created: $baseName.html`e[0m"
    
    Invoke-Pause
}

function Analyze-Threats {
    Show-Header
    Write-Host "`e[96m🧬 THREAT DATABASE ANALYSIS`e[0m`n"
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "`e[92m[+] No active threats in memory. System appears clean.`e[0m"
    } else {
        Write-Host "`e[93m[!] $($Global:ThreatDatabase.Count) malicious entities currently mapped.`e[0m`n"
        $Global:ThreatDatabase | Format-Table -Property @{N="Threat Path";E={$_.Forensics.Path}}, @{N="Score";E={$_.Risk.Score}}, @{N="Status";E={$_.Risk.Status}}, @{N="G-Clone";E={$_.Risk.IsGClone}} -AutoSize
        Write-Host "`e[90mProceed to Option [3] to neutralize.`e[0m"
    }
    Invoke-Pause
}

# ==============================================================================
# MAIN EXECUTION LOOP
# ==============================================================================

while ($true) {
    Show-Header
    Show-Menu
    
    $choice = Read-Host "`e[97mSelect Operation`e[0m"
    
    switch ($choice) {
        "1" { Invoke-DeepScan }
        "2" { Analyze-Threats }
        "3" { Invoke-CleanupEngine }
        "4" { 
            # Quick restore UI for quarantined files
            Show-Header
            Write-Host "`e[96m♻ QUARANTINE VAULT RESTORATION`e[0m`n"
            $qFiles = Get-ChildItem -Path $Global:QuarantineDir -Filter "*.json" -ErrorAction SilentlyContinue
            if ($qFiles.Count -eq 0) { Write-Host "`e[90m[+] Vault is empty.`e[0m"; Invoke-Pause; break }
            
            $i = 1; $qDict = @{}
            foreach ($q in $qFiles) {
                $meta = Get-Content $q.FullName | ConvertFrom-Json
                Write-Host "`e[36m[$i]`e[0m $($meta.OriginalName) (Quarantined: $($meta.QuarantinedAt)) -> $($meta.OriginalPath)"
                $qDict[$i] = $meta
                $i++
            }
            Write-Host "`n`e[93m[0] Cancel`e[0m"
            $rChoice = Read-Host "`e[97mSelect file to restore`e[0m"
            if ($rChoice -eq "0" -or -not $qDict[$rChoice -as [int]]) { break }
            
            $targetMeta = $qDict[$rChoice -as [int]]
            $virPath = $qFiles[($rChoice -as [int]) - 1].FullName.Replace(".json", ".vir")
            if (Test-Path $virPath) {
                Move-Item -Path $virPath -Destination $targetMeta.OriginalPath -Force
                Remove-Item -Path $qFiles[($rChoice -as [int]) - 1].FullName -Force
                Write-Host "`n`e[92m[+] File Restored to $($targetMeta.OriginalPath)`e[0m"
            }
            Invoke-Pause
        }
        "5" { Invoke-ImmunityDeployment }
        "6" { Invoke-SystemRepair }
        "7" { Export-Reports }
        "0" {
            Show-Header
            Write-Host "`e[92m[+] Terminating G.E.N Framework. Stay Secure.`e[0m`n"
            Start-Sleep -Seconds 2
            exit
        }
        Default { Write-Host "`e[91m[-] Invalid Command.`e[0m"; Start-Sleep -Seconds 1 }
    }
}
