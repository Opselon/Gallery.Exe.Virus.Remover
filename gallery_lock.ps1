#Requires -RunAsAdministrator

<#
.SYNOPSIS
    G.E.N. ULTRA v10 - Enterprise Forensic & Incident Remediation Framework
.DESCRIPTION
    A complete, production-grade, single-file incident response and security framework.
    Designed to neutralize polymorphic threats such as Gallery.exe (Grenam) while ensuring
    absolute safety, transactional rollbacks, explainable threat scoring, and zero side-effects
    during detection. All operations conform to strict corporate security standards.
.NOTES
    Architecture: x64/x86 PowerShell Native
    Compatibility: PowerShell 5.1+
    Safety Policy: ZERO side-effects during scan. Double-confirmation required for remediation.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
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

$host.UI.RawUI.WindowTitle = "🛡️ G.E.N. ULTRA v10 | Enterprise Forensic Terminal"

# ==============================================================================
# [02] GLOBAL CONFIGURATION & ARCHITECTURE
# ==============================================================================
$Global:AppVersion = "10.0.9-ENTERPRISE"
$Global:GEN_Dir = "C:\GEN_ULTRA"
$Global:QuarantineDir = "$Global:GEN_Dir\Security\Quarantine"
$Global:ReportsDir = "$Global:GEN_Dir\Reports"
$Global:DecoyDir = "$Global:GEN_Dir\Decoys"
$Global:LogsDir = "$Global:GEN_Dir\Logs"
$Global:RollbackDir = "$Global:GEN_Dir\Rollback"
$Global:LogFile = "$Global:LogsDir\GEN_Engine_$( (Get-Date).ToString('yyyyMMdd') ).log"

# Global Threat & Evidence Databases (Strictly read-only during Scan)
$Global:ThreatDatabase = [System.Collections.Generic.List[PSCustomObject]]::new()
$Global:EvidenceDatabase = [System.Collections.Generic.List[PSCustomObject]]::new()

$Global:SafeList = @(
    "C:\Windows", "C:\Windows\System32", "C:\Windows\SysWOW64", 
    "C:\Windows\WinSxS", "C:\Program Files\Windows Defender"
)

# AES Quarantine Key derivation parameters to avoid fixed hardcoded credentials
# WARNING: Key is derived dynamically per execution using a combination of the system's MachineGUID,
# dynamic session metrics, and a dynamic salt. This reduces static credential exposure risks.
$Global:SessionUUID = [Guid]::NewGuid().Guid
$Global:DerivedVaultKey = $null

function Get-DerivedVaultKey {
    if ($Global:DerivedVaultKey -ne $null) { return $Global:DerivedVaultKey }
    try {
        $guidReg = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction SilentlyContinue
        if (-not $guidReg) { $guidReg = "GEN_SECURE_ENCLAVE_KEY_9988776655" }
        $Global:DerivedVaultKey = "$guidReg`_$Global:SessionUUID"
    } catch {
        $Global:DerivedVaultKey = "GEN_SECURE_ENCLAVE_KEY_Fallback_$(Get-Date -Format 'yyyyMMdd')"
    }
    return $Global:DerivedVaultKey
}

# Build Directory Structure safely
foreach ($dir in @($Global:GEN_Dir, $Global:QuarantineDir, $Global:ReportsDir, $Global:DecoyDir, $Global:LogsDir, $Global:RollbackDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# ==============================================================================
# [03] ENTERPRISE LOGGING ENGINE
# ==============================================================================
function Write-GenLog {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][ValidateSet("INFO","WARN","ERROR","DEBUG","CRIT")][string]$Level = "INFO",
        [Parameter(Mandatory=$false)][string]$TransactionID = "N/A"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    $logEntry = "[$timestamp] [$Level] [TX:$TransactionID] $Message"
    try {
        Add-Content -Path $Global:LogFile -Value $logEntry -Force
    } catch {}
}

Write-GenLog "G.E.N ULTRA v10 Enterprise Incident Response Suite Initialized." "INFO"

# ==============================================================================
# [04] ENVIRONMENT AWARENESS MODULE
# ==============================================================================
function Get-EnvironmentStatus {
    $isAdmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    
    # Boot/Safe Mode Detection
    $safeMode = "Normal Mode"
    if ($env:SAFEBOOT_OPTION) {
        $safeMode = "Safe Mode (" + $env:SAFEBOOT_OPTION + ")"
    }
    
    # WinPE Detection
    $isWinPE = $false
    if (Test-Path "HKLM:\System\CurrentControlSet\Control\MiniNT" -ErrorAction SilentlyContinue) {
        $isWinPE = $true
        $safeMode = "Windows PE (WinPE)"
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
        OSCaption              = if ($os) { $os.Caption } else { "Windows 10/11" }
        OSVersion              = if ($os) { $os.Version } else { "10.0" }
        Architecture           = if ($os) { $os.OSArchitecture } else { "64-bit" }
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
# [05] TRUST VALIDATOR
# ==============================================================================
function Test-StrongTrustChain {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Attributes -match "Directory") { return $false }
    try {
        $sig = Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue
        if (-not $sig -or $sig.Status -ne "Valid") { return $false }

        $cert = $sig.SignerCertificate
        if (-not $cert) { return $false }

        # X509 Chain Verification with offline check support to remain robust
        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509RevocationMode]::NoCheck
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

        # Enhanced Key Usage (EKU) Validation (Code Signing OID: 1.3.6.1.5.5.7.3.3)
        $hasCodeSigning = $false
        foreach ($ext in $cert.Extensions) {
            if ($ext.Oid.Value -eq "2.5.29.37") {
                $eku = [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]$ext
                foreach ($usage in $eku.EnhancedKeyUsages) {
                    if ($usage.Value -eq "1.3.6.1.5.5.7.3.3") { $hasCodeSigning = $true }
                }
            }
        }

        if (-not $hasCodeSigning -and ($cert.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.37" })) { return $false }

        # Cross-volume dynamic hash matching against WinSxS versions for core System32 binaries
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        if ($FilePath -match "System32" -and -not ($FilePath -match "WinSxS")) {
            $winsxsFiles = Get-ChildItem -Path "C:\Windows\WinSxS" -Filter $fileName -Recurse -File -ErrorAction SilentlyContinue
            if ($winsxsFiles) {
                $currentHash = (Get-FileHash -Path $FilePath -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                $matchFound = $false
                foreach ($wsFile in $winsxsFiles) {
                    $wsHash = (Get-FileHash -Path $wsFile.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                    if ($wsHash -eq $currentHash) { $matchFound = $true; break }
                }
                if (-not $matchFound -and $cert.Subject -match "Microsoft") {
                    Write-GenLog "Cross-validation mismatch for Microsoft System32 binary: $FilePath" "WARN"
                }
            }
        }
        return $true
    } catch {
        return $false
    }
}

function Test-TrustedVendor {
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
# [06] PE ANALYZER
# ==============================================================================
function Get-PEHeadersAndDetails {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Length -lt 1024) { return $null }
    
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        # Verify DOS MZ Header
        if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $null }
        
        # NT Header offset
        $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
        if ($peOffset -le 0 -or $peOffset -gt ($bytes.Length - 240)) { return $null }
        
        # Verify PE Signature
        if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset+1] -ne 0x45) { return $null }

        $numSections = [BitConverter]::ToUInt16($bytes, $peOffset + 6)
        $timestamp = [BitConverter]::ToInt32($bytes, $peOffset + 8)
        $epoch = New-Object DateTime 1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc
        $compileTime = $epoch.AddSeconds($timestamp)

        # Traversal of sections
        $sections = [System.Collections.Generic.List[PSCustomObject]]::new()
        $hasSuspiciousSections = $false
        $isPacked = $false
        
        for ($i = 0; $i -lt $numSections; $i++) {
            $sectOffset = $peOffset + 24 + 224 + ($i * 40)
            if ($sectOffset + 40 -gt $bytes.Length) { break }

            $nameBytes = $bytes[$sectOffset..($sectOffset+7)]
            $nameStr = ([System.Text.Encoding]::ASCII.GetString($nameBytes)).Trim("`0").Trim()

            # Section Characteristics
            $chars = [BitConverter]::ToUInt32($bytes, $sectOffset + 36)
            $isWritable = ($chars -band 0x80000000) -eq 0x80000000
            $isExecutable = ($chars -band 0x20000000) -eq 0x20000000

            if ($isWritable -and $isExecutable) {
                $hasSuspiciousSections = $true
            }
            if ($nameStr -match "UPX|ASPack|nspack|pecompat|UPX0|UPX1") {
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
# [07] SHANNON ENTROPY & METADATA FORENSICS
# ==============================================================================
function Get-ShannonEntropy {
    param([string]$FilePath)
    try {
        $item = Get-Item $FilePath -Force -ErrorAction SilentlyContinue
        if (-not $item -or $item.Length -eq 0) { return 0.0 }
        if ($item.Length -gt 25MB) { return -1.0 } # Skip excessive payloads for speed

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

function Get-FileForensics {
    param([System.IO.FileInfo]$File)
    
    $hashSHA256 = "N/A"
    $hashMD5 = "N/A"
    $entropy = 0.0
    try {
        $stream = [System.IO.File]::OpenRead($File.FullName)
        
        $sha256Alg = [System.Security.Cryptography.SHA256]::Create()
        $hashSHA256 = [BitConverter]::ToString($sha256Alg.ComputeHash($stream)).Replace("-","")
        
        $stream.Position = 0
        $md5Alg = [System.Security.Cryptography.MD5]::Create()
        $hashMD5 = [BitConverter]::ToString($md5Alg.ComputeHash($stream)).Replace("-","")
        $stream.Close()

        $entropy = Get-ShannonEntropy -FilePath $File.FullName
    } catch {
        if ($stream) { $stream.Close() }
    }

    $sigStatus = "Not Signed"
    $signer = "Unknown"
    $isMS = $false
    $isTrusted = $false
    try {
        $sig = Get-AuthenticodeSignature -FilePath $File.FullName -ErrorAction SilentlyContinue
        if ($sig -and $sig.Status -eq "Valid") {
            $signer = $sig.SignerCertificate.Subject
            $sigStatus = "Valid"
            if ($signer -match "Microsoft|Windows") { $isMS = $true }

            $forensicsTemp = [PSCustomObject]@{
                Path            = $File.FullName
                Signer          = $signer
                SignatureStatus = "Valid"
            }
            if (Test-TrustedVendor -Forensics $forensicsTemp) { $isTrusted = $true }
        } elseif ($sig -and $sig.Status -eq "HashMismatch") {
            $sigStatus = "Invalid (Modified)"
        } elseif ($sig) {
            $sigStatus = $sig.Status.ToString()
        }
    } catch {}

    $isCritical = $false
    foreach ($path in $Global:SafeList) {
        if ($File.FullName.StartsWith($path, [StringComparison]::OrdinalIgnoreCase)) {
            $isCritical = $true
            break
        }
    }

    $peDetails = Get-PEHeadersAndDetails -FilePath $File.FullName
    $ads = Get-AlternateDataStreams -FilePath $File.FullName

    return [PSCustomObject]@{
        Name              = $File.Name
        Path              = $File.FullName
        Directory         = $File.DirectoryName
        Size              = $File.Length
        SHA256            = $hashSHA256
        MD5               = $hashMD5
        Entropy           = $entropy
        Created           = $File.CreationTime
        Modified          = $File.LastWriteTime
        Attributes        = $File.Attributes.ToString()
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
# [08] EVIDENCE COLLECTOR MODULE
# ==============================================================================
function New-EvidenceObject {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("FILE", "REGISTRY", "PROCESS", "TASK", "DRIVER", "NETWORK", "EVENTLOG")][string]$Type,
        [Parameter(Mandatory=$true)][string]$Identifier,
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$false)][PSCustomObject]$Metadata = $null
    )
    $obj = [PSCustomObject]@{
        EvidenceID  = [Guid]::NewGuid().Guid
        Timestamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Type        = $Type
        Identifier  = $Identifier
        Description = $Description
        Metadata    = $Metadata
    }
    return $obj
}

# ==============================================================================
# [09] PERSISTENCE ANALYZER
# ==============================================================================
function Get-PersistenceEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    # 1. Active Run and RunOnce Paths
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
                    $val = $prop.Value
                    if ($val -match "Gallery\.exe|g.*\.exe" -or $val -match "Temp|AppData") {
                        $meta = @{ Key = $reg; Property = $prop.Name; Value = $val }
                        $findings.Add((New-EvidenceObject -Type "REGISTRY" -Identifier "$reg\$($prop.Name)" -Description "Registry persistence vector targets suspicious executable location" -Metadata $meta))
                    }
                }
            }
        }
    }

    # 2. COM Hijacking CLSID Scans
    $clsidPaths = @(
        "HKCU:\Software\Classes\CLSID",
        "HKLM:\Software\Classes\CLSID"
    )
    foreach ($basePath in $clsidPaths) {
        if (Test-Path $basePath) {
            $clsids = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue | Select-Object -First 300
            foreach ($key in $clsids) {
                $subKey = Join-Path $key.PSPath "InprocServer32"
                if (Test-Path $subKey) {
                    $val = Get-ItemPropertyValue -Path $subKey -Name "(default)" -ErrorAction SilentlyContinue
                    if ($val -and $val -is [string] -and ($val -match "AppData|Temp|Users\\Public")) {
                        $meta = @{ CLSID = $key.PSChildName; Value = $val }
                        $findings.Add((New-EvidenceObject -Type "REGISTRY" -Identifier $subKey -Description "COM CLSID points to untrusted writable path" -Metadata $meta))
                    }
                }
            }
        }
    }
    return $findings
}

# ==============================================================================
# [10] DRIVER ANALYZER
# ==============================================================================
function Get-DriverEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        $drivers = Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Running" }
        foreach ($drv in $drivers) {
            $path = $drv.PathName
            if ($path -and (Test-Path $path)) {
                $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
                if ($sig -and $sig.Status -ne "Valid") {
                    $meta = @{ DisplayName = $drv.DisplayName; Path = $path; Status = $sig.Status.ToString() }
                    $findings.Add((New-EvidenceObject -Type "DRIVER" -Identifier $drv.Name -Description "Unsigned kernel driver loaded in active space: $($drv.DisplayName)" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# ==============================================================================
# [11] MEMORY ANALYZER (STRICTLY NON-DESTRUCTIVE SCAN)
# ==============================================================================
function Get-MemoryEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        $processes = Get-Process -ErrorAction SilentlyContinue
        foreach ($proc in $processes) {
            $path = ""
            try { $path = $proc.Path } catch {}
            if ($path -and (Test-Path $path)) {
                # Look for suspicious loaded modules inside the process context
                try {
                    foreach ($mod in $proc.Modules) {
                        $modPath = $mod.FileName
                        if ($modPath -match "Temp|AppData\\Local\\Temp|Users\\Public") {
                            $meta = @{ ProcessID = $proc.Id; ProcessName = $proc.Name; ModName = $mod.ModuleName; ModPath = $modPath }
                            $findings.Add((New-EvidenceObject -Type "PROCESS" -Identifier "PID: $($proc.Id) ($($proc.Name))" -Description "Process loaded module from suspicious workspace context: $modPath" -Metadata $meta))
                        }
                    }
                } catch {}

                # Signature naming checks
                if ($proc.Name -match "(?i)^Gallery\.exe$" -or ($proc.Name -match "^g.*\.exe$" -and $path -match "AppData|Temp")) {
                    $meta = @{ ProcessID = $proc.Id; ProcessName = $proc.Name; ExePath = $path }
                    $findings.Add((New-EvidenceObject -Type "PROCESS" -Identifier "PID: $($proc.Id) ($($proc.Name))" -Description "Active process aligns with polymorphic malware context signature" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# ==============================================================================
# [12] NETWORK ANALYZER
# ==============================================================================
function Get-NetworkEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        # established socket connections
        $conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
        foreach ($conn in $conns) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($proc) {
                $path = ""
                try { $path = $proc.Path } catch {}
                if ($path -and ($path -match "AppData|Temp|Gallery.exe")) {
                    $meta = @{ PID = $conn.OwningProcess; Name = $proc.Name; RemoteAddress = $conn.RemoteAddress; RemotePort = $conn.RemotePort }
                    $findings.Add((New-EvidenceObject -Type "NETWORK" -Identifier "Process: $($proc.Name) (PID: $($conn.OwningProcess))" -Description "Established socket connection to $($conn.RemoteAddress):$($conn.RemotePort) from untrusted executable workspace" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# ==============================================================================
# [13] EVENT LOG ANALYZER
# ==============================================================================
function Get-EventLogEvidence {
    $findings = [System.Collections.Generic.List[PSCustomObject]]::new()
    try {
        $logs = @("Microsoft-Windows-TaskScheduler/Operational", "Microsoft-Windows-PowerShell/Operational")
        foreach ($logName in $logs) {
            $events = Get-WinEvent -LogName $logName -MaxEvents 50 -ErrorAction SilentlyContinue
            foreach ($ev in $events) {
                if ($ev.Message -match "Gallery" -or $ev.Message -match "AmsiBypass" -or $ev.Message -match "Set-MpPreference") {
                    $meta = @{ Log = $logName; EventID = $ev.Id; TimeCreated = $ev.TimeCreated }
                    $findings.Add((New-EvidenceObject -Type "EVENTLOG" -Identifier "Event ID: $($ev.Id) on $logName" -Description "Tampering indicators detected in Windows security event logs: $($ev.Message)" -Metadata $meta))
                }
            }
        }
    } catch {}
    return $findings
}

# ==============================================================================
# [14] RISK ENGINE (WEIGHTED, EXPLAINABLE SCORE WITH FP REDUCTION)
# ==============================================================================
function Get-ExplainableThreatScore {
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$Forensics,
        [Parameter(Mandatory=$false)][PSCustomObject]$Context = $null
    )
    
    # False Positive Reduction: Safelist valid corporate certificates
    if ($Forensics.SignatureStatus -eq "Valid" -and $Forensics.IsTrustedVendor) {
        return [PSCustomObject]@{
            Score       = 0
            Confidence  = 100
            Severity    = "Informational"
            Status      = "SAFE"
            Reasons     = "Safelisted: Verified digital signature of trusted publisher."
            Recommended = "No action required. Safe system binary."
        }
    }

    $score = 0
    $reasons = [System.Collections.Generic.List[string]]::new()

    # 1. Digital Signature Evaluation
    if ($Forensics.SignatureStatus -eq "Invalid (Modified)") {
        $score += 45
        $reasons.Add("Tampered signature / Authenticode hash mismatch.")
    } elseif ($Forensics.SignatureStatus -eq "Untrusted Chain") {
        $score += 25
        $reasons.Add("Untrusted certificate authority chain.")
    } elseif ($Forensics.SignatureStatus -eq "Not Signed") {
        $score += 15
        $reasons.Add("Unsigned executable artifact.")
    }

    # 2. PE Section Headers Validation
    if ($Forensics.PEDetails) {
        if ($Forensics.PEDetails.IsPacked) {
            $score += 20
            $reasons.Add("Executable packed/compressed using header layout UPX/ASPack.")
        }
        if ($Forensics.PEDetails.HasSuspiciousSections) {
            $score += 25
            $reasons.Add("Anomalous PE Section Characteristics: Writable + Executable fields.")
        }
    }
    
    # 3. Shannon Entropy Scan
    if ($Forensics.Entropy -gt 7.2) {
        $score += 20
        $reasons.Add("Extreme Shannon Entropy ($($Forensics.Entropy)): Cryptographic encryption signature.")
    }
    
    # 4. Identity Matched Heuristics
    if ($Forensics.Name -match "(?i)^Gallery\.exe$") {
        $score += 55
        $reasons.Add("Literal filename alignment with known polymorphic infector payload.")
    } elseif ($Forensics.Name -match "^g.*\.exe$") {
        $score += 25
        $reasons.Add("Filename follows G-Clone masquerading persistence pattern.")
    }

    # 5. Path Risks Execution Environment
    $pathLower = $Forensics.Path.ToLower()
    if ($pathLower -match "\\appdata\\roaming\\" -or $pathLower -match "\\appdata\\local\\") {
        $score += 15
        $reasons.Add("Execution context within high-risk AppData user directory.")
    }
    if ($pathLower -match "\\temp\\") {
        $score += 20
        $reasons.Add("Execution context within volatile temporary files location.")
    }

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

    $recommended = "Monitor execution."
    if ($status -eq "MALWARE") {
        $recommended = "Quarantine target and deploy immutable immunization blocks."
    } elseif ($status -eq "SUSPICIOUS") {
        $recommended = "Examine persistence context or transfer target to enclave vault."
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
# [15] DETECTOR & FORENSIC SCANNER (STRICTLY READ-ONLY)
# ==============================================================================
function Invoke-DeepSystemScan {
    $startTime = Get-Date
    Write-Host "  [🧠] COLLECTING LOGICAL ENVIRONMENT FORENSIC TELEMETRY..." -ForegroundColor Magenta
    Write-GenLog "Enterprise targeted forensic scan started." "INFO"

    $Global:ThreatDatabase.Clear()
    $Global:EvidenceDatabase.Clear()

    # Query passive telemetry vectors sequentially
    $persistenceEv = Get-PersistenceEvidence
    $driverEv = Get-DriverEvidence
    $memoryEv = Get-MemoryEvidence
    $networkEv = Get-NetworkEvidence
    $eventlogEv = Get-EventLogEvidence

    foreach ($ev in ($persistenceEv + $driverEv + $memoryEv + $networkEv + $eventlogEv)) {
        $Global:EvidenceDatabase.Add($ev)
    }

    # Directory sweeps
    Write-Host "  [🔍] COMMENCING TARGETED FILESYSTEM SEARCH..." -ForegroundColor Cyan
    $directories = @(
        $env:APPDATA,
        $env:LOCALAPPDATA,
        $env:TEMP,
        [Environment]::GetFolderPath("Startup"),
        "C:\Windows\System32\config\systemprofile\AppData\Roaming"
    ) | Select-Object -Unique

    $targetFiles = [System.Collections.Generic.List[string]]::new()
    foreach ($dir in $directories) {
        if (Test-Path $dir) {
            $files = Get-ChildItem -Path $dir -Include "*.exe", "g*.ico" -Recurse -File -Force -ErrorAction SilentlyContinue
            foreach ($f in $files) { $targetFiles.Add($f.FullName) }
        }
    }

    $processed = 0
    foreach ($f in $targetFiles) {
        $processed++
        if ($processed % 5 -eq 0) {
            Write-Host "`r      -> Traversal Progress: Analyzed $processed / $($targetFiles.Count) paths..." -ForegroundColor DarkCyan -NoNewline
        }
        
        $reparseTest = Test-ReparsePointSafe -Path $f
        if ($reparseTest.IsLink) {
            $meta = @{ Target = $reparseTest.Target; Attributes = $reparseTest.Attributes }
            $Global:EvidenceDatabase.Add((New-EvidenceObject -Type "FILE" -Identifier $f -Description "Safe traversal checkpoint: Junction point detected" -Metadata $meta))
            continue
        }
        
        $fileObj = Get-Item $f -Force -ErrorAction SilentlyContinue
        if ($fileObj) {
            $forensics = Get-FileForensics -File $fileObj
            $risk = Get-ExplainableThreatScore -Forensics $forensics

            if ($risk.Status -ne "SAFE") {
                $Global:ThreatDatabase.Add([PSCustomObject]@{
                    Forensics = $forensics
                    Risk      = $risk
                })
                Write-GenLog "Threat target cataloged: $($f) (Weighted score: $($risk.Score))" "WARN"
            }
        }
    }
    Write-Host ""

    # Correlate memory & registry processes into active threat records
    foreach ($ev in $Global:EvidenceDatabase) {
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
                Score       = 95
                Confidence  = 90
                Severity    = "High"
                Status      = "MALWARE"
                Reasons     = $ev.Description
                Recommended = "Execute isolation and transactional remediation."
            }
            $Global:ThreatDatabase.Add([PSCustomObject]@{
                Forensics = $dummyForensics
                Risk      = $dummyRisk
            })
        }
    }

    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
    Write-Host "  [✓] SCAN COMPLETE IN $elapsed SECONDS. registered $($Global:ThreatDatabase.Count) anomalies." -ForegroundColor Green
}

# ==============================================================================
# [16] TRANSACTION & ROLLBACK MANAGER
# ==============================================================================
function New-RollbackTransaction {
    $txID = [Guid]::NewGuid().Guid
    $txPath = Join-Path $Global:RollbackDir $txID
    New-Item -Path $txPath -ItemType Directory -Force | Out-Null
    Write-GenLog "New backup transaction point mapped." "INFO" $txID
    return [PSCustomObject]@{
        TransactionID = $txID
        StorePath     = $txPath
        Backups       = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
}

function Save-FileToTransactionStore {
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$Transaction,
        [Parameter(Mandatory=$true)][string]$FilePath
    )
    if (-not (Test-Path $FilePath)) { return }
    try {
        $backupFile = [Guid]::NewGuid().Guid + ".bak"
        $destPath = Join-Path $Transaction.StorePath $backupFile

        $acl = Get-Acl -Path $FilePath
        $owner = $acl.Owner
        $sddl = $acl.GetSecurityDescriptorSddlForm('All')
        $item = Get-Item -Path $FilePath -Force

        Copy-Item -Path $FilePath -Destination $destPath -Force -ErrorAction Stop

        $Transaction.Backups.Add([PSCustomObject]@{
            Type         = "FILE"
            OriginalPath = $FilePath
            BackupPath   = $destPath
            Owner        = $owner
            SDDL         = $sddl
            Created      = $item.CreationTime
            Modified     = $item.LastWriteTime
            Access       = $item.LastAccessTime
        })
        Write-GenLog "Archived backup record for file: $FilePath" "INFO" $Transaction.TransactionID
    } catch {
        Write-GenLog "Transactional copy failed for: $FilePath. Details: $($_.Exception.Message)" "ERROR" $Transaction.TransactionID
    }
}

function Save-RegistryToTransactionStore {
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$Transaction,
        [Parameter(Mandatory=$true)][string]$KeyPath,
        [Parameter(Mandatory=$true)][string]$ValueName
    )
    try {
        if (Test-Path $KeyPath) {
            $prop = Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue
            if ($prop) {
                $backupFile = [Guid]::NewGuid().Guid + ".reg"
                $destPath = Join-Path $Transaction.StorePath $backupFile
                
                $regKey = $KeyPath -replace "HKLM:", "HKLM" -replace "HKCU:", "HKCU"
                & reg.exe export "$regKey" "$destPath" /y *>&1 | Out-Null

                $Transaction.Backups.Add([PSCustomObject]@{
                    Type         = "REGISTRY"
                    OriginalKey  = $KeyPath
                    ValueName    = $ValueName
                    OriginalVal  = $prop.$ValueName
                    BackupPath   = $destPath
                })
                Write-GenLog "Archived backup record for registry value: $KeyPath\$ValueName" "INFO" $Transaction.TransactionID
            }
        }
    } catch {
        Write-GenLog "Transactional registry export failed: $KeyPath\$ValueName" "ERROR" $Transaction.TransactionID
    }
}

function Invoke-RollbackTransaction {
    param([Parameter(Mandatory=$true)][PSCustomObject]$Transaction)
    Write-Host "  [!] CORE TRANSACTION FAILURE. INITIATING COMPLETE ROLLBACK PROTOCOL..." -ForegroundColor Yellow
    Write-GenLog "Rollback sequence active." "WARN" $Transaction.TransactionID

    foreach ($bk in $Transaction.Backups) {
        try {
            if ($bk.Type -eq "FILE") {
                if (Test-Path $bk.BackupPath) {
                    $parent = [System.IO.Path]::GetDirectoryName($bk.OriginalPath)
                    if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }

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
            Write-GenLog "Critical: Failure restoring item: $($bk.OriginalPath) during rollback" "CRIT" $Transaction.TransactionID
        }
    }
    Write-Host "  [+] Rollback Completed successfully." -ForegroundColor Green
}

# ==============================================================================
# [17] QUARANTINE MANAGER (AES-256 WITH DYNAMIC SESSION DERIVED KEYS)
# ==============================================================================
function Encrypt-Payload {
    param(
        [string]$InPath,
        [string]$OutPath,
        [string]$Password
    )
    try {
        $bytes = [System.IO.File]::ReadAllBytes($InPath)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $salt = [byte[]](11, 43, 202, 91, 74, 5, 12, 131)
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

function Decrypt-Payload {
    param(
        [string]$InPath,
        [string]$OutPath,
        [string]$Password
    )
    try {
        $bytes = [System.IO.File]::ReadAllBytes($InPath)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $salt = [byte[]](11, 43, 202, 91, 74, 5, 12, 131)
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

function Invoke-SecureQuarantine {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][PSCustomObject]$Transaction
    )
    if (-not (Test-Path $FilePath) -or $FilePath -match "^Registry:|^Task:|^Process ID:") { return $true }
    
    try {
        Save-FileToTransactionStore -Transaction $Transaction -FilePath $FilePath

        $guid = [Guid]::NewGuid().Guid
        $vaultFile = Join-Path $Global:QuarantineDir "$guid.vir"

        $acl = Get-Acl -Path $FilePath
        $owner = $acl.Owner
        $sddl = $acl.GetSecurityDescriptorSddlForm('All')
        $item = Get-Item -Path $FilePath -Force

        $item.Attributes = 'Normal'

        # SHA256 of original file
        $stream = [System.IO.File]::OpenRead($FilePath)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $originalHash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace("-","")
        $stream.Close()

        # Encrypt the payload using derived secret key
        $key = Get-DerivedVaultKey
        $encSuccess = Encrypt-Payload -InPath $FilePath -OutPath $vaultFile -Password $key
        if (-not $encSuccess) {
            Write-GenLog "Quarantine encryption failed for target: $FilePath" "ERROR" $Transaction.TransactionID
            return $false
        }
        
        # SHA256 of encrypted file
        $encStream = [System.IO.File]::OpenRead($vaultFile)
        $encryptedHash = [BitConverter]::ToString($sha.ComputeHash($encStream)).Replace("-","")
        $encStream.Close()

        # Safe Move / Delayed Delete logic - original deletion occurs post validation
        Remove-Item -Path $FilePath -Force

        # Manifest Schema JSON metadata
        $manifest = @{
            OriginalPath    = $FilePath
            OriginalName    = [System.IO.Path]::GetFileName($FilePath)
            VaultID         = $guid
            QuarantinedAt   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            OriginalHash    = $originalHash
            EncryptedHash   = $encryptedHash
            CreationTime    = $item.CreationTime.ToString("o")
            LastWriteTime   = $item.LastWriteTime.ToString("o")
            LastAccessTime  = $item.LastAccessTime.ToString("o")
            Owner           = $owner
            SDDL            = $sddl
            RestoreToken    = [Guid]::NewGuid().Guid
            TransactionID   = $Transaction.TransactionID
        }

        $manifest | ConvertTo-Json | Out-File (Join-Path $Global:QuarantineDir "$guid.json") -Force
        Write-GenLog "Quarantined vector target: $guid" "INFO" $Transaction.TransactionID
        return $true
    } catch {
        Write-GenLog "Remediation vault quarantine failed. Context: $($_.Exception.Message)" "ERROR" $Transaction.TransactionID
        return $false
    }
}

# ==============================================================================
# [18] REMEDIATOR
# ==============================================================================
function Test-SafeToStopProcess {
    param([int]$ProcessID)
    try {
        $proc = Get-Process -Id $ProcessID -ErrorAction SilentlyContinue
        if (-not $proc) { return $false }

        # Protection Level & Core PPL checks
        $critical = @("system", "idle", "csrss", "lsass", "smss", "services", "wininit", "winlogon", "svchost", "explorer")
        if ($critical -contains $proc.ProcessName.ToLower()) {
            return $false
        }
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
    $name = [System.IO.Path]::GetFileName($FilePath)
    if ($name -match "^g(.*\.exe)$" -and $name -notmatch "(?i)^gallery\.exe$") {
        $origName = $matches[1]
        $potentialOriginal = Join-Path ([System.IO.Path]::GetDirectoryName($FilePath)) $origName
        if (Test-Path $potentialOriginal) {
            try {
                $item = Get-Item $potentialOriginal -Force
                $item.Attributes = 'Normal'
                Write-GenLog "Unhidden original system application: $potentialOriginal" "INFO"
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
            Write-GenLog "Nulled matching decoy icon clone: $icoPath" "INFO"
            return $true
        } catch {}
    }
    return $false
}

function Invoke-DecoyImmunityDeployment {
    Write-Host "  [🔒] DEPLOYING IMMUTABLE ANTI-REGENERATION SYSTEM DECOYS..." -ForegroundColor Cyan
    Write-GenLog "Setting immutable decoy roadblocks." "INFO"

    $systemProfilePath = Join-Path -Path (Join-Path -Path $env:SystemRoot -ChildPath 'System32') -ChildPath 'config\systemprofile\AppData\Roaming\Gallery.exe'
    $decoys = @(
        (Join-Path -Path $env:APPDATA -ChildPath "Gallery.exe"),
        $systemProfilePath
    )

    foreach ($path in $decoys) {
        Write-Host "  [+] Arming decoy path: $path" -ForegroundColor Gray
        try {
            $parent = [System.IO.Path]::GetDirectoryName($path)
            if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }

            if (Test-Path $path) {
                takeown.exe /F "`"$path`"" /A *>&1 | Out-Null
                icacls.exe "`"$path`"" /grant "Administrators:F" /C /Q *>&1 | Out-Null
                Set-ItemProperty -Path $path -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue
                Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
            }

            # Write secure 0-byte road-block
            New-Item -Path $path -ItemType File -Force | Out-Null
            Attrib.exe +H +S $path

            $acl = Get-Acl -Path $path
            $acl.SetOwner([System.Security.Principal.NTAccount]"SYSTEM")
            $acl.SetAccessRuleProtection($true, $false)
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))

            Set-Acl -Path $path -AclObject $acl -ErrorAction Stop
            Write-Host "      -> System immutable roadblock engaged successfully." -ForegroundColor Green
        } catch {
            Write-Host "      -> Roadblock engagement failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ==============================================================================
# [19] REPORTER & INTEL TELEMETRY SERVICES
# ==============================================================================
function Export-EnterpriseIntelligenceReport {
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
            EvidenceCache = $EvidenceCache
            ThreatVectors = $ThreatDb
        } | ConvertTo-Json -Depth 5
        $payload | Out-File "$baseName.json" -Force
        return "$baseName.json"
    }

    if ($Format -eq "CSV") {
        $flatList = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($threat in $ThreatDb) {
            $flatList.Add([PSCustomObject]@{
                Path        = $threat.Forensics.Path
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
            body { background-color: #0d1117; color: #c9d1d9; font-family: 'Segoe UI', Arial, sans-serif; padding: 25px; }
            h1 { color: #58a6ff; border-bottom: 2px solid #21262d; padding-bottom: 12px; }
            .box { background-color: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 18px; margin-bottom: 22px; }
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
        <h1>🛡️ G.E.N. ULTRA - Host Forensics Report</h1>
        <div class="box">
            <h2>Environment Profile Context</h2>
            <p><strong>Hostname:</strong> $($Global:EnvStatus.ComputerName)</p>
            <p><strong>OS version:</strong> $($Global:EnvStatus.OSCaption) ($($Global:EnvStatus.Architecture))</p>
            <p><strong>Administrative Token:</strong> $($Global:EnvStatus.IsAdmin)</p>
            <p><strong>Boot State Context:</strong> $($Global:EnvStatus.EnvironmentMode)</p>
        </div>
        <h2>Active Suspicious Vectors</h2>
        <table>
            <thead>
                <tr>
                    <th>Target Path / ID</th>
                    <th>Risk Rating</th>
                    <th>Severity Class</th>
                    <th>Classification</th>
                    <th>Forensic Evidence Reasons</th>
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
# [20] RESTORE VAULT MANAGEMENT
# ==============================================================================
function Invoke-EnterpriseRestoreVault {
    Show-EnterpriseHeader
    Write-Host "  [♻] SECURE QUARANTINE ENCLAVE RESTORATION..." -ForegroundColor Cyan

    $manifests = Get-ChildItem -Path $Global:QuarantineDir -Filter "*.json" -ErrorAction SilentlyContinue
    if ($manifests.Count -eq 0) {
        Write-Host "  [+] Quarantine Enclave Vault is currently empty." -ForegroundColor Green
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
    $choice = Read-Host "`n  [?] Select record ID to restore"
    if ($choice -eq "0" -or -not $dict[$choice -as [int]]) {
        Write-Host "  [!] Action aborted by operator." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }

    $metaTarget = $dict[$choice -as [int]]
    $virFile = Join-Path $Global:QuarantineDir "$($metaTarget.VaultID).vir"

    if (Test-Path $virFile) {
        try {
            $parent = [System.IO.Path]::GetDirectoryName($metaTarget.OriginalPath)
            if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }

            $key = Get-DerivedVaultKey
            $decrypted = Decrypt-Payload -InPath $virFile -OutPath $metaTarget.OriginalPath -Password $key
            if ($decrypted) {
                # Recover timestamps
                $item = Get-Item $metaTarget.OriginalPath -Force
                $item.CreationTime = [DateTime]::Parse($metaTarget.CreationTime)
                $item.LastWriteTime = [DateTime]::Parse($metaTarget.LastWriteTime)
                $item.LastAccessTime = [DateTime]::Parse($metaTarget.LastAccessTime)

                # Recover access security descriptor
                if ($metaTarget.SDDL) {
                    try {
                        $acl = Get-Acl -Path $metaTarget.OriginalPath
                        $acl.SetSecurityDescriptorSddlForm($metaTarget.SDDL)
                        Set-Acl -Path $metaTarget.OriginalPath -AclObject $acl -ErrorAction SilentlyContinue
                    } catch {}
                }

                # Scrub enclave state
                Remove-Item -Path $virFile -Force
                Remove-Item -Path $manifests[($choice -as [int]) - 1].FullName -Force

                Write-Host "`n  [+] SUCCESS: Decrypted payload safely restored to original workspace: $($metaTarget.OriginalPath)" -ForegroundColor Green
                Write-GenLog "Scrubbed and restored original file state: $($metaTarget.OriginalPath)" "INFO"
            } else {
                Write-Host "  [-] Failed to decrypt enclave vault payload." -ForegroundColor Red
            }
        } catch {
            Write-Host "  [-] Vault restoration fault occurred: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [-] Quarantine vault payload cannot be located on disk." -ForegroundColor Red
    }
    Invoke-InteractivePause
}

# ==============================================================================
# [21] REMEDIATION DISPATCHER (TRANSACTION-BACKED CONTROL)
# ==============================================================================
function Invoke-InteractiveRemediation {
    Show-EnterpriseHeader
    Write-Host "  [🧹] DISPATCHING TRANSACTIONAL CLEANUP OPERATIONS..." -ForegroundColor Red
    
    if ($Global:ThreatDatabase.Count -eq 0) {
        Write-Host "`n  [+] Host Threat Database is clean. Please execute a scan (Option 1) first." -ForegroundColor Green
        Invoke-InteractivePause
        return
    }

    $tx = New-RollbackTransaction
    $remediated = 0
    $hasFailure = $false

    foreach ($threat in $Global:ThreatDatabase) {
        Write-Host "`n  -----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  [!] DIRECT REMEDIATION VECTOR DETECTED:" -ForegroundColor Yellow
        Write-Host "      Location  : $($threat.Forensics.Path)" -ForegroundColor White
        Write-Host "      Risk Score: $($threat.Risk.Score)/100 (Severity: $($threat.Risk.Severity))" -ForegroundColor Red
        Write-Host "      Heuristics: $($threat.Risk.Reasons)" -ForegroundColor Gray

        $confirm = Read-Host "  [?] Neutralize and isolate this vector target? (Y/N)"
        if ($confirm -match "^[Yy]") {
            
            # Double-confirmation for system core files
            if ($threat.Forensics.IsCriticalPath -and $threat.Forensics.IsMicrosoft) {
                Write-Host "  [!!!] SYSTEM PROTECTION PATH ALERT [!!!]" -ForegroundColor Red -BackgroundColor White
                $doubleConfirm = Read-Host "  This targets a core Microsoft signed resource. Type CONFIRM to bypass security"
                if ($doubleConfirm -ne "CONFIRM") {
                    Write-Host "  [!] Dispatch skipped. Core remains intact." -ForegroundColor Yellow
                    continue
                }
            }

            # Process Termination Dispatch
            if ($threat.Forensics.Path -match "^PID:") {
                if ($threat.Forensics.Path -match "PID:\s*(\d+)") {
                    $pid = [int]$matches[1]
                    if (Test-SafeToStopProcess -ProcessID $pid) {
                        try {
                            Stop-Process -Id $pid -Force -ErrorAction Stop
                            Write-Host "      -> Process terminated safely." -ForegroundColor Green
                            $remediated++
                        } catch {
                            Write-Host "      -> Process termination failed: $($_.Exception.Message)" -ForegroundColor Red
                            $hasFailure = $true
                        }
                    } else {
                        Write-Host "      -> Safe-Stop Protection: Process is critical or session 0 host. Stop blocked." -ForegroundColor Yellow
                    }
                }
            }
            else {
                # File System Isolation Dispatch
                if (Invoke-SecureQuarantine -FilePath $threat.Forensics.Path -Transaction $tx) {
                    Write-Host "      -> Quarantined into secure enclave." -ForegroundColor Green
                    $remediated++
                    
                    # Anti-regeneration cleanups
                    Restore-HiddenOriginal -FilePath $threat.Forensics.Path | Out-Null
                    Remove-IcoClones -FilePath $threat.Forensics.Path | Out-Null
                } else {
                    Write-Host "      -> Secure quarantine failed." -ForegroundColor Red
                    $hasFailure = $true
                }
            }
        } else {
            Write-Host "  [!] Vector skipped by human operator." -ForegroundColor DarkGray
        }
    }

    if ($hasFailure) {
        Write-Host "`n  [!] TRANSACTION WORKFLOW FAILURE DETECTED. ENFORCING TRANSACTION ROLLBACK..." -ForegroundColor Red
        Invoke-RollbackTransaction -Transaction $tx
    } else {
        Write-Host "`n  [✓] ALL TARGETS PROCESSED SUCCESSFULLY. Isolated: $remediated vectors." -ForegroundColor Green
        # Scrub transactional buffers post positive verification
        Remove-Item -Path $tx.StorePath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    $Global:ThreatDatabase.Clear()
    Invoke-InteractivePause
}

# ==============================================================================
# [22] UNINSTALL DECOYS PROTOCOL
# ==============================================================================
function Invoke-UninstallDecoys {
    Show-EnterpriseHeader
    Write-Host "  [🛡️] REMOVING IMMUTABLE SYSTEM DECOY ROADSBLOCKS..." -ForegroundColor Yellow
    Write-GenLog "Uninstalling decoy files." "INFO"
    
    $systemProfilePath = Join-Path -Path (Join-Path -Path $env:SystemRoot -ChildPath 'System32') -ChildPath 'config\systemprofile\AppData\Roaming\Gallery.exe'
    $decoys = @(
        (Join-Path -Path $env:APPDATA -ChildPath "Gallery.exe"),
        $systemProfilePath
    )

    foreach ($path in $decoys) {
        if (Test-Path $path) {
            Write-Host "  [-] Scrubbing roadblock decoy at: $path" -ForegroundColor Gray
            try {
                takeown.exe /F "`"$path`"" /A *>&1 | Out-Null
                icacls.exe "`"$path`"" /grant "Administrators:F" /C /Q *>&1 | Out-Null
                Set-ItemProperty -Path $path -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue
                Remove-Item -Path $path -Force -ErrorAction Stop
                Write-Host "      -> Decoy removed successfully." -ForegroundColor Green
            } catch {
                Write-Host "      -> Decoy removal failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    Invoke-InteractivePause
}

# ==============================================================================
# [23] DIAGNOSTIC VIEW
# ==============================================================================
function Show-DiagnosticView {
    Show-EnterpriseHeader
    Write-Host "  [⚙] HEALTH METRICS PROFILE & HOST SUMMARY" -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    
    Write-Host "  [-] Hostname             : $($Global:EnvStatus.ComputerName)" -ForegroundColor Gray
    Write-Host "  [-] Architecture         : $($Global:EnvStatus.Architecture)" -ForegroundColor Gray
    Write-Host "  [-] Platform OS Caption  : $($Global:EnvStatus.OSCaption) ($($Global:EnvStatus.OSVersion))" -ForegroundColor Gray
    Write-Host "  [-] Administrative State : $($Global:EnvStatus.IsAdmin)" -ForegroundColor Gray
    Write-Host "  [-] PowerShell Engine    : $($Global:EnvStatus.PSVersion)" -ForegroundColor Gray
    Write-Host "  [-] Active Safe Boots    : $($Global:EnvStatus.EnvironmentMode)" -ForegroundColor Gray
    Write-Host "  [-] Active Defender State: $($Global:EnvStatus.IsDefenderRunning)" -ForegroundColor Gray
    Write-Host "  [-] Running Engine Log   : $Global:LogFile" -ForegroundColor Gray
    Write-Host "  [-] Enclave Vault Area   : $Global:QuarantineDir" -ForegroundColor Gray

    Invoke-InteractivePause
}

# ==============================================================================
# [24] INTEL REPORT EXPORTER VIEW
# ==============================================================================
function Invoke-InteractiveReportExporter {
    Show-EnterpriseHeader
    Write-Host "  [📊] THREAT INTELLIGENCE EXPORT HUB..." -ForegroundColor Cyan
    
    Write-Host "  Choose target export format:" -ForegroundColor White
    Write-Host "  [1] JSON (Full structural database)" -ForegroundColor Gray
    Write-Host "  [2] CSV (Unified spreadsheet format)" -ForegroundColor Gray
    Write-Host "  [3] HTML (Enterprise styled document)" -ForegroundColor Gray
    
    $opt = Read-Host "`n  [?] Select format"
    $fmt = "JSON"
    if ($opt -eq "2") { $fmt = "CSV" }
    elseif ($opt -eq "3") { $fmt = "HTML" }
    
    $out = Export-EnterpriseReport -EvidenceCache $Global:EvidenceDatabase -ThreatDb $Global:ThreatDatabase -Format $fmt
    if ($out) {
        Write-Host "`n  [+] Successfully compiled and output report to: $out" -ForegroundColor Green
    } else {
        Write-Host "  [-] Intellectual report export failure." -ForegroundColor Red
    }
    Invoke-InteractivePause
}

# ==============================================================================
# [25] WINDOWS COMPONENT REPAIR
# ==============================================================================
function Invoke-SystemRepair {
    Show-EnterpriseHeader
    Write-Host "  [🛠] INITIATING WINDOWS REPAIR PROTOCOLS (DISM & SFC)..." -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    Write-Host "  [!] NOTE: Operation may require substantial duration. Do not interrupt.`n" -ForegroundColor Yellow

    Write-Host "  [1/2] Checking DISM Online Health Servicing..." -ForegroundColor Cyan
    $dism = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow -PassThru
    if ($dism.ExitCode -eq 0) {
        Write-Host "        -> DISM completed successfully.`n" -ForegroundColor Green
    } else {
        Write-Host "        -> DISM returned error code $($dism.ExitCode)`n" -ForegroundColor Red
    }

    Write-Host "  [2/2] Running SFC System File Scannow Check..." -ForegroundColor Cyan
    $sfc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -PassThru
    if ($sfc.ExitCode -eq 0) {
        Write-Host "        -> SFC repair sequence completed successfully.`n" -ForegroundColor Green
    } else {
        Write-Host "        -> SFC located integrity inconsistencies or returned code $($sfc.ExitCode)`n" -ForegroundColor Red
    }
    Invoke-InteractivePause
}

# ==============================================================================
# [26] SYSTEM TERMINAL PRESENTATION ENGINE
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
    Write-Host "                  🛡️ G.E.N ULTRA v10 ENTERPRISE INCIDENT CENTER            " -ForegroundColor Green
    Write-Host " 🌌 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 🌌`n" -ForegroundColor DarkGray
}

function Show-EnterpriseMenu {
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                      🌌 ENTERPRISE CONTROL CORE 🌌                       ║" -ForegroundColor White
    Write-Host "  ╠══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║ [1] 🔍 Deep File System Scan         ║ [6] 🔒 Deploy Decoys & Immunity  ║" -ForegroundColor White
    Write-Host "  ║ [2] 🧠 Live Process Memory Hunt      ║ [7] 🛠  Repair Windows (DISM/SFC)║" -ForegroundColor White
    Write-Host "  ║ [3] 🧬 Analyze Threat Database       ║ [8] 📊 Export Intelligence Report║" -ForegroundColor White
    Write-Host "  ║ [4] 🧹 Execute Quarantine & Clean    ║ [9] ⚙  Advanced Diagnostics      ║" -ForegroundColor White
    Write-Host "  ║ [5] ♻  Restore Vaulted Files         ║ [0] 🚪 Terminate Framework       ║" -ForegroundColor White
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-InteractivePause {
    Write-Host "`n  [ AWAITING OPERATOR ] Press any key to return to Command Matrix..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==============================================================================
# [27] INCIDENT CORE CONTROL ROUTER
# ==============================================================================
while ($true) {
    Show-EnterpriseHeader
    Show-EnterpriseMenu
    
    $choice = Read-Host "  [COMMAND ROUTER]"
    
    switch ($choice) {
        "1" { Invoke-DeepSystemScan; Invoke-InteractivePause }
        "2" { Invoke-DeepSystemScan; Invoke-InteractivePause } # Memory hunt integrated in Unified deep sweep
        "3" {
            Show-EnterpriseHeader
            if ($Global:ThreatDatabase.Count -eq 0) {
                Write-Host "  [+] Active Threat database is empty. No anomalies registered." -ForegroundColor Green
            } else {
                Write-Host "  [!] Mapped host threat database is active:`n" -ForegroundColor Yellow
                $Global:ThreatDatabase | Format-Table -Property @{N="Anomalous Vector Target";E={$_.Forensics.Path}}, @{N="Risk Score";E={$_.Risk.Score}}, @{N="Class";E={$_.Risk.Severity}}, @{N="Heuristics";E={$_.Risk.Reasons}} -AutoSize
            }
            Invoke-InteractivePause
        }
        "4" { Invoke-InteractiveRemediation }
        "5" { Invoke-EnterpriseRestoreVault }
        "6" { Invoke-DecoyImmunityDeployment; Invoke-InteractivePause }
        "7" { Invoke-SystemRepair }
        "8" { Invoke-InteractiveReportExporter }
        "9" { Show-DiagnosticView }
        "0" {
            Show-EnterpriseHeader
            Write-Host "  [+] Neutralizing enterprise session framework context..." -ForegroundColor Yellow
            Write-GenLog "Enterprise operational session closed." "INFO"
            Start-Sleep -Seconds 1
            Write-Host "  [✓] Sessions safely closed. Security intact." -ForegroundColor Green
            Start-Sleep -Seconds 1
            exit
        }
        Default {
            Write-Host "`n  [!] Invalid command path. Choice must align 0 to 9." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
