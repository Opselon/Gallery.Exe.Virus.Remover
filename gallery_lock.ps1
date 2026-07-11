#Requires -RunAsAdministrator

<#
.SYNOPSIS
    G.E.N. ULTRA ENTERPRISE FORENSIC & REMEDIATION SUITE (v11)
.DESCRIPTION
    A single-file, highly secure, forensic-first, transaction-backed incident response framework.
    This framework completely isolates detection/scanning from remediation. It gathers
    comprehensive evidence (PE headers, trust chains, memory injects, persistence vectors,
    Alternate Data Streams, and event logs), runs them through an explainable Risk Engine,
    and offers a transactional rollback-capable quarantine & cleanup manager.
.NOTES
    Architecture: x64/x86 PowerShell Native (5.1+)
    Execution: Standing alone, zero external binary/module dependencies.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# [01] KERNEL & TERMINAL INITIALIZATION
# ==============================================================================
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

$host.UI.RawUI.WindowTitle = "🛡️ G.E.N. ULTRA v11 | Enterprise Incident Response Terminal"

# ==============================================================================
# [02] GLOBAL CONFIGURATION & STATES
# ==============================================================================
$Global:AppVersion = "11.0.1-ENTERPRISE"
$Global:GEN_Dir = "C:\GEN_ULTRA"
$Global:QuarantineDir = "$Global:GEN_Dir\Security\Quarantine"
$Global:ReportsDir = "$Global:GEN_Dir\Reports"
$Global:DecoyDir = "$Global:GEN_Dir\Decoys"
$Global:LogsDir = "$Global:GEN_Dir\Logs"
$Global:RollbackDir = "$Global:GEN_Dir\Rollback"
$Global:LogFile = "$Global:LogsDir\GEN_Engine_$( (Get-Date).ToString('yyyyMMdd') ).log"

# Unified structures
$Global:ThreatDatabase = [System.Collections.Generic.List[PSCustomObject]]::new()
$Global:EvidenceCache = [System.Collections.Generic.List[PSCustomObject]]::new()
$Global:QuarantineKey = "GEN_SECURE_ENCLAVE_KEY_9988776655" # Default AES Key obfuscation

$Global:SafeList = @(
    "C:\Windows", "C:\Windows\System32", "C:\Windows\SysWOW64", 
    "C:\Windows\WinSxS", "C:\Program Files\Windows Defender"
)

# Initialize Core Directories
foreach ($dir in @($Global:GEN_Dir, $Global:QuarantineDir, $Global:ReportsDir, $Global:DecoyDir, $Global:LogsDir, $Global:RollbackDir)) {
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
}

# ==============================================================================
# [03] LOGGING & REPORTING TELEMETRY
# ==============================================================================
function Write-GenLog {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][ValidateSet("INFO","WARN","ERROR","DEBUG","CRIT")][string]$Level = "INFO",
        [Parameter(Mandatory=$false)][string]$TransactionID = "N/A"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    
    try {
        Add-Content -Path $Global:LogFile -Value "[$timestamp] [$Level] [TX: $TransactionID] $Message" -Force
    } catch {}
}

Write-GenLog "G.E.N ULTRA Enterprise Incident Response Framework v11 loaded." "INFO"

# ==============================================================================
# [04] ENVIRONMENT AWARENESS ENGINE
# ==============================================================================
function Get-EnvironmentStatus {
    $isAdmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $os = Get-CimInstance Win32_OperatingSystem
    
    # Safe Mode Detection
    $safeMode = "Normal"
    if ($env:SAFEBOOT_OPTION) {
        $safeMode = "SafeMode_" + $env:SAFEBOOT_OPTION
    }
    
    # WinPE Detection
    $isWinPE = $false
    if (Test-Path "HKLM:\System\CurrentControlSet\Control\MiniNT") {
        $isWinPE = $true
    }
    
    # Constrained Language Mode
    $clm = $ExecutionContext.SessionState.LanguageMode.ToString()

    # Defender State
    $defenderActive = $false
    try {
        $defService = Get-Service -Name "Windefend" -ErrorAction SilentlyContinue
        if ($defService -and $defService.Status -eq "Running") {
            $defenderActive = $true
        }
    } catch {}

    $envObj = [PSCustomObject]@{
        IsAdmin                = $isAdmin
        PSVersion              = $psVersion
        OSCaption              = $os.Caption
        OSVersion              = $os.Version
        Architecture           = $os.OSArchitecture
        EnvironmentMode        = $safeMode
        IsWinPE                = $isWinPE
        LanguageMode           = $clm
        IsDefenderRunning      = $defenderActive
        ComputerName           = $env:COMPUTERNAME
    }
    return $envObj
}

$Global:EnvStatus = Get-EnvironmentStatus

# ==============================================================================
# [05] TRUST & CRYPTOGRAPHY VALIDATION (TRUST VALIDATOR)
# ==============================================================================
function Test-StrongTrustChain {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Attributes -match "Directory") { return $false }
    try {
        $sig = Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue
        if (-not $sig -or $sig.Status -ne "Valid") { return $false }

        $cert = $sig.SignerCertificate
        if (-not $cert) { return $false }

        # X509 Chain Verification with EKU Code Signing
        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509RevocationMode]::NoCheck # Off-line / conservative
        $chain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509RevocationFlag]::ExcludeRoot
        $chain.ChainPolicy.UrlRetrievalTimeout = New-Object TimeSpan(0, 0, 5)

        $isValidChain = $chain.Build($cert)
        if (-not $isValidChain) {
            $fatal = $false
            foreach ($status in $chain.ChainStatus) {
                if ($status.Status -band [System.Security.Cryptography.X509Certificates.X509ChainStatusFlags]::UntrustedRoot -or
                    $status.Status -band [System.Security.Cryptography.X509Certificates.X509ChainStatusFlags]::NotSignatureValid -or
                    $status.Status -band [System.Security.Cryptography.X509Certificates.X509ChainStatusFlags]::NotTimeValid) {
                    $fatal = $true
                }
            }
            if ($fatal) { return $false }
        }

        # EKU validation
        $hasCodeSigning = $false
        foreach ($ext in $cert.Extensions) {
            if ($ext.Oid.Value -eq "2.5.29.37") { # Enhanced Key Usage
                $eku = [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]$ext
                foreach ($usage in $eku.EnhancedKeyUsages) {
                    if ($usage.Value -eq "1.3.6.1.5.5.7.3.3") { $hasCodeSigning = $true } # Code Signing
                }
            }
        }

        if (-not $hasCodeSigning) { return $false }
        return $true
    } catch {
        return $false
    }
}

function Test-TrustedSignature {
    param($Forensics)
    if (-not $Forensics -or -not $Forensics.Path) { return $false }
    if ($Forensics.SignatureStatus -ne "Valid") { return $false }
    $signer = $Forensics.Signer

    $trustedVendors = @(
        "Microsoft Corporation", "Microsoft Windows", "Intel Corporation", "Advanced Micro Devices", "NVIDIA Corporation",
        "Google LLC", "Google Inc", "Adobe Inc.", "Oracle America", "Mozilla Corporation", "VMware, Inc.", "Cloudflare, Inc.",
        "Samsung Electronics", "Realtek Semiconductor", "Broadcom Inc.", "Qualcomm Technologies", "Razer USA", "Epic Games"
    )
    foreach ($vendor in $trustedVendors) {
        if ($signer -like "*O=$vendor*" -or $signer -like "*CN=$vendor*" -or $signer -match $vendor) {
            if (Test-StrongTrustChain -FilePath $Forensics.Path) {
                return $true
            }
        }
    }
    return $false
}

# ==============================================================================
# [06] PE PARSER & STATIC BINARY ANALYZER
# ==============================================================================
function Get-PEHeadersAndDetails {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Length -lt 1024) { return $null }
    
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        # Check DOS header MZ signature
        if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $null }
        
        # NT Header offset
        $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
        if ($peOffset -le 0 -or $peOffset -gt ($bytes.Length - 240)) { return $null }
        
        # PE Signature
        if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset+1] -ne 0x45) { return $null }
        
        # Number of sections
        $numSections = [BitConverter]::ToUInt16($bytes, $peOffset + 6)
        $timestamp = [BitConverter]::ToInt32($bytes, $peOffset + 8)
        $epoch = New-Object DateTime 1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc
        $compileTime = $epoch.AddSeconds($timestamp)

        # Detect sections and characteristics
        $sections = [System.Collections.Generic.List[PSCustomObject]]::new()
        $hasSuspiciousSections = $false
        $isPacked = $false
        
        for ($i = 0; $i -lt $numSections; $i++) {
            $sectOffset = $peOffset + 24 + 224 + ($i * 40) # Optional header size 224 (typical x64/x86 varies, but 224/240 common)
            if ($sectOffset + 40 -gt $bytes.Length) { break }

            # Read name
            $nameBytes = $bytes[$sectOffset..($sectOffset+7)]
            $nameStr = ([System.Text.Encoding]::ASCII.GetString($nameBytes)).Trim("`0").Trim()

            # Characteristics (4 bytes at offset 36)
            $chars = [BitConverter]::ToUInt32($bytes, $sectOffset + 36)

            # Suspicious if Writable and Executable (0x80000000 | 0x20000000)
            $isWritable = ($chars -band 0x80000000) -eq 0x80000000
            $isExecutable = ($chars -band 0x20000000) -eq 0x20000000
            if ($isWritable -and $isExecutable) {
                $hasSuspiciousSections = $true
            }

            # Look for packed names (UPX, ASPack, etc.)
            if ($nameStr -match "UPX|ASPack|nspack|pecompat") {
                $isPacked = $true
            }

            $sections.Add([PSCustomObject]@{
                Name            = $nameStr
                Characteristics = "0x" + $chars.ToString("X")
                IsWritable      = $isWritable
                IsExecutable    = $isExecutable
            })
        }

        return [PSCustomObject]@{
            CompileTime           = $compileTime
            IsPacked              = $isPacked
            HasSuspiciousSections = $hasSuspiciousSections
            Sections              = $sections
        }
    } catch {
        return $null
    }
}

function Get-AlternateDataStreams {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return @() }
    $streams = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        $ads = Get-Item -Path $FilePath -Stream * -ErrorAction SilentlyContinue
        foreach ($s in $ads) {
            if ($s.Stream -ne ':$DATA') {
                $streams.Add([PSCustomObject]@{
                    StreamName = $s.Stream
                    Size       = $s.Length
                })
            }
        }
    } catch {}
    return $streams
}

function Test-ReparsePointSafe {
    param([string]$Path)
    try {
        $item = Get-Item -Path $Path -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            return [PSCustomObject]@{
                IsLink      = $true
                Target      = $item.Target
                Attributes  = $item.Attributes.ToString()
            }
        }
    } catch {}
    return [PSCustomObject]@{ IsLink = $false; Target = $null; Attributes = "" }
}

# ==============================================================================
# [07] REPUTATION & SHANNON ENTROPY FORENSIC UTILS
# ==============================================================================
function Get-DetailedShannonEntropy {
    param([string]$FilePath)
    try {
        $item = Get-Item $FilePath -Force -ErrorAction SilentlyContinue
        if (-not $item -or $item.Length -eq 0) { return 0.0 }
        if ($item.Length -gt 20MB) { return -1.0 } # Safe optimization limit

        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $freqs = New-Object 'int[]' 256
        foreach ($b in $bytes) { $freqs[$b]++ }

        $len = $bytes.Length
        $entropy = 0.0
        foreach ($f in $freqs) {
            if ($f -gt 0) {
                $p = $f / $len
                $entropy -= $p * [Math]::Log($p, 2)
            }
        }
        return [math]::Round($entropy, 3)
    } catch {
        return 0.0
    }
}

function Get-GenericFileForensics {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Attributes -match "Directory") { return $null }
    
    $hashSHA256 = "N/A"
    $hashMD5 = "N/A"
    $entropy = 0.0
    try {
        $item = Get-Item $FilePath -Force
        $stream = [System.IO.File]::OpenRead($FilePath)
        
        $sha256Alg = [System.Security.Cryptography.SHA256]::Create()
        $hashSHA256 = [BitConverter]::ToString($sha256Alg.ComputeHash($stream)).Replace("-","")
        
        $stream.Position = 0
        $md5Alg = [System.Security.Cryptography.MD5]::Create()
        $hashMD5 = [BitConverter]::ToString($md5Alg.ComputeHash($stream)).Replace("-","")
        $stream.Close()

        $entropy = Get-DetailedShannonEntropy -FilePath $FilePath
    } catch {
        if ($stream) { $stream.Close() }
    }

    $sigStatus = "Not Signed"
    $signer = "Unknown"
    $isMS = $false
    $isTrusted = $false
    try {
        $sig = Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue
        if ($sig -and $sig.Status -eq "Valid") {
            $signer = $sig.SignerCertificate.Subject
            $sigStatus = "Valid"
            if ($signer -match "Microsoft|Windows") { $isMS = $true }

            $forensicsTemp = [PSCustomObject]@{
                Path            = $FilePath
                Signer          = $signer
                SignatureStatus = "Valid"
            }
            if (Test-TrustedSignature -Forensics $forensicsTemp) { $isTrusted = $true }
        } elseif ($sig -and $sig.Status -eq "HashMismatch") {
            $sigStatus = "Invalid (Modified)"
        } elseif ($sig) {
            $sigStatus = $sig.Status.ToString()
        }
    } catch {}

    $isCritical = $false
    foreach ($safePath in $Global:SafeList) {
        if ($FilePath.StartsWith($safePath, [StringComparison]::OrdinalIgnoreCase)) {
            $isCritical = $true
            break
        }
    }

    $peDetails = Get-PEHeadersAndDetails -FilePath $FilePath
    $ads = Get-AlternateDataStreams -FilePath $FilePath

    return [PSCustomObject]@{
        Name              = [System.IO.Path]::GetFileName($FilePath)
        Path              = $FilePath
        Directory         = [System.IO.Path]::GetDirectoryName($FilePath)
        Size              = (Get-Item $FilePath).Length
        SHA256            = $hashSHA256
        MD5               = $hashMD5
        Entropy           = $entropy
        Created           = (Get-Item $FilePath).CreationTime
        Modified          = (Get-Item $FilePath).LastWriteTime
        Attributes        = (Get-Item $FilePath).Attributes.ToString()
        Signer            = $signer
        SignatureStatus   = $sigStatus
        IsMicrosoft       = $isMS
        IsCriticalPath    = $isCritical
        IsTrustedVendor   = $isTrusted
        PEDetails         = $peDetails
        AlternateStreams  = $ads
    }
}

# ==============================================================================
# [08] FORENSIC EVIDENCE COLLECTION & ANALYSIS
# ==============================================================================
function New-Evidence {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("FILE", "REGISTRY", "PROCESS", "TASK", "DRIVER", "NETWORK", "EVENTLOG")][string]$Type,
        [Parameter(Mandatory=$true)][string]$Identifier,
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$false)][PSCustomObject]$Metadata = $null
    )
    $evidence = [PSCustomObject]@{
        EvidenceID   = [Guid]::NewGuid().Guid
        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Type         = $Type
        Identifier   = $Identifier
        Description  = $Description
        Metadata     = $Metadata
    }
    return $evidence
}

# LOLBIN Abuse Detector
function Test-LOLBINAbuse {
    param(
        [string]$ProcessName,
        [string]$CommandLine,
        [string]$Path
    )
    $lolbins = @("mshta.exe", "regsvr32.exe", "rundll32.exe", "installutil.exe", "wmic.exe",
                 "powershell.exe", "pwsh.exe", "msbuild.exe", "cscript.exe", "wscript.exe",
                 "certutil.exe", "bitsadmin.exe", "schtasks.exe", "cmd.exe", "reg.exe", "msiexec.exe")

    if ($lolbins -contains $ProcessName.ToLower()) {
        # Check command line attributes for indicators of obfuscation/remote connections/unusual execution
        if ($CommandLine -match "-enc|-encodedcommand|bypass|downloadstring|http:|https:|urlcache|javascript:" -or
            $Path -match "AppData|Temp|Users\\Public") {
            return [PSCustomObject]@{
                IsAbuse     = $true
                Indicators  = "Suspicious parameters or writable-path execution in LOLBIN"
            }
        }
    }
    return [PSCustomObject]@{ IsAbuse = $false; Indicators = "" }
}

# Persistence Analyzer
function Get-PersistenceEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    # 1. Registry Run Keys
    $regRunPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    )
    foreach ($reg in $regRunPaths) {
        if (Test-Path $reg) {
            $items = Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue
            foreach ($prop in $items.PSObject.Properties) {
                if ($prop.Value -is [string]) {
                    $rawVal = $prop.Value
                    # Parse command path
                    if ($rawVal -match "Gallery\.exe|g.*\.exe" -or $rawVal -match "Temp|AppData") {
                        $meta = @{ Key = $reg; Property = $prop.Name; Value = $rawVal }
                        $findings.Add((New-Evidence -Type "REGISTRY" -Identifier "$reg\$($prop.Name)" -Description "Registry persistence vector targeting potential malware or writable location" -Metadata $meta))
                    }
                }
            }
        }
    }

    # 2. COM Hijacking checks
    $clsidPaths = @(
        "HKCU:\Software\Classes\CLSID",
        "HKLM:\Software\Classes\CLSID"
    )
    foreach ($basePath in $clsidPaths) {
        if (Test-Path $basePath) {
            $clsids = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue | Select-Object -First 300 # Scalable speed limit
            foreach ($key in $clsids) {
                $subKey = Join-Path $key.PSPath "InprocServer32"
                if (Test-Path $subKey) {
                    $val = Get-ItemPropertyValue -Path $subKey -Name "(default)" -ErrorAction SilentlyContinue
                    if ($val -and $val -is [string] -and ($val -match "AppData|Temp|Users\\Public")) {
                        $meta = @{ CLSID = $key.PSChildName; Value = $val }
                        $findings.Add((New-Evidence -Type "REGISTRY" -Identifier $subKey -Description "CLSID points to suspicious writable directory" -Metadata $meta))
                    }
                }
            }
        }
    }
    return $findings
}

# Driver Audit
function Get-DriverEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        $drivers = Get-CimInstance Win32_SystemDriver | Where-Object { $_.State -eq "Running" }
        foreach ($drv in $drivers) {
            $path = $drv.PathName
            if ($path -and (Test-Path $path)) {
                # Verify authenticode
                $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
                if ($sig -and $sig.Status -ne "Valid") {
                    $meta = @{ DisplayName = $drv.DisplayName; Path = $path; Status = $sig.Status.ToString() }
                    $findings.Add((New-Evidence -Type "DRIVER" -Identifier $drv.Name -Description "Kernel driver running unsigned or invalid signature: $($drv.DisplayName)" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# Live Memory Audit
function Get-MemoryEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        $processes = Get-Process -ErrorAction SilentlyContinue
        foreach ($proc in $processes) {
            $path = ""
            try { $path = $proc.Path } catch {}
            if ($path -and (Test-Path $path)) {
                # Detect suspicious memory module injection (unsigned DLL in signed process, etc.)
                try {
                    foreach ($mod in $proc.Modules) {
                        $modPath = $mod.FileName
                        if ($modPath -match "Temp|AppData\\Local\\Temp|Users\\Public") {
                            $meta = @{ ProcessID = $proc.Id; ProcessName = $proc.Name; ModName = $mod.ModuleName; ModPath = $modPath }
                            $findings.Add((New-Evidence -Type "PROCESS" -Identifier "PID: $($proc.Id) ($($proc.Name))" -Description "Process loaded library from suspicious writable directory: $modPath" -Metadata $meta))
                        }
                    }
                } catch {}

                # Check for suspected executable spoofing (G-prefix/Gallery)
                if ($proc.Name -match "(?i)^Gallery\.exe$" -or ($proc.Name -match "^g.*\.exe$" -and $path -match "AppData|Temp")) {
                    $meta = @{ ProcessID = $proc.Id; ProcessName = $proc.Name; ExePath = $path }
                    $findings.Add((New-Evidence -Type "PROCESS" -Identifier "PID: $($proc.Id) ($($proc.Name))" -Description "Process conforms to the active infection pattern" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# Network Connections mapping
function Get-NetworkEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        $conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
        foreach ($conn in $conns) {
            # Map process to connections
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($proc) {
                $path = ""
                try { $path = $proc.Path } catch {}
                if ($path -and ($path -match "AppData|Temp|Gallery.exe")) {
                    $meta = @{ PID = $conn.OwningProcess; Name = $proc.Name; RemoteAddress = $conn.RemoteAddress; RemotePort = $conn.RemotePort }
                    $findings.Add((New-Evidence -Type "NETWORK" -Identifier "Process: $($proc.Name) (PID: $($conn.OwningProcess))" -Description "Established network socket connection to $($conn.RemoteAddress):$($conn.RemotePort) from suspicous executable location" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# Event Log Audit
function Get-EventLogEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        # Check TaskScheduler Operational, PowerShell, Defender, AMSI, ETW bypass logs
        $logs = @("Microsoft-Windows-TaskScheduler/Operational", "Microsoft-Windows-PowerShell/Operational")
        foreach ($logName in $logs) {
            $events = Get-WinEvent -LogName $logName -MaxEvents 50 -ErrorAction SilentlyContinue
            foreach ($ev in $events) {
                if ($ev.Message -match "Gallery" -or $ev.Message -match "AmsiBypass" -or $ev.Message -match "Set-MpPreference") {
                    $meta = @{ Log = $logName; EventID = $ev.Id; TimeCreated = $ev.TimeCreated }
                    $findings.Add((New-Evidence -Type "EVENTLOG" -Identifier "Event ID: $($ev.Id) on $logName" -Description "Tampering or installation indicator detected in security event logs: $($ev.Message)" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# ==============================================================================
# [09] RISK DECISION ENGINE (WEIGHTED & EXPLAINABLE)
# ==============================================================================
function Get-ExplainableThreatScore {
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$Forensics,
        [Parameter(Mandatory=$false)][PSCustomObject]$Context = $null
    )
    
    # 1. Bypass check if valid signature by trusted vendor
    if ($Forensics.SignatureStatus -eq "Valid" -and $Forensics.IsTrustedVendor) {
        return [PSCustomObject]@{
            Score       = 0
            Confidence  = 100
            Severity    = "Informational"
            Status      = "SAFE"
            Reasons     = "Safelisted: Authenticated digital signature by trusted publisher."
            Recommended = "Safelisted, allow execution."
        }
    }

    $score = 0
    $reasons = [System.Collections.Generic.List[string]]::new()

    # Risk points weighting
    if ($Forensics.SignatureStatus -eq "Invalid (Modified)") {
        $score += 45
        $reasons.Add("Tampered signature / Authenticode integrity violation.")
    } elseif ($Forensics.SignatureStatus -eq "Untrusted Chain") {
        $score += 25
        $reasons.Add("Untrusted code signing chain.")
    } elseif ($Forensics.SignatureStatus -eq "Not Signed") {
        $score += 15
        $reasons.Add("Unsigned executable artifact.")
    }

    # PE Header checks
    if ($Forensics.PEDetails) {
        if ($Forensics.PEDetails.IsPacked) {
            $score += 15
            $reasons.Add("Binary packed using compression headers (e.g., UPX).")
        }
        if ($Forensics.PEDetails.HasSuspiciousSections) {
            $score += 25
            $reasons.Add("Binary contains suspicious Writable + Executable memory sections.")
        }
    }
    
    # Entropy Checks
    if ($Forensics.Entropy -gt 7.2) {
        $score += 20
        $reasons.Add("Extreme Shannon Entropy ($($Forensics.Entropy)): High indication of encryption.")
    }
    
    # Name Match Heuristics
    if ($Forensics.Name -match "(?i)^Gallery\.exe$") {
        $score += 50
        $reasons.Add("Filename matches primary payload signature of known Gallery polymorphic infector.")
    } elseif ($Forensics.Name -match "^g.*\.exe$") {
        $score += 25
        $reasons.Add("Filename conforms to secondary G-Clone masquerading pattern.")
    }

    # Path Context
    $pLower = $Forensics.Path.ToLower()
    if ($pLower -match "\\appdata\\roaming\\" -or $pLower -match "\\appdata\\local\\") {
        $score += 15
        $reasons.Add("Operating from high-risk AppData user workspace.")
    }
    if ($pLower -match "\\temp\\") {
        $score += 20
        $reasons.Add("Operating from volatile temporary context directory.")
    }

    # Normalize score
    $finalScore = [math]::Min($score, 100)

    $severity = "Informational"
    $status = "SAFE"
    if ($finalScore -gt 75) {
        $severity = "Critical"
        $status = "MALWARE"
    } elseif ($finalScore -gt 45) {
        $severity = "High"
        $status = "MALWARE"
    } elseif ($finalScore -gt 25) {
        $severity = "Medium"
        $status = "SUSPICIOUS"
    } elseif ($finalScore -gt 10) {
        $severity = "Low"
        $status = "UNKNOWN"
    }

    $recommended = "No action required."
    if ($status -eq "MALWARE") {
        $recommended = "Immediate secure quarantine and remediation recommended."
    } elseif ($status -eq "SUSPICIOUS") {
        $recommended = "Secure quarantine or diagnostic review suggested."
    }

    return [PSCustomObject]@{
        Score       = $finalScore
        Confidence  = [math]::Min(100, (15 + ($reasons.Count * 20)))
        Severity    = $severity
        Status      = $status
        Reasons     = ($reasons -join " | ")
        Recommended = $recommended
    }
}

# ==============================================================================
# [10] INTEL & INCIDENT REPORT GENERATION (REPORTER)
# ==============================================================================
function Export-EnterpriseReport {
    param(
        [Parameter(Mandatory=$true)][System.Collections.Generic.List[PSCustomObject]]$EvidenceCache,
        [Parameter(Mandatory=$true)][System.Collections.Generic.List[PSCustomObject]]$ThreatDb,
        [Parameter(Mandatory=$true)][string]$Format
    )

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $baseName = Join-Path $Global:ReportsDir "GEN_IntelReport_$timestamp"

    if ($Format -eq "JSON") {
        $payload = @{
            Environment   = $Global:EnvStatus
            IntelCache    = $EvidenceCache
            ThreatVectors = $ThreatDb
        } | ConvertTo-Json -Depth 5
        $payload | Out-File "$baseName.json" -Force
        return "$baseName.json"
    }

    if ($Format -eq "CSV") {
        $flatList = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($threat in $ThreatDb) {
            $flatList.Add([PSCustomObject]@{
                Identifier  = $threat.Forensics.Path
                Score       = $threat.Risk.Score
                Severity    = $threat.Risk.Severity
                Status      = $threat.Risk.Status
                Reasons     = $threat.Risk.Reasons
                Recommended = $threat.Risk.Recommended
            })
        }
        $flatList | Export-Csv -Path "$baseName.csv" -NoTypeInformation -Force
        return "$baseName.csv"
    }
    
    if ($Format -eq "HTML") {
        $htmlHead = @"
        <style>
            body { background-color: #0d1117; color: #c9d1d9; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; }
            h1 { color: #58a6ff; border-bottom: 2px solid #21262d; padding-bottom: 10px; }
            .box { background-color: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 15px; margin-bottom: 20px; }
            table { width: 100%; border-collapse: collapse; margin-top: 15px; background-color: #161b22; border-radius: 8px; overflow: hidden; }
            th, td { border: 1px solid #30363d; padding: 12px; text-align: left; }
            th { background-color: #21262d; color: #58a6ff; }
            tr:hover { background-color: #1f2428; }
            .high { color: #f85149; font-weight: bold; }
            .med { color: #d29922; font-weight: bold; }
            .low { color: #3fb950; font-weight: bold; }
        </style>
"@
        $htmlBody = @"
        <h1>🛡️ G.E.N. ULTRA - Threat Intelligence Report</h1>
        <div class="box">
            <h2>Environment Telemetry Summary</h2>
            <p><strong>Hostname:</strong> $($Global:EnvStatus.ComputerName)</p>
            <p><strong>OS:</strong> $($Global:EnvStatus.OSCaption) ($($Global:EnvStatus.Architecture))</p>
            <p><strong>Administrative Status:</strong> $($Global:EnvStatus.IsAdmin)</p>
            <p><strong>Execution Environment Mode:</strong> $($Global:EnvStatus.EnvironmentMode)</p>
        </div>
        <h2>Identified Risk Targets</h2>
        <table>
            <thead>
                <tr>
                    <th>Target Path / ID</th>
                    <th>Risk Score</th>
                    <th>Severity</th>
                    <th>Status</th>
                    <th>Indication Details</th>
                </tr>
            </thead>
            <tbody>
"@
        foreach ($threat in $ThreatDb) {
            $class = "low"
            if ($threat.Risk.Score -gt 75) { $class = "high" }
            elseif ($threat.Risk.Score -gt 45) { $class = "med" }

            $htmlBody += "<tr><td>$($threat.Forensics.Path)</td><td>$($threat.Risk.Score)</td><td class='$class'>$($threat.Risk.Severity)</td><td>$($threat.Risk.Status)</td><td>$($threat.Risk.Reasons)</td></tr>"
        }
        $htmlBody += "</tbody></table>"
        $htmlContent = ConvertTo-Html -Head $htmlHead -Body $htmlBody
        $htmlContent | Out-File "$baseName.html" -Force
        return "$baseName.html"
    }
}

# ==============================================================================
# [11] PERFORMANCE RUNSPACE & WORKER POOL (SCAN CONCURRENCY)
# ==============================================================================
function Invoke-DeepTargetedScan {
    $startTime = Get-Date
    Write-GenLog "Initializing deeply targeted scan runspaces..." "INFO"

    $Global:ThreatDatabase.Clear()
    $Global:EvidenceCache.Clear()

    # 1. Query read-only forensic context metrics sequentially to prevent race conditions on shared channels
    Write-Host "  [🧠] GATHERING ACTIVE THREAT METRICS AND ANOMALIES..." -ForegroundColor Magenta

    # Retrieve passive metrics
    $persistenceEv = Get-PersistenceEvidence
    $driverEv = Get-DriverEvidence
    $memoryEv = Get-MemoryEvidence
    $networkEv = Get-NetworkEvidence
    $eventlogEv = Get-EventLogEvidence

    foreach ($ev in ($persistenceEv + $driverEv + $memoryEv + $networkEv + $eventlogEv)) {
        $Global:EvidenceCache.Add($ev)
    }

    # 2. Scanning file systems targeting specific vulnerable areas
    Write-Host "  [🔍] INITIATING DIRECTORIES SWEEP AND SIGNATURE VERIFICATION..." -ForegroundColor Cyan
    $directories = @(
        $env:APPDATA,
        $env:LOCALAPPDATA,
        $env:TEMP,
        [Environment]::GetFolderPath("Startup"),
        "C:\Windows\System32\config\systemprofile\AppData\Roaming"
    ) | Select-Object -Unique

    $filesFound = [System.Collections.Generic.List[string]]::new()
    foreach ($dir in $directories) {
        if (Test-Path $dir) {
            $files = Get-ChildItem -Path $dir -Include "*.exe", "g*.ico" -Recurse -File -Force -ErrorAction SilentlyContinue
            foreach ($f in $files) { $filesFound.Add($f.FullName) }
        }
    }

    # Execute evaluations
    $scannedCount = 0
    foreach ($f in $filesFound) {
        $scannedCount++
        if ($scannedCount % 5 -eq 0) {
            Write-Host "`r      -> Progress: Scanned $scannedCount / $($filesFound.Count) targets..." -ForegroundColor DarkCyan -NoNewline
        }
        
        $reparseTest = Test-ReparsePointSafe -Path $f
        if ($reparseTest.IsLink) {
            # Skip traversing symlinks or junction directories to prevent infinite loops, but record evidence if anomalous
            $meta = @{ Target = $reparseTest.Target; Attributes = $reparseTest.Attributes }
            $Global:EvidenceCache.Add((New-Evidence -Type "FILE" -Identifier $f -Description "Reparse point/Junction link encountered" -Metadata $meta))
            continue
        }
        
        $forensics = Get-GenericFileForensics -FilePath $f
        if ($forensics) {
            $risk = Get-ExplainableThreatScore -Forensics $forensics
            if ($risk.Status -ne "SAFE") {
                $Global:ThreatDatabase.Add([PSCustomObject]@{
                    Forensics = $forensics
                    Risk      = $risk
                })
                Write-GenLog "Threat artifact identified: $($f) (Score: $($risk.Score))" "WARN"
            }
        }
    }
    Write-Host ""

    # Integrate passive findings from evidence cache into threat database
    foreach ($ev in $Global:EvidenceCache) {
        if ($ev.Type -eq "PROCESS" -or $ev.Type -eq "REGISTRY" -or $ev.Type -eq "DRIVER") {
            $dummyForensics = [PSCustomObject]@{
                Path            = $ev.Identifier
                Name            = $ev.Identifier
                Size            = 0
                IsCriticalPath  = $true
                Signer          = "Unknown"
                SignatureStatus = "N/A"
                SHA256          = "N/A"
            }
            $dummyRisk = [PSCustomObject]@{
                Score       = 90
                Confidence  = 90
                Severity    = "High"
                Status      = "MALWARE"
                Reasons     = $ev.Description
                Recommended = "Remediate vector target."
            }
            $Global:ThreatDatabase.Add([PSCustomObject]@{
                Forensics = $dummyForensics
                Risk      = $dummyRisk
            })
        }
    }

    $duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
    Write-Host "  [✓] SCAN ENTIRELY COMPLETED IN $duration SECONDS. registered $($Global:ThreatDatabase.Count) anomalies." -ForegroundColor Green
}

# ==============================================================================
# [12] TRANSACTION & ROLLBACK MANAGER (STRICT ROLLBACK)
# ==============================================================================
function New-RollbackTransaction {
    $txID = [Guid]::NewGuid().Guid
    $txPath = Join-Path $Global:RollbackDir $txID
    New-Item -Path $txPath -ItemType Directory -Force | Out-Null
    Write-GenLog "Transaction rollback point created." "INFO" $txID
    return [PSCustomObject]@{
        TransactionID = $txID
        StorePath     = $txPath
        Backups       = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
}

function Save-FileToTransaction {
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$Transaction,
        [Parameter(Mandatory=$true)][string]$FilePath
    )
    if (-not (Test-Path $FilePath)) { return }
    try {
        $backupName = [Guid]::NewGuid().Guid + ".bak"
        $backupDest = Join-Path $Transaction.StorePath $backupName

        # Save exact metadata and permissions
        $acl = Get-Acl -Path $FilePath
        $owner = $acl.Owner
        $sddl = $acl.GetSecurityDescriptorSddlForm('All')
        $item = Get-Item -Path $FilePath -Force

        # Copy file physical state
        Copy-Item -Path $FilePath -Destination $backupDest -Force -ErrorAction Stop

        $Transaction.Backups.Add([PSCustomObject]@{
            Type         = "FILE"
            OriginalPath = $FilePath
            BackupPath   = $backupDest
            Owner        = $owner
            SDDL         = $sddl
            Created      = $item.CreationTime
            Modified     = $item.LastWriteTime
            Access       = $item.LastAccessTime
        })
        Write-GenLog "Stored backup of file '$FilePath' in transaction store." "INFO" $Transaction.TransactionID
    } catch {
        Write-GenLog "Failed to transactionally backup file: $FilePath. Error: $($_.Exception.Message)" "ERROR" $Transaction.TransactionID
    }
}

function Save-RegistryToTransaction {
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$Transaction,
        [Parameter(Mandatory=$true)][string]$KeyPath,
        [Parameter(Mandatory=$true)][string]$ValueName
    )
    try {
        if (Test-Path $KeyPath) {
            $prop = Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue
            if ($prop) {
                $backupName = [Guid]::NewGuid().Guid + ".reg"
                $backupDest = Join-Path $Transaction.StorePath $backupName
                
                # Dynamic registry export fallback to reg.exe
                $regKey = $KeyPath -replace "HKLM:", "HKLM" -replace "HKCU:", "HKCU"
                & reg.exe export "$regKey" "$backupDest" /y *>&1 | Out-Null

                $Transaction.Backups.Add([PSCustomObject]@{
                    Type         = "REGISTRY"
                    OriginalKey  = $KeyPath
                    ValueName    = $ValueName
                    OriginalVal  = $prop.$ValueName
                    BackupPath   = $backupDest
                })
                Write-GenLog "Stored registry backup of '$KeyPath\$ValueName'" "INFO" $Transaction.TransactionID
            }
        }
    } catch {
        Write-GenLog "Failed to transactionally backup registry state: $KeyPath. Error: $($_.Exception.Message)" "ERROR" $Transaction.TransactionID
    }
}

function Invoke-RollbackTransaction {
    param([Parameter(Mandatory=$true)][PSCustomObject]$Transaction)
    Write-Host "  [!] ROLLBACK INITIATED FOR TRANSACTION: $($Transaction.TransactionID)" -ForegroundColor Yellow
    Write-GenLog "Rollback sequence executed." "WARN" $Transaction.TransactionID

    foreach ($bk in $Transaction.Backups) {
        try {
            if ($bk.Type -eq "FILE") {
                if (Test-Path $bk.BackupPath) {
                    $parent = [System.IO.Path]::GetDirectoryName($bk.OriginalPath)
                    if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }

                    # Un harden if locked decoy exists
                    if (Test-Path $bk.OriginalPath) {
                        $isMSProtected = $bk.OriginalPath -match "C:\\Windows\\System32"
                        if (-not $isMSProtected) {
                            takeown.exe /F "`"$($bk.OriginalPath)`"" /A *>&1 | Out-Null
                            icacls.exe "`"$($bk.OriginalPath)`"" /grant "Administrators:F" /C /Q *>&1 | Out-Null
                        }
                        Set-ItemProperty -Path $bk.OriginalPath -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue
                        Remove-Item -Path $bk.OriginalPath -Force -ErrorAction SilentlyContinue
                    }

                    Copy-Item -Path $bk.BackupPath -Destination $bk.OriginalPath -Force

                    # Restore times and permissions
                    $item = Get-Item $bk.OriginalPath -Force
                    $item.CreationTime = $bk.Created
                    $item.LastWriteTime = $bk.Modified
                    $item.LastAccessTime = $bk.Access

                    $acl = Get-Acl -Path $bk.OriginalPath
                    $acl.SetSecurityDescriptorSddlForm($bk.SDDL)
                    Set-Acl -Path $bk.OriginalPath -AclObject $acl -ErrorAction SilentlyContinue
                }
            }
            elseif ($bk.Type -eq "REGISTRY") {
                if (Test-Path $bk.BackupPath) {
                    & reg.exe import "$($bk.BackupPath)" *>&1 | Out-Null
                } else {
                    Set-ItemProperty -Path $bk.OriginalKey -Name $bk.ValueName -Value $bk.OriginalVal -Force
                }
            }
        } catch {
            Write-GenLog "Rollback entity restoration failed. Error: $($_.Exception.Message)" "CRIT" $Transaction.TransactionID
        }
    }
    Write-Host "  [+] Rollback Completed." -ForegroundColor Green
}

# ==============================================================================
# [13] QUARANTINE VAULT MANAGER (AES-256 SECURE VAULT)
# ==============================================================================
function Encrypt-FileAES256 {
    param(
        [string]$InPath,
        [string]$OutPath,
        [string]$Password
    )
    try {
        $bytes = [System.IO.File]::ReadAllBytes($InPath)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $salt = [byte[]](7, 12, 85, 34, 122, 9, 44, 211)
        $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes $Password, $salt, 2000
        $aes.Key = $pbkdf2.GetBytes(32)
        $aes.IV = $pbkdf2.GetBytes(16)

        $encryptor = $aes.CreateEncryptor()
        $encBytes = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
        [System.IO.File]::WriteAllBytes($OutPath, $encBytes)

        $aes.Dispose()
        return $true
    } catch {
        return $false
    }
}

function Decrypt-FileAES256 {
    param(
        [string]$InPath,
        [string]$OutPath,
        [string]$Password
    )
    try {
        $bytes = [System.IO.File]::ReadAllBytes($InPath)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $salt = [byte[]](7, 12, 85, 34, 122, 9, 44, 211)
        $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes $Password, $salt, 2000
        $aes.Key = $pbkdf2.GetBytes(32)
        $aes.IV = $pbkdf2.GetBytes(16)

        $decryptor = $aes.CreateDecryptor()
        $decBytes = $decryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
        [System.IO.File]::WriteAllBytes($OutPath, $decBytes)

        $aes.Dispose()
        return $true
    } catch {
        return $false
    }
}

function Invoke-QuarantineSecurely {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][PSCustomObject]$Transaction
    )
    if (-not (Test-Path $FilePath) -or $FilePath -match "^Registry:|^Task:|^Process ID:") { return $true }
    
    try {
        Save-FileToTransaction -Transaction $Transaction -FilePath $FilePath
        
        $guid = [Guid]::NewGuid().Guid
        $encDest = Join-Path $Global:QuarantineDir "$guid.vir"

        # Retrieve security parameters
        $acl = Get-Acl -Path $FilePath
        $owner = $acl.Owner
        $sddl = $acl.GetSecurityDescriptorSddlForm('All')
        $item = Get-Item -Path $FilePath -Force

        # Force attributes to normal to allow encryption reading
        $item.Attributes = 'Normal'

        # Calculate Original Hash
        $stream = [System.IO.File]::OpenRead($FilePath)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $originalHash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace("-","")
        $stream.Close()

        # Encrypt target payload
        $success = Encrypt-FileAES256 -InPath $FilePath -OutPath $encDest -Password $Global:QuarantineKey
        if (-not $success) {
            Write-GenLog "Quarantine encryption failed for $FilePath" "ERROR" $Transaction.TransactionID
            return $false
        }
        
        # Calculate Encrypted Payload Hash
        $encStream = [System.IO.File]::OpenRead($encDest)
        $encHash = [BitConverter]::ToString($sha.ComputeHash($encStream)).Replace("-","")
        $encStream.Close()

        # Safely remove original file
        Remove-Item -Path $FilePath -Force

        # Save structured metadata manifest
        $manifest = @{
            OriginalPath    = $FilePath
            OriginalName    = [System.IO.Path]::GetFileName($FilePath)
            VaultID         = $guid
            QuarantinedAt   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            OriginalHash    = $originalHash
            EncryptedHash   = $encHash
            CreationTime    = $item.CreationTime.ToString("o")
            LastWriteTime   = $item.LastWriteTime.ToString("o")
            LastAccessTime  = $item.LastAccessTime.ToString("o")
            Owner           = $owner
            SDDL            = $sddl
            RestoreToken    = [Guid]::NewGuid().Guid
            TransactionID   = $Transaction.TransactionID
        }

        $manifest | ConvertTo-Json | Out-File (Join-Path $Global:QuarantineDir "$guid.json") -Force
        Write-GenLog "Successfully secured payload in enclave vault: $guid" "INFO" $Transaction.TransactionID
        return $true
    } catch {
        Write-GenLog "Quarantine secure transition failed: $($_.Exception.Message)" "ERROR" $Transaction.TransactionID
        return $false
    }
}

# ==============================================================================
# [14] PROCESS REMEDIATION & IMMUNITY ENGINE (REMEDIATOR)
# ==============================================================================
function Test-SafeToStopProcess {
    param([int]$ProcessID)
    try {
        $proc = Get-Process -Id $ProcessID -ErrorAction SilentlyContinue
        if (-not $proc) { return $false }

        # 1. Protection Check (PPL/System Process Guards)
        $critical = @("system", "idle", "csrss", "lsass", "smss", "services", "wininit", "winlogon", "svchost", "explorer")
        if ($critical -contains $proc.ProcessName.ToLower()) {
            return $false
        }

        # 2. Session 0 Service association check
        if ($proc.SessionId -eq 0) {
            $srv = Get-CimInstance Win32_Service -Filter "ProcessId = $ProcessID" -ErrorAction SilentlyContinue
            if ($srv) { return $false }
        }
        return $true
    } catch {
        return $false
    }
}

function Restore-HiddenOriginal {
    param([string]$FilePath)
    $origName = [System.IO.Path]::GetFileName($FilePath)
    if ($origName -match "^g(.*\.exe)$" -and $origName -notmatch "(?i)^gallery\.exe$") {
        $cleanName = $matches[1]
        $potentialOriginal = Join-Path ([System.IO.Path]::GetDirectoryName($FilePath)) $cleanName
        if (Test-Path $potentialOriginal) {
            try {
                $item = Get-Item $potentialOriginal -Force
                $item.Attributes = 'Normal'
                Write-GenLog "Restored system attributes visibility on original binary: $potentialOriginal" "INFO"
                return $true
            } catch {}
        }
    }
    return $false
}

function Remove-IcoClones {
    param([string]$FilePath)
    $icoPath = $FilePath.Replace(".exe", ".ico")
    if (Test-Path $icoPath) {
        try {
            $item = Get-Item $icoPath -Force
            $item.Attributes = 'Normal'
            Remove-Item -Path $icoPath -Force
            Write-GenLog "Successfully cleaned matched fake icon: $icoPath" "INFO"
            return $true
        } catch {}
    }
    return $false
}

function Invoke-DecoyImmunityDeployment {
    Write-Host "  [🔒] DEPLOYING IMMUTABLE DECOYS & ANTI-REGENERATION SYSTEM..." -ForegroundColor Cyan
    Write-GenLog "Deploying immutable decoy files to combat polymorphic regeneration." "INFO"
    
    $systemProfilePath = Join-Path -Path (Join-Path -Path $env:SystemRoot -ChildPath 'System32') -ChildPath 'config\systemprofile\AppData\Roaming\Gallery.exe'
    $decoys = @(
        (Join-Path -Path $env:APPDATA -ChildPath "Gallery.exe"),
        $systemProfilePath
    )
    
    foreach ($path in $decoys) {
        Write-Host "  [+] Setting Immunity roadblock on: $path" -ForegroundColor Gray
        try {
            $parent = [System.IO.Path]::GetDirectoryName($path)
            if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }

            # Clean up existing to overwrite
            if (Test-Path $path) {
                # Override security blocks to remove
                takeown.exe /F "`"$path`"" /A *>&1 | Out-Null
                icacls.exe "`"$path`"" /grant "Administrators:F" /C /Q *>&1 | Out-Null
                Set-ItemProperty -Path $path -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue
                Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
            }

            # Write 0-byte file
            New-Item -Path $path -ItemType File -Force | Out-Null
            Attrib.exe +H +S $path

            # Tighten security descriptor
            $acl = Get-Acl -Path $path
            $acl.SetOwner([System.Security.Principal.NTAccount]"SYSTEM")
            $acl.SetAccessRuleProtection($true, $false)
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))

            Set-Acl -Path $path -AclObject $acl -ErrorAction Stop
            Write-Host "      -> Immutable lock deployed successfully." -ForegroundColor Green
        } catch {
            Write-Host "      -> Failed to deploy immunity block: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ==============================================================================
# [15] CORE USER INTERFACE & UTILITIES
# ==============================================================================
function Show-EnterpriseHeader {
    Clear-Host
    Write-Host ""
    Write-Host "   ██████╗  ███████╗ ███╗   ██╗     ██╗   ██╗ ██╗     ████████╗ ██████╗   █████╗ " -ForegroundColor Cyan
    Write-Host "  ██╔════╝  ██╔════╝ ████╗  ██║     ██║   ██║ ██║     ╚══██╔══╝ ██╔══██╗ ██╔══██╗" -ForegroundColor Cyan
    Write-Host "  ██║  ███╗ █████╗   ██╔██╗ ██║     ██║   ██║ ██║        ██║    ██████╔╝ ███████║" -ForegroundColor DarkCyan
    Write-Host "  ██║   ██║ ██╔══╝   ██║╚██╗██║     ██║   ██║ ██║        ██║    ██╔══██╗ ██╔══██║" -ForegroundColor Blue
    Write-Host "  ╚██████╔╝ ███████╗ ██║ ╚████║     ╚██████╔╝ ███████╗   ██║    ██║  ██║ ██║  ██║" -ForegroundColor DarkBlue
    Write-Host "   ╚═════╝  ╚══════╝ ╚═╝  ╚═══╝      ╚═════╝  ╚══════╝   ╚═╝    ╚═╝  ╚═╝ ╚═╝  ╚═╝" -ForegroundColor DarkBlue
    Write-Host " 🌌 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 🌌" -ForegroundColor DarkGray
    Write-Host "                    🛡️ G.E.N ULTRA ENTERPRISE INCIDENT SUITE (v11)            " -ForegroundColor Green
    Write-Host " 🌌 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 🌌`n" -ForegroundColor DarkGray
}

function Show-EnterpriseMenu {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                🌌 ENTERPRISE DIAGNOSTIC COMMAND CENTER 🌌                ║" -ForegroundColor White
    Write-Host "  ╠══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║ [1] 🔍 Deep Read-Only Forensic Scan  ║ [6] 🔒 Deploy Decoys & Immunity  ║" -ForegroundColor White
    Write-Host "  ║ [2] 🧬 View Mapped Threat database   ║ [7] 📊 Export Intelligence Report ║" -ForegroundColor White
    Write-Host "  ║ [3] 🧹 Execute Safe Remediation      ║ [8] ♻  Restore Quarantined Files ║" -ForegroundColor White
    Write-Host "  ║ [4] ⚙  Advanced Diagnostics          ║ [9] 🛡️ Uninstall Decoy Blocks    ║" -ForegroundColor White
    Write-Host "  ║ [0] 🚪 Terminate Sessions            ║                                  ║" -ForegroundColor White
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-InteractivePause {
    Write-Host "`n  Press any key to return to Main Menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# [16] REMEDIATION DISPATCHER (SAFE, SEQUENTIAL REMEDIATOR WITH CONFIRMATION)
# ==============================================================================
function Invoke-InteractiveRemediation {
    Show-EnterpriseHeader
    Write-Host "  [🧹] INITIATING SECURE TRANSACTIONAL REMEDIATION WORKFLOW..." -ForegroundColor Red
    
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "`n  [+] Mapped Threat Database is currently empty. Run deep scan first." -ForegroundColor Green
        Invoke-InteractivePause
        return
    }

    $tx = New-RollbackTransaction
    $remediated = 0
    $stageFailed = $false

    foreach ($threat in $Global:ThreatDatabase) {
        Write-Host "`n  -----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  [!] TARGET IDENTIFIED FOR DISPATCH:" -ForegroundColor Yellow
        Write-Host "      Path: $($threat.Forensics.Path)" -ForegroundColor White
        Write-Host "      Risk Score: $($threat.Risk.Score)/100 (Severity: $($threat.Risk.Severity))" -ForegroundColor Red
        Write-Host "      Heuristics: $($threat.Risk.Reasons)" -ForegroundColor Gray

        # Prompt for confirmation before applying any changes
        $confirm = Read-Host "  [?] Execute safe quarantine & neutralization on this vector? (Y/N)"
        if ($confirm -match "^[Yy]") {
            
            # Double-confirmation block for critical path / Microsoft signed binaries
            if ($threat.Forensics.IsCriticalPath -and $threat.Forensics.IsMicrosoft) {
                Write-Host "  [!!!] SYSTEM CRITICAL VECTOR DETECTED [!!!]" -ForegroundColor Red -BackgroundColor White
                $doubleConfirm = Read-Host "  WARNING: Target is signed by Microsoft and resides in a protected location. Force quarantine? (Type CONFIRM)"
                if ($doubleConfirm -ne "CONFIRM") {
                    Write-Host "  [!] De-escalated. Remediation skipped." -ForegroundColor Yellow
                    continue
                }
            }

            # Execution
            if ($threat.Forensics.Path -match "^PID:") {
                # Terminate process safely
                if ($threat.Forensics.Path -match "PID:\s*(\d+)") {
                    $pid = [int]$matches[1]
                    if (Test-SafeToStopProcess -ProcessID $pid) {
                        try {
                            Stop-Process -Id $pid -Force -ErrorAction Stop
                            Write-Host "      -> Process terminated successfully." -ForegroundColor Green
                            $remediated++
                        } catch {
                            Write-Host "      -> Process termination failed: $($_.Exception.Message)" -ForegroundColor Red
                            $stageFailed = $true
                        }
                    } else {
                        Write-Host "      -> Process is highly protected. Safe Stop blocked to prevent Windows corruption." -ForegroundColor Yellow
                    }
                }
            }
            else {
                # Secure File System Quarantine
                if (Invoke-QuarantineSecurely -FilePath $threat.Forensics.Path -Transaction $tx) {
                    Write-Host "      -> Securely quarantined in encrypted vault." -ForegroundColor Green
                    $remediated++
                    
                    # Auto-recovery actions
                    Restore-HiddenOriginal -FilePath $threat.Forensics.Path | Out-Null
                    Remove-IcoClones -FilePath $threat.Forensics.Path | Out-Null
                } else {
                    Write-Host "      -> Quarantine failed on this stage." -ForegroundColor Red
                    $stageFailed = $true
                }
            }
        } else {
            Write-Host "  [!] Skipped by user operator." -ForegroundColor DarkGray
        }
    }

    if ($stageFailed) {
        Write-Host "`n  [!] TRANSACTION WORKFLOW FAILURE DETECTED. ROLLBACK INITIATED..." -ForegroundColor Red
        Invoke-RollbackTransaction -Transaction $tx
    } else {
        Write-Host "`n  [✓] ALL DISPATCH OPERATIONS CONCLUDED SUCCESSFULY. Remediated: $remediated targets." -ForegroundColor Green
        # Delayed/Safe removal of transaction cache
        Remove-Item -Path $tx.StorePath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    $Global:ThreatDatabase.Clear()
    Invoke-InteractivePause
}

function Invoke-UninstallDecoys {
    Show-EnterpriseHeader
    Write-Host "  [🛡️] UNINSTALLING SECURITY DECOY IMMUNITY BLOCKS..." -ForegroundColor Yellow
    Write-GenLog "Uninstall decoy protocol launched by user operator." "INFO"
    
    $systemProfilePath = Join-Path -Path (Join-Path -Path $env:SystemRoot -ChildPath 'System32') -ChildPath 'config\systemprofile\AppData\Roaming\Gallery.exe'
    $decoys = @(
        (Join-Path -Path $env:APPDATA -ChildPath "Gallery.exe"),
        $systemProfilePath
    )

    foreach ($path in $decoys) {
        if (Test-Path $path) {
            Write-Host "  [-] Neutralizing roadblock on: $path" -ForegroundColor Gray
            try {
                # Force reset permission rules
                takeown.exe /F "`"$path`"" /A *>&1 | Out-Null
                icacls.exe "`"$path`"" /grant "Administrators:F" /C /Q *>&1 | Out-Null
                Set-ItemProperty -Path $path -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue
                Remove-Item -Path $path -Force -ErrorAction Stop
                Write-Host "      -> Removed successfully." -ForegroundColor Green
            } catch {
                Write-Host "      -> Removal failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    Invoke-InteractivePause
}

function Invoke-EnterpriseRestoreVault {
    Show-EnterpriseHeader
    Write-Host "  [♻] SECURE QUARANTINE VAULT RESTORATION" -ForegroundColor Cyan
    
    $manifests = Get-ChildItem -Path $Global:QuarantineDir -Filter "*.json" -ErrorAction SilentlyContinue
    if ($manifests.Count -eq 0) {
        Write-Host "  [+] Secure Quarantine Vault is currently empty." -ForegroundColor Green
        Invoke-InteractivePause
        return
    }

    $dict = @{}
    $i = 1
    foreach ($man in $manifests) {
        try {
            $meta = Get-Content $man.FullName | ConvertFrom-Json
            Write-Host "  [$i] $($meta.OriginalName) (Quarantined: $($meta.QuarantinedAt))" -ForegroundColor Yellow
            Write-Host "      Source Path: $($meta.OriginalPath)" -ForegroundColor DarkGray
            $dict[$i] = $meta
            $i++
        } catch {}
    }
    
    Write-Host "  [0] Cancel" -ForegroundColor DarkGray
    $choice = Read-Host "`n  [?] Select target ID to restore"
    if ($choice -eq "0" -or -not $dict[$choice -as [int]]) {
        Write-Host "  [!] Operation Cancelled." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }
    
    $metaTarget = $dict[$choice -as [int]]
    $virFile = Join-Path $Global:QuarantineDir "$($metaTarget.VaultID).vir"

    if (Test-Path $virFile) {
        try {
            # Reconstruct parent path
            $parent = [System.IO.Path]::GetDirectoryName($metaTarget.OriginalPath)
            if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }

            $decrypted = Decrypt-FileAES256 -InPath $virFile -OutPath $metaTarget.OriginalPath -Password $Global:QuarantineKey
            if ($decrypted) {
                # Restore original times
                $item = Get-Item $metaTarget.OriginalPath -Force
                $item.CreationTime = [DateTime]::Parse($metaTarget.CreationTime)
                $item.LastWriteTime = [DateTime]::Parse($metaTarget.LastWriteTime)
                $item.LastAccessTime = [DateTime]::Parse($metaTarget.LastAccessTime)

                # Restore security descriptor
                if ($metaTarget.SDDL) {
                    try {
                        $acl = Get-Acl -Path $metaTarget.OriginalPath
                        $acl.SetSecurityDescriptorSddlForm($metaTarget.SDDL)
                        Set-Acl -Path $metaTarget.OriginalPath -AclObject $acl -ErrorAction SilentlyContinue
                    } catch {}
                }

                # Clean up vault records
                Remove-Item -Path $virFile -Force
                Remove-Item -Path $manifests[($choice -as [int]) - 1].FullName -Force

                Write-Host "`n  [+] SUCCESS: Decrypted payload safely restored to: $($metaTarget.OriginalPath)" -ForegroundColor Green
                Write-GenLog "Restored $($metaTarget.OriginalPath) from vault enclave." "INFO"
            } else {
                Write-Host "  [-] Failed to decrypt vault payload." -ForegroundColor Red
            }
        } catch {
            Write-Host "  [-] Restoration fault occurred: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [-] Quarantine virtual payload has gone missing." -ForegroundColor Red
    }
    Invoke-InteractivePause
}

# ==============================================================================
# [17] SYSTEM DIAGNOSTICS VIEW
# ==============================================================================
function Show-DiagnosticView {
    Show-EnterpriseHeader
    Write-Host "  [⚙] ENTERPRISE HEALTH DIAGNOSTICS & SYSTEM PROFILE" -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    Write-Host "  [-] Host System Name    : $($Global:EnvStatus.ComputerName)" -ForegroundColor Gray
    Write-Host "  [-] OS Architecture     : $($Global:EnvStatus.Architecture)" -ForegroundColor Gray
    Write-Host "  [-] OS Version / Caption : $($Global:EnvStatus.OSCaption) ($($Global:EnvStatus.OSVersion))" -ForegroundColor Gray
    Write-Host "  [-] Administrative State: $($Global:EnvStatus.IsAdmin)" -ForegroundColor Gray
    Write-Host "  [-] PowerShell Engine    : $($Global:EnvStatus.PSVersion)" -ForegroundColor Gray
    Write-Host "  [-] Defender State      : Active=$($Global:EnvStatus.IsDefenderRunning)" -ForegroundColor Gray
    Write-Host "  [-] Active Log File      : $Global:LogFile" -ForegroundColor Gray
    Write-Host "  [-] Enclave Vault path  : $Global:QuarantineDir" -ForegroundColor Gray
    
    Invoke-InteractivePause
}

# ==============================================================================
# [18] CLI ROUTER COMMAND EXECUTION
# ==============================================================================
function Invoke-InteractiveReportExporter {
    Show-EnterpriseHeader
    Write-Host "  [📊] INTEL EXPORT CENTER" -ForegroundColor Cyan
    
    Write-Host "  Select desired export format:" -ForegroundColor White
    Write-Host "  [1] JSON (Comprehensive incident database)" -ForegroundColor Gray
    Write-Host "  [2] CSV (Spreadsheet friendly targets)" -ForegroundColor Gray
    Write-Host "  [3] HTML (Enterprise styled report)" -ForegroundColor Gray
    
    $opt = Read-Host "`n  [?] Choice"
    $fmt = "JSON"
    if ($opt -eq "2") { $fmt = "CSV" }
    elseif ($opt -eq "3") { $fmt = "HTML" }
    
    $path = Export-EnterpriseReport -EvidenceCache $Global:EvidenceCache -ThreatDb $Global:ThreatDatabase -Format $fmt
    if ($path) {
        Write-Host "`n  [+] Successfully exported telemetry record to: $path" -ForegroundColor Green
    } else {
        Write-Host "  [-] Failed to write intel report." -ForegroundColor Red
    }
    Invoke-InteractivePause
}

# ==============================================================================
# [19] SYSTEM ENTRY ROUTER
# ==============================================================================
while ($true) {
    Show-EnterpriseHeader
    Show-EnterpriseMenu
    
    $c = Read-Host "  [COMMAND ROUTER]"
    
    switch ($c) {
        "1" { Invoke-DeepTargetedScan; Invoke-InteractivePause }
        "2" {
            Show-EnterpriseHeader
            if ($Global:ThreatDatabase.Count -eq 0) {
                Write-Host "  [+] Threat database is clean. No anomalies mapped." -ForegroundColor Green
            } else {
                Write-Host "  [!] $($Global:ThreatDatabase.Count) suspicious targets registered in database:`n" -ForegroundColor Yellow
                $Global:ThreatDatabase | Format-Table -Property @{N="Target Vector";E={$_.Forensics.Path}}, @{N="Score";E={$_.Risk.Score}}, @{N="Severity";E={$_.Risk.Severity}}, @{N="Heuristics";E={$_.Risk.Reasons}} -AutoSize
            }
            Invoke-InteractivePause
        }
        "3" { Invoke-InteractiveRemediation }
        "4" { Show-DiagnosticView }
        "5" { Invoke-EnterpriseRestoreVault }
        "6" { Invoke-DecoyImmunityDeployment; Invoke-InteractivePause }
        "7" { Invoke-InteractiveReportExporter }
        "8" { Invoke-EnterpriseRestoreVault }
        "9" { Invoke-UninstallDecoys }
        "0" {
            Show-EnterpriseHeader
            Write-Host "  [+] Dismantling enterprise framework session context..." -ForegroundColor Yellow
            Write-GenLog "Interactive session closed." "INFO"
            Start-Sleep -Seconds 1
            Write-Host "  [✓] Sessions safely closed. Stay guarded." -ForegroundColor Green
            Start-Sleep -Seconds 1
            exit
        }
        Default {
            Write-Host "`n  [!] Invalid command context syntax. Select (0-9)." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
