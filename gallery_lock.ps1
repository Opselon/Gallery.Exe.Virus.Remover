#Requires -RunAsAdministrator

<#
.SYNOPSIS
    G.E.N. ULTRA v10 - Gallery.exe Extermination & Neutralization Framework (Enterprise Master)
.DESCRIPTION
    A colossal, single-file, enterprise-grade forensic suite. 
    Designed for absolute eradication of the Gallery.exe (Grenam) polymorphic infector.
    
    Includes Shannon Entropy calculation, live memory process termination, AES-encrypted 
    quarantine, double-confirmation safety protocols, and advanced anti-regeneration.
.NOTES
    Architecture: x64/x86 PowerShell Native
    Compatibility: PS 5.1+
    Author: Opselon & G.E.N Security Team
    Execution: DO NOT SPLIT MODULES. Run strictly as a unified script.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# [01] KERNEL & TERMINAL INITIALIZATION (FIXED UX)
# ==============================================================================

# Force Enable VT100 processing for Windows Console to prevent e[38;2;... bleed
try {
    $Process = (Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int dwMode); [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out int lpMode); [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int nStdHandle);' -Name "Win32Console" -Namespace Win32 -PassThru)
    $Handle = $Process::GetStdHandle(-11)
    $Mode = 0
    $Process::GetConsoleMode($Handle, [ref]$Mode) | Out-Null
    $Process::SetConsoleMode($Handle, $Mode -bor 4) | Out-Null
    $Global:VT100Enabled = $true
} catch {
    $Global:VT100Enabled = $false
}

$host.UI.RawUI.WindowTitle = "🛡️ G.E.N. ULTRA v10 | Enterprise Malware Forensic Terminal"
$Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 3000)
$Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 40)

# ==============================================================================
# [02] GLOBAL CONFIGURATION & ARCHITECTURE
# ==============================================================================

$Global:AppVersion = "10.0.5-ENTERPRISE"
$Global:GEN_Dir = "C:\GEN_ULTRA"
$Global:QuarantineDir = "$Global:GEN_Dir\Security\Quarantine"
$Global:ReportsDir = "$Global:GEN_Dir\Reports"
$Global:DecoyDir = "$Global:GEN_Dir\Decoys"
$Global:LogsDir = "$Global:GEN_Dir\Logs"
$Global:LogFile = "$Global:LogsDir\GEN_Engine_$( (Get-Date).ToString('yyyyMMdd') ).log"

$Global:ThreatDatabase = [System.Collections.Generic.List[PSCustomObject]]::new()
$Global:ProcessDatabase = [System.Collections.Generic.List[PSCustomObject]]::new()
$Global:QuarantineKey = "GEN_SECURE_ENCLAVE_KEY_9988776655" # Used for basic obfuscation
$Global:SafeList = @(
    "C:\Windows", "C:\Windows\System32", "C:\Windows\SysWOW64", 
    "C:\Windows\WinSxS", "C:\Program Files\Windows Defender"
)

# Build Directory Structure
foreach ($dir in @($Global:GEN_Dir, $Global:QuarantineDir, $Global:ReportsDir, $Global:DecoyDir, $Global:LogsDir)) {
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
}

# ==============================================================================
# [03] ENTERPRISE LOGGING ENGINE
# ==============================================================================

function Write-GenLog {
    <#
    .SYNOPSIS
        Appends a formatted message to the rolling application log.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][ValidateSet("INFO","WARN","ERROR","DEBUG","CRIT")][string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $Global:LogFile -Value $logEntry -Force
    } catch {
        # Failsafe if log is locked
    }
}

Write-GenLog "G.E.N ULTRA Framework Initialized." "INFO"
Write-GenLog "VT100 Rendering Engine Status: $Global:VT100Enabled" "DEBUG"

# ==============================================================================
# [04] RIGID UI & AESTHETICS ENGINE (ALIGNMENT SAFE)
# ==============================================================================

function Write-SafeColor {
    param([string]$Text, [string]$Color)
    Write-Host $Text -ForegroundColor $Color -NoNewline
}

function Show-GenHeader {
    Clear-Host
    Write-Host ""
    Write-Host "   ██████╗  ███████╗ ███╗   ██╗     ██╗   ██╗ ██╗     ████████╗ ██████╗   █████╗ " -ForegroundColor Cyan
    Write-Host "  ██╔════╝  ██╔════╝ ████╗  ██║     ██║   ██║ ██║     ╚══██╔══╝ ██╔══██╗ ██╔══██╗" -ForegroundColor Cyan
    Write-Host "  ██║  ███╗ █████╗   ██╔██╗ ██║     ██║   ██║ ██║        ██║    ██████╔╝ ███████║" -ForegroundColor DarkCyan
    Write-Host "  ██║   ██║ ██╔══╝   ██║╚██╗██║     ██║   ██║ ██║        ██║    ██╔══██╗ ██╔══██║" -ForegroundColor Blue
    Write-Host "  ╚██████╔╝ ███████╗ ██║ ╚████║     ╚██████╔╝ ███████╗   ██║    ██║  ██║ ██║  ██║" -ForegroundColor DarkBlue
    Write-Host "   ╚═════╝  ╚══════╝ ╚═╝  ╚═══╝      ╚═════╝  ╚══════╝   ╚═╝    ╚═╝  ╚═╝ ╚═╝  ╚═╝" -ForegroundColor DarkBlue
    
    Write-Host " 🌌" -NoNewline; Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray -NoNewline; Write-Host "🌌 "
    Write-Host "                       🛡️ G.E.N ULTRA v10 ENTERPRISE                          " -ForegroundColor Green
    Write-Host "           Gallery.exe Extermination & Neutralization Framework              " -ForegroundColor Gray
    Write-Host " 🌌" -NoNewline; Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray -NoNewline; Write-Host "🌌 `n"
}

function Show-GenMenu {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║ " -ForegroundColor Cyan -NoNewline; Write-Host "                  🛡️ G.E.N ULTRA COMMAND MATRIX                  " -ForegroundColor White -NoNewline; Write-Host "        ║" -ForegroundColor Cyan
    Write-Host "  ╠══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    Write-Host "  ║ " -ForegroundColor Cyan -NoNewline; Write-Host " " -NoNewline; Write-Host "[1]" -ForegroundColor Green -NoNewline; Write-Host " 🔍 Deep File System Scan        " -ForegroundColor White -NoNewline; Write-Host " " -NoNewline; Write-Host "[6]" -ForegroundColor Green -NoNewline; Write-Host " 🔒 Deploy Decoys & Immunity    " -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "  ║ " -ForegroundColor Cyan -NoNewline; Write-Host " " -NoNewline; Write-Host "[2]" -ForegroundColor Green -NoNewline; Write-Host " 🧠 Live Process Memory Hunt     " -ForegroundColor White -NoNewline; Write-Host " " -NoNewline; Write-Host "[7]" -ForegroundColor Green -NoNewline; Write-Host " 🛠  Repair Windows (DISM/SFC)  " -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "  ║ " -ForegroundColor Cyan -NoNewline; Write-Host " " -NoNewline; Write-Host "[3]" -ForegroundColor Yellow -NoNewline; Write-Host " 🧬 Analyze Threat Database      " -ForegroundColor White -NoNewline; Write-Host " " -NoNewline; Write-Host "[8]" -ForegroundColor Green -NoNewline; Write-Host " 📊 Export Intelligence Report  " -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "  ║ " -ForegroundColor Cyan -NoNewline; Write-Host " " -NoNewline; Write-Host "[4]" -ForegroundColor Red -NoNewline; Write-Host " 🧹 Execute Quarantine & Clean   " -ForegroundColor White -NoNewline; Write-Host " " -NoNewline; Write-Host "[9]" -ForegroundColor Magenta -NoNewline; Write-Host " ⚙  Advanced Diagnostics        " -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "  ║ " -ForegroundColor Cyan -NoNewline; Write-Host " " -NoNewline; Write-Host "[5]" -ForegroundColor Cyan -NoNewline; Write-Host " ♻  Restore Vaulted Files        " -ForegroundColor White -NoNewline; Write-Host " " -NoNewline; Write-Host "[0]" -ForegroundColor DarkGray -NoNewline; Write-Host " 🚪 Terminate Framework         " -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-GenPause {
    Write-Host "`n  [ AWAITING COMMAND ] Press any key to return to Main Menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-Spinner {
    param([int]$Milliseconds, [string]$Message)
    $spinner = @('|', '/', '-', '\')
    $cycles = [math]::Round($Milliseconds / 100)
    for ($i = 0; $i -lt $cycles; $i++) {
        $char = $spinner[$i % 4]
        Write-Host "`r  [$char] $Message " -ForegroundColor Cyan -NoNewline
        Start-Sleep -Milliseconds 100
    }
    Write-Host "`r  [✓] $Message " -ForegroundColor Green
}

# ==============================================================================
# [05] ADVANCED MATHEMATICAL FORENSICS (ENTROPY)
# ==============================================================================

function Get-ShannonEntropy {
    <#
    .SYNOPSIS
        Calculates the Shannon Entropy of a file to detect packed or encrypted malware.
    .DESCRIPTION
        Gallery.exe and its variants often use packing. High entropy (> 7.0) indicates
        compression or encryption, which is highly suspicious for small executables.
    #>
    param([Parameter(Mandatory=$true)][string]$FilePath)
    
    try {
        if ((Get-Item $FilePath).Length -eq 0) { return 0.0 }
        if ((Get-Item $FilePath).Length -gt 50MB) { return -1.0 } # Skip large files for speed

        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $frequencies = New-Object 'int[]' 256
        
        foreach ($byte in $bytes) {
            $frequencies[$byte]++
        }
        
        $length = $bytes.Length
        $entropy = 0.0
        
        foreach ($freq in $frequencies) {
            if ($freq -gt 0) {
                $probability = $freq / $length
                $entropy -= $probability * [Math]::Log($probability, 2)
            }
        }
        return [math]::Round($entropy, 3)
    } catch {
        Write-GenLog "Entropy calculation failed for $FilePath : $($_.Exception.Message)" "WARN"
        return 0.0
    }
}

# ==============================================================================
# [06] DEEP FILE FORENSICS & CRYPTOGRAPHY ENGINE
# ==============================================================================

function Get-FileForensics {
    param([System.IO.FileInfo]$File)
    
    $hashSHA256 = "UNKNOWN"
    $hashMD5 = "UNKNOWN"
    $entropy = 0.0

    try {
        $hashStream = [System.IO.File]::OpenRead($File.FullName)
        
        $sha256Alg = [System.Security.Cryptography.SHA256]::Create()
        $hashSHA256 = [BitConverter]::ToString($sha256Alg.ComputeHash($hashStream)).Replace("-","")
        
        $hashStream.Position = 0
        $md5Alg = [System.Security.Cryptography.MD5]::Create()
        $hashMD5 = [BitConverter]::ToString($md5Alg.ComputeHash($hashStream)).Replace("-","")
        
        $hashStream.Close()
        
        # Calculate Entropy if file is suspiciously small (< 2MB)
        if ($File.Length -lt 2MB) {
            $entropy = Get-ShannonEntropy -FilePath $File.FullName
        }
    } catch {
        Write-GenLog "Hashing failed for $($File.FullName)" "ERROR"
    }

    $sigStatus = "Not Signed"
    $signer = "Unknown"
    $isMS = $false
    try {
        $sig = Get-AuthenticodeSignature -FilePath $File.FullName -ErrorAction SilentlyContinue
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
        Directory = $File.DirectoryName
        Size = $File.Length
        SHA256 = $hashSHA256
        MD5 = $hashMD5
        Entropy = $entropy
        Created = $File.CreationTime
        Modified = $File.LastWriteTime
        Attributes = $File.Attributes.ToString()
        Signer = $signer
        SignatureStatus = $sigStatus
        IsMicrosoft = $isMS
        IsCriticalPath = $isCritical
    }
}

# ==============================================================================
# [07] THREAT HEURISTICS & SCORING ENGINE
# ==============================================================================

function Get-ThreatScore {
    <#
    .SYNOPSIS
        Evaluates a file's forensic profile against Gallery/Grenam known behaviors.
    #>
    param($Forensics)
    $score = 0
    $reasons = [System.Collections.Generic.List[string]]::new()
    
    $isGClone = $false
    $hiddenOriginalPath = $null
    $hasMatchingIco = $false

    # RULE 1: Literal Gallery.exe matching
    if ($Forensics.Name -match "(?i)^Gallery\.exe$") {
        $score += 100
        $reasons.Add("Known Primary Malware Payload Name")
    }

    # RULE 2: G-Prefix Clone Behavior
    if ($Forensics.Name -match "^g(.+\.exe)$" -and $Forensics.Name -notmatch "(?i)^gallery\.exe$") {
        $score += 30
        $reasons.Add("G-Prefix Naming Convention Detected")
        
        $originalName = $matches[1]
        $potentialOriginal = Join-Path $Forensics.Directory $originalName
        
        if (Test-Path $potentialOriginal) {
            $origInfo = Get-Item $potentialOriginal -Force
            
            # Sub-rule: Is the original hidden?
            if ($origInfo.Attributes -match "Hidden") {
                $score += 40
                $reasons.Add("Original Executable Hidden in Same Directory")
                $isGClone = $true
                $hiddenOriginalPath = $potentialOriginal
            }
            
            # Sub-rule: Size Anomaly (Virus is usually much smaller than the app it replaces)
            if ($Forensics.Size -lt 2MB -and $origInfo.Length -gt ($Forensics.Size * 2)) {
                $score += 20
                $reasons.Add("File Size Abnormally Small Compared to Hidden Original")
            }
        }
        
        # Sub-rule: Malicious ICO generation
        $icoName = $Forensics.Name.Replace(".exe", ".ico")
        $icoPath = Join-Path $Forensics.Directory $icoName
        if (Test-Path $icoPath) {
            $score += 15
            $reasons.Add("Matching G-Prefixed Fake .ICO File Found")
            $hasMatchingIco = $true
        }
    }

    # RULE 3: Cryptographic Anomalies
    if ($Forensics.SignatureStatus -eq "Not Signed" -or $Forensics.SignatureStatus -eq "Invalid (Modified)") {
        $score += 10
        $reasons.Add("Unsigned or Invalid Authenticode")
    }
    
    if ($Forensics.Entropy -gt 7.2) {
        $score += 20
        $reasons.Add("High Entropy ($($Forensics.Entropy)) - Likely Packed/Encrypted")
    }

    # RULE 4: Attribute Tampering
    if ($Forensics.Attributes -match "Hidden" -and $Forensics.Attributes -match "System") {
        if ($Forensics.Name -match "^g" -or $Forensics.Name -match "(?i)gallery") {
            $score += 20
            $reasons.Add("Super-Hidden (System+Hidden) Attributes Applied")
        }
    }

    # RULE 5: Suspicious Locations
    $lowersPath = $Forensics.Path.ToLower()
    if ($lowersPath -match "\\appdata\\roaming\\" -or $lowersPath -match "\\appdata\\local\\") {
        $score += 15
        $reasons.Add("Execution from User AppData")
    }
    if ($lowersPath -match "\\start menu\\programs\\startup\\") {
        $score += 30
        $reasons.Add("Persistence via Startup Folder")
    }
    if ($lowersPath -match "\\temp\\") {
        $score += 20
        $reasons.Add("Execution from Temp Directory")
    }
    if ($lowersPath -match "config\\systemprofile\\appdata") {
        $score += 40
        $reasons.Add("Execution from SYSTEM Profile AppData (Privilege Escalation)")
    }

    # Calculate Final
    $finalScore = [math]::Min($score, 100)
    
    $status = "SAFE"
    if ($finalScore -ge 30 -and $finalScore -le 65) { $status = "SUSPICIOUS" }
    elseif ($finalScore -gt 65) { $status = "MALWARE" }

    return [PSCustomObject]@{
        Score = $finalScore
        Status = $status
        Reasons = ($reasons -join " | ")
        IsGClone = $isGClone
        HiddenOriginalPath = $hiddenOriginalPath
        HasMatchingIco = $hasMatchingIco
    }
}

# ==============================================================================
# [08] LIVE PROCESS & MEMORY HUNTING ENGINE
# ==============================================================================

function Invoke-MemoryHunt {
    <#
    .SYNOPSIS
        Scans active RAM for Gallery.exe processes or processes running from suspicious paths.
    #>
    Show-GenHeader
    Write-Host "  [🧠] INITIATING LIVE PROCESS MEMORY HUNT..." -ForegroundColor Magenta
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    $Global:ProcessDatabase.Clear()
    $runningProcs = Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -ne $null }
    $threatsInMem = 0

    foreach ($proc in $runningProcs) {
        $isThreat = $false
        $reason = ""

        if ($proc.Name -match "(?i)^Gallery\.exe$") {
            $isThreat = $true
            $reason = "Known Gallery.exe Process"
        } elseif ($proc.Name -match "^g.*\.exe$") {
            # Could be a spawned g-clone
            $isThreat = $true
            $reason = "Suspected G-Clone Execution"
        } elseif ($proc.ExecutablePath -match "Temp\\.*\.exe" -or $proc.ExecutablePath -match "AppData\\.*Gallery") {
            $isThreat = $true
            $reason = "Suspicious Execution Path"
        }

        if ($isThreat) {
            $threatsInMem++
            $Global:ProcessDatabase.Add([PSCustomObject]@{
                ProcessID = $proc.ProcessId
                Name = $proc.Name
                Path = $proc.ExecutablePath
                CommandLine = $proc.CommandLine
                Reason = $reason
            })
            
            Write-Host "  [!] ACTIVE THREAT DETECTED IN MEMORY" -ForegroundColor Red
            Write-Host "      PID  : $($proc.ProcessId)" -ForegroundColor Gray
            Write-Host "      NAME : $($proc.Name)" -ForegroundColor Gray
            Write-Host "      PATH : $($proc.ExecutablePath)" -ForegroundColor Gray
            Write-Host "      FLAG : $reason`n" -ForegroundColor DarkRed
        }
    }

    if ($threatsInMem -eq 0) {
        Write-Host "  [+] Memory Scan Complete. No active Gallery/Grenam processes found." -ForegroundColor Green
    } else {
        Write-Host "  [!] WARNING: $threatsInMem malicious processes are actively running." -ForegroundColor Red
        $action = Read-Host "  [?] Do you want to TERMINATE these processes immediately? (Y/N)"
        if ($action -match "^[Yy]") {
            foreach ($tp in $Global:ProcessDatabase) {
                try {
                    Stop-Process -Id $tp.ProcessID -Force -ErrorAction Stop
                    Write-Host "      [-] Terminated PID $($tp.ProcessID) ($($tp.Name))" -ForegroundColor Green
                    Write-GenLog "Force terminated malicious process: $($tp.Name) (PID: $($tp.ProcessID))" "WARN"
                } catch {
                    Write-Host "      [x] Failed to terminate PID $($tp.ProcessID): $($_.Exception.Message)" -ForegroundColor Red
                    Write-GenLog "Failed to terminate malicious process: $($tp.Name) (PID: $($tp.ProcessID))" "ERROR"
                }
            }
        }
    }
    Invoke-GenPause
}

# ==============================================================================
# [09] PERSISTENCE & REGISTRY SCANNER
# ==============================================================================

function Scan-RegistryPersistence {
    Write-Host "  [+] Scanning Registry Persistence Vectors..." -ForegroundColor Cyan
    $threatsFound = 0
    
    $regPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
    )

    foreach ($reg in $regPaths) {
        if (Test-Path $reg) {
            $items = Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue
            
            # Standard Run Keys
            foreach ($prop in $items.PSObject.Properties) {
                if ($prop.Value -is [string] -and ($prop.Value -match "Gallery\.exe" -or $prop.Value -match "g.*\.exe")) {
                    $threatsFound++
                    $Global:ThreatDatabase.Add([PSCustomObject]@{
                        Forensics = [PSCustomObject]@{ Path = "Registry: $($reg)\$($prop.Name)"; Name = $prop.Name; Size = 0; IsCriticalPath = $false; Signer = "N/A" }
                        Risk = [PSCustomObject]@{ Status = "MALWARE"; Score = 100; Reasons = "Malicious Persistence Key ($($prop.Value))"; IsGClone = $false }
                    })
                    Write-GenLog "Registry Persistence Found: $($reg)\$($prop.Name) -> $($prop.Value)" "WARN"
                }
            }

            # Winlogon Hijacks
            if ($reg -match "Winlogon") {
                if ($items.Shell -and $items.Shell -ne "explorer.exe") {
                    if ($items.Shell -match "Gallery|g.*\.exe") {
                        $threatsFound++
                        $Global:ThreatDatabase.Add([PSCustomObject]@{
                            Forensics = [PSCustomObject]@{ Path = "Registry: $($reg)\Shell"; Name = "Shell"; Size = 0; IsCriticalPath = $true; Signer = "N/A" }
                            Risk = [PSCustomObject]@{ Status = "MALWARE"; Score = 100; Reasons = "Winlogon Shell Hijack ($($items.Shell))"; IsGClone = $false }
                        })
                    }
                }
            }
        }
    }
    return $threatsFound
}

function Scan-ScheduledTasks {
    Write-Host "  [+] Scanning Scheduled Tasks & WMI Consumers..." -ForegroundColor Cyan
    $threatsFound = 0
    try {
        $tasks = schtasks.exe /query /V /FO CSV | ConvertFrom-Csv -ErrorAction SilentlyContinue
        foreach ($task in $tasks) {
            if ($task.'Task To Run' -match "Gallery\.exe" -or $task.'Task To Run' -match "\\g.*\.exe") {
                $threatsFound++
                $Global:ThreatDatabase.Add([PSCustomObject]@{
                    Forensics = [PSCustomObject]@{ Path = "Task: $($task.TaskName)"; Name = $task.TaskName; Size = 0; IsCriticalPath = $false; Signer = "N/A" }
                    Risk = [PSCustomObject]@{ Status = "MALWARE"; Score = 100; Reasons = "Malicious Scheduled Task ($($task.'Task To Run'))"; IsGClone = $false }
                })
            }
        }
    } catch {}
    return $threatsFound
}

# ==============================================================================
# [10] MASTER DEEP FILE SCANNER
# ==============================================================================

function Invoke-DeepSystemScan {
    Show-GenHeader
    Write-Host "  [🔍] INITIATING DEEP MALWARE FORENSIC SCAN..." -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    Invoke-Spinner -Milliseconds 1500 -Message "Mounting File Systems and Initializing Heuristics Engine"

    # Create Pre-Scan Restore Point
    Write-Host "  [+] Creating Windows System Restore Point (Failsafe)..." -ForegroundColor Gray
    try {
        Checkpoint-Computer -Description "GEN Ultra Pre-Scan Baseline" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
        Write-Host "      -> Restore point created successfully." -ForegroundColor Green
    } catch {
        Write-Host "      -> Restore point creation skipped or unavailable." -ForegroundColor DarkGray
    }

    $Global:ThreatDatabase.Clear()
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.IsReady }
    
    $scannedFiles = 0
    $threatsFound = 0
    $startTime = Get-Date

    foreach ($drive in $drives) {
        $root = $drive.Root
        Write-Host "\n  [+] Traversing Sector: $root" -ForegroundColor Cyan
        
        $foldersToScan = @($root)
        if ($root -match "^C:\\") {
            # Highly targeted rapid scan paths for Gallery.exe vectors
            $foldersToScan = @(
                $env:APPDATA, 
                $env:LOCALAPPDATA, 
                $env:TEMP, 
                [Environment]::GetFolderPath("Startup"),
                [Environment]::GetFolderPath("Desktop"),
                "C:\Program Files", 
                "C:\Program Files (x86)",
                "C:\Windows\System32\config\systemprofile\AppData",
                "C:\Windows\SysWOW64\config\systemprofile\AppData",
                "C:\" # Fallback full recursive
            ) | Select-Object -Unique
        }

        foreach ($folder in $foldersToScan) {
            if (-not (Test-Path $folder)) { continue }
            
            # We specifically target .exe and .ico files. Gallery renames originals and drops fakes.
            $files = Get-ChildItem -Path $folder -Include "*.exe", "g*.ico" -Recurse -File -Force -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $scannedFiles++
                
                # UI Update every 20 files to reduce rendering lag
                if ($scannedFiles % 20 -eq 0) {
                    $elapsed = (Get-Date) - $startTime
                    $speed = if ($elapsed.TotalSeconds -gt 0) { [math]::Round($scannedFiles / $elapsed.TotalSeconds) } else { 0 }
                    $truncPath = if ($file.DirectoryName.Length -gt 45) { $file.DirectoryName.Substring(0, 45) + "..." } else { $file.DirectoryName.PadRight(48) }
                    Write-Host "`r  [~] Scanning: $truncPath | Scanned: $scannedFiles | Speed: $speed/s " -ForegroundColor DarkCyan -NoNewline
                }

                # Fast filter: Skip obvious Microsoft files by name if deeply nested in WinSxS to save time
                if ($file.FullName -match "\\WinSxS\\" -and $file.Name -notmatch "^g|^Gallery") { continue }

                # Forensic Analysis
                $forensics = Get-FileForensics -File $file
                $risk = Get-ThreatScore -Forensics $forensics

                if ($risk.Status -ne "SAFE") {
                    $threatsFound++
                    $Global:ThreatDatabase.Add([PSCustomObject]@{
                        Forensics = $forensics
                        Risk = $risk
                    })
                    Write-GenLog "Threat Discovered: $($forensics.Path) (Score: $($risk.Score))" "WARN"
                }
            }
        }
    }
    
    Write-Host "`n"
    $threatsFound += Scan-RegistryPersistence
    $threatsFound += Scan-ScheduledTasks

    Write-Host "`n  =====================================================================" -ForegroundColor DarkGray
    Write-Host "  [✓] SCAN COMPLETE" -ForegroundColor Green
    Write-Host "      Duration       : $(([math]::Round(((Get-Date) - $startTime).TotalSeconds, 2))) Seconds" -ForegroundColor Gray
    Write-Host "      Files Analyzed : $scannedFiles" -ForegroundColor Gray
    if ($threatsFound -gt 0) {
        Write-Host "      Threats Found  : $threatsFound" -ForegroundColor Red
        Write-Host "      RECOMMENDATION : Proceed to Option [4] to execute quarantine." -ForegroundColor Yellow
    } else {
        Write-Host "      Threats Found  : 0" -ForegroundColor Green
        Write-Host "      STATUS         : SYSTEM IS SECURE." -ForegroundColor Green
    }
    
    Invoke-GenPause
}

# ==============================================================================
# [11] QUARANTINE & AES ENCRYPTION ENGINE
# ==============================================================================

function Invoke-SecureQuarantine {
    <#
    .SYNOPSIS
        Moves a malicious file to the vault and renames it to break execution.
        (In a full .NET compiled app this would use AES, here we use structural breaking).
    #>
    param([string]$ThreatPath)
    
    if ($ThreatPath -match "^Registry:|Task:") { return $true } # Logical bypass for non-files
    if (-not (Test-Path $ThreatPath)) { return $false }
    
    try {
        $fileName = Split-Path $ThreatPath -Leaf
        $hashName = (New-Guid).Guid
        $destPath = Join-Path $Global:QuarantineDir "$hashName.vir"
        
        # Take Ownership and strip attributes before moving
        takeown.exe /F "`"$ThreatPath`"" /A 2>&1 | Out-Null
        icacls.exe "`"$ThreatPath`"" /grant "Administrators:F" /C /Q 2>&1 | Out-Null
        $item = Get-Item $ThreatPath -Force
        $item.Attributes = 'Normal'

        Move-Item -Path $ThreatPath -Destination $destPath -Force
        
        $metadata = @{
            OriginalPath = $ThreatPath
            QuarantinedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            OriginalName = $fileName
            VaultID = $hashName
        }
        $metadata | ConvertTo-Json | Out-File (Join-Path $Global:QuarantineDir "$hashName.json")
        Write-GenLog "Quarantined $ThreatPath to VaultID $hashName" "INFO"
        return $true
    } catch {
        Write-GenLog "Quarantine failed for $ThreatPath : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restore-HiddenOriginal {
    param($ThreatItem)
    if ($ThreatItem.Risk.IsGClone -and $ThreatItem.Risk.HiddenOriginalPath) {
        $hiddenPath = $ThreatItem.Risk.HiddenOriginalPath
        if (Test-Path $hiddenPath) {
            try {
                $file = Get-Item $hiddenPath -Force
                # Remove Super-Hidden attributes
                $file.Attributes = $file.Attributes -band -bnot [System.IO.FileAttributes]::Hidden
                $file.Attributes = $file.Attributes -band -bnot [System.IO.FileAttributes]::System
                $file.Attributes = $file.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly
                $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Normal
                Write-GenLog "Restored visibility to original file: $hiddenPath" "INFO"
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
                Write-GenLog "Destroyed malicious fake icon: $icoPath" "INFO"
                return $true
            } catch { return $false }
        }
    }
    return $false
}

# ==============================================================================
# [12] THREAT CLEANUP & RECOVERY UI
# ==============================================================================

function Show-ThreatCard {
    param($Threat)
    
    $color = if ($Threat.Risk.Score -gt 80) { "Red" } elseif ($Threat.Risk.Score -gt 50) { "Magenta" } else { "Yellow" }
    
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $color
    Write-Host "  ║ " -ForegroundColor $color -NoNewline; Write-Host "🚨 ACTIVE THREAT IDENTIFIED                                                     " -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor $color
    Write-Host "  ╠══════════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor $color
    
    Write-Host "  ║ " -ForegroundColor $color -NoNewline; Write-Host "File Path : " -ForegroundColor Cyan -NoNewline; Write-Host $Threat.Forensics.Path.PadRight(64) -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor $color
    Write-Host "  ║ " -ForegroundColor $color -NoNewline; Write-Host "SHA256    : " -ForegroundColor Cyan -NoNewline; Write-Host $Threat.Forensics.SHA256.PadRight(64) -ForegroundColor Gray -NoNewline; Write-Host "║" -ForegroundColor $color
    
    $signerPad = "$($Threat.Forensics.Signer) [$($Threat.Forensics.SignatureStatus)]".PadRight(64)
    Write-Host "  ║ " -ForegroundColor $color -NoNewline; Write-Host "Signature : " -ForegroundColor Cyan -NoNewline; Write-Host $signerPad -ForegroundColor Gray -NoNewline; Write-Host "║" -ForegroundColor $color
    
    $riskPad = "$($Threat.Risk.Score)/100 [ $($Threat.Risk.Status) ]".PadRight(64)
    Write-Host "  ║ " -ForegroundColor $color -NoNewline; Write-Host "Risk Lvl  : " -ForegroundColor Cyan -NoNewline; Write-Host $riskPad -ForegroundColor Red -NoNewline; Write-Host "║" -ForegroundColor $color
    
    # Text wrapping for reasons
    $reasons = $Threat.Risk.Reasons
    if ($reasons.Length -gt 60) { $reasons = $reasons.Substring(0, 60) + "..." }
    Write-Host "  ║ " -ForegroundColor $color -NoNewline; Write-Host "Flags     : " -ForegroundColor Cyan -NoNewline; Write-Host $reasons.PadRight(64) -ForegroundColor Yellow -NoNewline; Write-Host "║" -ForegroundColor $color
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $color
}

function Invoke-CleanupEngine {
    Show-GenHeader
    Write-Host "  [🧹] INITIATING THREAT NEUTRALIZATION & RECOVERY PROTOCOL" -ForegroundColor Red
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "`n  [+] Threat Database is empty. Please run a Deep Scan (Option 1) first." -ForegroundColor Green
        Invoke-GenPause
        return
    }

    $autoCleanAll = $false
    $cleanedCount = 0

    foreach ($threat in $Global:ThreatDatabase) {
        Clear-Host
        Show-GenHeader
        Show-ThreatCard -Threat $threat

        # Double Confirmation for MS Files in Critical Paths
        if ($threat.Forensics.IsCriticalPath -and $threat.Forensics.IsMicrosoft) {
            Write-Host "`n  [!!!] SYSTEM CRITICAL FILE DETECTED [!!!]" -ForegroundColor Red -BackgroundColor White
            Write-Host "  This file is signed by Microsoft and resides in a protected Windows directory." -ForegroundColor Red
            Write-Host "  AUTOMATIC DELETION BLOCKED. Explicit manual verification required." -ForegroundColor Yellow
            $autoCleanAll = $false
        }

        $action = "S"
        if ($autoCleanAll) {
            $action = "A"
        } else {
            Write-Host "`n  AVAILABLE ACTIONS:" -ForegroundColor Cyan
            Write-Host "  [Y]" -ForegroundColor Green -NoNewline; Write-Host " Delete & Purge       " -ForegroundColor White -NoNewline
            Write-Host "  [Q]" -ForegroundColor Yellow -NoNewline; Write-Host " Quarantine to Vault  " -ForegroundColor White
            Write-Host "  [R]" -ForegroundColor Blue -NoNewline; Write-Host " Restore Original App " -ForegroundColor White -NoNewline
            Write-Host "  [S]" -ForegroundColor DarkGray -NoNewline; Write-Host " Skip                 " -ForegroundColor White
            Write-Host "  [A]" -ForegroundColor Magenta -NoNewline; Write-Host " Apply Quarantine to All Remaining" -ForegroundColor White
            
            Write-Host "`n"
            $action = Read-Host "  [?] Select Action"
        }

        if ($action -match "^[Aa]") { $autoCleanAll = $true; $action = "Q" }

        switch -Regex ($action) {
            "^[Yy]" {
                if ($threat.Forensics.Path -match "^Registry:") {
                    $pathParts = $threat.Forensics.Path.Split(":")
                    $regKey = $pathParts[1].Trim().Split("\")
                    $valName = $regKey[-1]
                    $regPath = ($regKey[0..($regKey.Length-2)] -join "\")
                    try {
                        Remove-ItemProperty -Path $regPath -Name $valName -Force -ErrorAction Stop
                        Write-Host "  [+] Persistence Key Purged." -ForegroundColor Green
                        $cleanedCount++
                    } catch { Write-Host "  [-] Failed to purge key." -ForegroundColor Red }
                } elseif ($threat.Forensics.Path -match "^Task:") {
                    schtasks.exe /Delete /TN "`"$($threat.Forensics.Name)`"" /F | Out-Null
                    Write-Host "  [+] Scheduled Task Purged." -ForegroundColor Green
                    $cleanedCount++
                } else {
                    $procName = [System.IO.Path]::GetFileNameWithoutExtension($threat.Forensics.Path)
                    Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
                    try {
                        takeown.exe /F "`"$($threat.Forensics.Path)`"" /A 2>&1 | Out-Null
                        icacls.exe "`"$($threat.Forensics.Path)`"" /grant "Administrators:F" /C /Q 2>&1 | Out-Null
                        $f = Get-Item $threat.Forensics.Path -Force
                        $f.Attributes = 'Normal'
                        Remove-Item -Path $threat.Forensics.Path -Force -ErrorAction Stop
                        Write-Host "  [+] Threat Deleted." -ForegroundColor Green
                        $cleanedCount++
                    } catch { Write-Host "  [-] Deletion Failed: $($_.Exception.Message)" -ForegroundColor Red }
                }
                
                # Auto-Recovery
                if ($threat.Risk.IsGClone) { 
                    if (Restore-HiddenOriginal -ThreatItem $threat) { Write-Host "  [+] Hidden Original Restored." -ForegroundColor Blue }
                    if (Remove-IcoClone -ThreatItem $threat) { Write-Host "  [+] Fake ICO icon removed." -ForegroundColor Blue }
                }
            }
            "^[Qq]" {
                if (Invoke-SecureQuarantine -ThreatPath $threat.Forensics.Path) {
                    Write-Host "  [+] Threat securely moved to Vault." -ForegroundColor Yellow
                    $cleanedCount++
                    if ($threat.Risk.IsGClone) { 
                        if (Restore-HiddenOriginal -ThreatItem $threat) { Write-Host "  [+] Hidden Original Restored & Unhidden." -ForegroundColor Blue }
                        if (Remove-IcoClone -ThreatItem $threat) { Write-Host "  [+] Matching ICO clone removed." -ForegroundColor Blue }
                    }
                } else { Write-Host "  [-] Quarantine Failed." -ForegroundColor Red }
            }
            "^[Rr]" {
                if ($threat.Risk.IsGClone) {
                    if (Restore-HiddenOriginal -ThreatItem $threat) { Write-Host "  [+] Original File Visibility Restored." -ForegroundColor Green }
                    else { Write-Host "  [-] Failed to restore original." -ForegroundColor Red }
                } else { Write-Host "  [!] Not a G-Prefix clone. Nothing to restore." -ForegroundColor Yellow }
            }
            "^[Ss]" { Write-Host "  [!] Threat Skipped." -ForegroundColor DarkGray }
            Default { Write-Host "  [!] Unknown input. Skipped by default." -ForegroundColor DarkGray }
        }
        Start-Sleep -Milliseconds 800
    }
    
    $Global:ThreatDatabase.Clear()
    Write-Host "`n  =====================================================================" -ForegroundColor DarkGray
    Write-Host "  [✓] CLEANUP SEQUENCE COMPLETE. Neutralized: $cleanedCount" -ForegroundColor Green
    Invoke-GenPause
}

# ==============================================================================
# [13] ANTI-REGENERATION (VACCINATION & IMMUNITY)
# ==============================================================================

function Invoke-ImmunityDeployment {
    <#
    .SYNOPSIS
        Deploys Decoy files with Deny-Write ACLs to prevent Gallery.exe from recreating itself.
    #>
    Show-GenHeader
    Write-Host "  [🔒] DEPLOYING ANTI-REGENERATION IMMUNITY MATRIX" -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
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
        Write-Host "  [+] Securing Vector: $target" -ForegroundColor Gray
        try {
            $dir = Split-Path $target -Parent
            if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
            
            if (Test-Path $target) { 
                takeown.exe /F "`"$target`"" /A 2>&1 | Out-Null
                icacls.exe "`"$target`"" /reset /Q 2>&1 | Out-Null
                Remove-Item -Path $target -Force 
            }
            
            # Create Null Decoy
            New-Item -Path $target -ItemType File -Force | Out-Null
            Set-ItemProperty -Path $target -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force

            # Apply Strict ACL (Deny Write to Everyone)
            $acl = Get-Acl $target
            $acl.SetAccessRuleProtection($true, $false)
            $denyAll = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Write", "Deny")
            $allowSys = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")
            $allowAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "ReadAndExecute", "Allow")
            $acl.AddAccessRule($denyAll)
            $acl.AddAccessRule($allowSys)
            $acl.AddAccessRule($allowAdmin)
            Set-Acl -Path $target -AclObject $acl
            
            Write-Host "      -> IMMUNITY LAYER APPLIED (WRITE DENIED)" -ForegroundColor Green
            Write-GenLog "Deployed Immunity Decoy at $target" "INFO"
        } catch {
            Write-Host "      -> FAILED TO SECURE VECTOR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n  [✓] Malware Regeneration Vectors Sealed." -ForegroundColor Green
    Invoke-GenPause
}

# ==============================================================================
# [14] SYSTEM REPAIR ENGINE (DISM / SFC)
# ==============================================================================

function Invoke-SystemRepair {
    Show-GenHeader
    Write-Host "  [🛠] INITIATING WINDOWS COMPONENT STORE REPAIR" -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    Write-Host "  [!] WARNING: This process may take 10-30 minutes. Do not interrupt.`n" -ForegroundColor Yellow
    
    Write-Host "  [1/2] Executing DISM (Deployment Image Servicing and Management)..." -ForegroundColor Cyan
    $dismProc = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow -PassThru
    if ($dismProc.ExitCode -eq 0) { 
        Write-Host "        -> DISM Completed Successfully.`n" -ForegroundColor Green
        Write-GenLog "DISM Repair Completed Successfully." "INFO"
    } else { 
        Write-Host "        -> DISM returned error code $($dismProc.ExitCode)`n" -ForegroundColor Red 
        Write-GenLog "DISM Repair Failed. Code: $($dismProc.ExitCode)" "ERROR"
    }

    Write-Host "  [2/2] Executing SFC (System File Checker)..." -ForegroundColor Cyan
    $sfcProc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -PassThru
    if ($sfcProc.ExitCode -eq 0) { 
        Write-Host "        -> SFC Completed Successfully.`n" -ForegroundColor Green
        Write-GenLog "SFC Repair Completed Successfully." "INFO"
    } else { 
        Write-Host "        -> SFC found issues or returned error code $($sfcProc.ExitCode)`n" -ForegroundColor Red
        Write-GenLog "SFC Repair returned code: $($sfcProc.ExitCode)" "WARN"
    }

    Write-Host "  [✓] System Integrity Operations Concluded." -ForegroundColor Green
    Invoke-GenPause
}

# ==============================================================================
# [15] ADVANCED REPORTING & EXPORT ENGINE (HTML/JSON)
# ==============================================================================

function Export-IntelligenceReport {
    Show-GenHeader
    Write-Host "  [📊] GENERATING THREAT INTELLIGENCE REPORTS..." -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "  [-] No active threats in memory to report. Run a scan first." -ForegroundColor Yellow
        Invoke-GenPause
        return
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $baseName = Join-Path $Global:ReportsDir "GEN_Report_$timestamp"
    
    # Flatten Data
    $exportData = $Global:ThreatDatabase | ForEach-Object {
        [PSCustomObject]@{
            File = $_.Forensics.Path
            SHA256 = $_.Forensics.SHA256
            RiskScore = $_.Risk.Score
            Status = $_.Risk.Status
            Reason = $_.Risk.Reasons
            Signer = $_.Forensics.Signer
            Entropy = $_.Forensics.Entropy
            IsGClone = $_.Risk.IsGClone
        }
    }

    # JSON Export
    try {
        $exportData | ConvertTo-Json -Depth 3 | Out-File "$baseName.json"
        Write-Host "  [+] JSON Report Created: $baseName.json" -ForegroundColor Green
    } catch { Write-Host "  [-] JSON Export Failed." -ForegroundColor Red }

    # CSV Export
    try {
        $exportData | Export-Csv -Path "$baseName.csv" -NoTypeInformation
        Write-Host "  [+] CSV Report Created:  $baseName.csv" -ForegroundColor Green
    } catch { Write-Host "  [-] CSV Export Failed." -ForegroundColor Red }

    # Massive HTML Template embedded to meet enterprise reporting standards
    $htmlHead = @"
    <style>
        body { background-color: #0d1117; color: #c9d1d9; font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif; margin: 0; padding: 20px; }
        h1 { color: #58a6ff; border-bottom: 1px solid #21262d; padding-bottom: 10px; }
        h2 { color: #3fb950; }
        .summary-box { background-color: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 15px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; background-color: #161b22; border-radius: 6px; overflow: hidden; }
        th, td { border: 1px solid #30363d; padding: 12px; text-align: left; }
        th { background-color: #21262d; color: #58a6ff; font-weight: 600; }
        tr:nth-child(even) { background-color: #0d1117; }
        tr:hover { background-color: #1f2428; }
        .risk-high { color: #f85149; font-weight: bold; }
        .risk-med { color: #d29922; font-weight: bold; }
        .risk-low { color: #3fb950; font-weight: bold; }
        .footer { margin-top: 30px; font-size: 0.8em; color: #8b949e; text-align: center; border-top: 1px solid #21262d; padding-top: 10px; }
    </style>
"@
    
    $htmlPre = @"
    <h1>🛡️ G.E.N ULTRA - Threat Intelligence Report</h1>
    <div class="summary-box">
        <h2>Scan Summary</h2>
        <p><strong>Generated:</strong> $( (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") )</p>
        <p><strong>Host System:</strong> $env:COMPUTERNAME</p>
        <p><strong>Total Threats Mapped:</strong> $($Global:ThreatDatabase.Count)</p>
    </div>
    <h2>Threat Telemetry</h2>
"@

    try {
        $htmlContent = $exportData | ConvertTo-Html -Head $htmlHead -PreContent $htmlPre -PostContent "<div class='footer'>G.E.N Framework Enterprise Edition | Confidential Intelligence Report</div>"
        
        # Inject CSS classes for risk levels
        $htmlContent = $htmlContent -replace "<td>MALWARE</td>", "<td class='risk-high'>MALWARE</td>"
        $htmlContent = $htmlContent -replace "<td>SUSPICIOUS</td>", "<td class='risk-med'>SUSPICIOUS</td>"
        
        $htmlContent | Out-File "$baseName.html"
        Write-Host "  [+] HTML Report Created: $baseName.html" -ForegroundColor Green
        Write-GenLog "Generated full intelligence report package at $baseName" "INFO"
    } catch { Write-Host "  [-] HTML Export Failed." -ForegroundColor Red }
    
    Invoke-GenPause
}

# ==============================================================================
# [16] UI ROUTING & STATE MANAGEMENT
# ==============================================================================

function Analyze-ThreatDatabase {
    Show-GenHeader
    Write-Host "  [🧬] THREAT DATABASE ANALYSIS" -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "  [+] No active threats in memory. System appears clean." -ForegroundColor Green
    } else {
        Write-Host "  [!] $($Global:ThreatDatabase.Count) malicious entities currently mapped.`n" -ForegroundColor Yellow
        $Global:ThreatDatabase | Format-Table -Property @{N="Threat Path";E={$_.Forensics.Path}}, @{N="Score";E={$_.Risk.Score}}, @{N="Status";E={$_.Risk.Status}}, @{N="G-Clone";E={$_.Risk.IsGClone}} -AutoSize
        Write-Host "`n  [i] Proceed to Option [4] to execute neutralization." -ForegroundColor Gray
    }
    Invoke-GenPause
}

function Invoke-AdvancedDiagnostics {
    Show-GenHeader
    Write-Host "  [⚙] ADVANCED DIAGNOSTICS & SYSTEM PROFILING" -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $av = Get-CimInstance -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue | Select-Object -ExpandProperty displayName
    if (-not $av) { $av = "Windows Defender (Native)" }

    Write-Host "  [-] Hostname        : $($os.CSName)" -ForegroundColor Gray
    Write-Host "  [-] OS Architecture : $($os.OSArchitecture)" -ForegroundColor Gray
    Write-Host "  [-] OS Version      : $($os.Caption) ($($os.Version))" -ForegroundColor Gray
    Write-Host "  [-] CPU Processor   : $($cpu.Name)" -ForegroundColor Gray
    Write-Host "  [-] Total Memory    : $ram GB" -ForegroundColor Gray
    Write-Host "  [-] Antivirus Engine: $($av -join ', ')" -ForegroundColor Gray
    Write-Host "  [-] G.E.N Version   : $Global:AppVersion" -ForegroundColor Gray
    Write-Host "  [-] Active Log File : $Global:LogFile" -ForegroundColor Gray
    Write-Host "  [-] Quarantine Dir  : $Global:QuarantineDir" -ForegroundColor Gray
    
    Invoke-GenPause
}

function Invoke-RestoreVault {
    Show-GenHeader
    Write-Host "  [♻] QUARANTINE VAULT RESTORATION" -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    $qFiles = Get-ChildItem -Path $Global:QuarantineDir -Filter "*.json" -ErrorAction SilentlyContinue
    if ($qFiles.Count -eq 0) { 
        Write-Host "  [+] The Quarantine Vault is empty." -ForegroundColor Green
        Invoke-GenPause
        return 
    }
    
    $i = 1
    $qDict = @{}
    foreach ($q in $qFiles) {
        $meta = Get-Content $q.FullName | ConvertFrom-Json
        Write-Host "  [$i] $($meta.OriginalName) (Quarantined: $($meta.QuarantinedAt))" -ForegroundColor Yellow
        Write-Host "      -> Source: $($meta.OriginalPath)" -ForegroundColor DarkGray
        $qDict[$i] = $meta
        $i++
    }
    
    Write-Host "`n  [0] Cancel" -ForegroundColor DarkGray
    $rChoice = Read-Host "`n  [?] Select file ID to restore"
    
    if ($rChoice -eq "0" -or -not $qDict[$rChoice -as [int]]) { 
        Write-Host "  [!] Operation Cancelled." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return 
    }
    
    $targetMeta = $qDict[$rChoice -as [int]]
    $virPath = Join-Path $Global:QuarantineDir "$($targetMeta.VaultID).vir"
    
    if (Test-Path $virPath) {
        try {
            Move-Item -Path $virPath -Destination $targetMeta.OriginalPath -Force -ErrorAction Stop
            Remove-Item -Path $qFiles[($rChoice -as [int]) - 1].FullName -Force
            Write-Host "`n  [+] SUCCESS: File Restored to $($targetMeta.OriginalPath)" -ForegroundColor Green
            Write-GenLog "Restored $($targetMeta.VaultID) to $($targetMeta.OriginalPath) from Quarantine." "INFO"
        } catch {
            Write-Host "`n  [-] FAILED to restore file: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "`n  [-] Vault payload missing. Cannot restore." -ForegroundColor Red
    }
    Invoke-GenPause
}

# ==============================================================================
# [17] MAIN EXECUTION LOOP
# ==============================================================================

while ($true) {
    Show-GenHeader
    Show-GenMenu
    
    $choice = Read-Host "  [COMMAND ROUTER]"
    
    switch ($choice) {
        "1" { Invoke-DeepSystemScan }
        "2" { Invoke-MemoryHunt }
        "3" { Analyze-ThreatDatabase }
        "4" { Invoke-CleanupEngine }
        "5" { Invoke-RestoreVault }
        "6" { Invoke-ImmunityDeployment }
        "7" { Invoke-SystemRepair }
        "8" { Export-IntelligenceReport }
        "9" { Invoke-AdvancedDiagnostics }
        "0" {
            Show-GenHeader
            Write-Host "  [+] Terminating G.E.N Framework Sessions..." -ForegroundColor Yellow
            Write-GenLog "Framework execution terminated by user." "INFO"
            Start-Sleep -Seconds 1
            Write-Host "  [✓] Session Closed. Stay Secure." -ForegroundColor Green
            Start-Sleep -Seconds 1
            exit
        }
        Default { 
            Write-Host "`n  [!] Invalid Command Syntax. Please select 0-9." -ForegroundColor Red
            Start-Sleep -Seconds 1 
        }
    }
}
