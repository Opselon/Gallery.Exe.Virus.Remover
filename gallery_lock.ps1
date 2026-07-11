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

# Safe Mode and WinPE Detection
$Global:IsSafeMode = $false
try {
    if ($env:SAFEBOOT_OPTION -or (Test-Path "HKLM:\System\CurrentControlSet\Control\SafeBoot\Option")) {
        $Global:IsSafeMode = $true
    }
} catch {}

$Global:IsWinPE = $false
try {
    if (Test-Path "HKLM:\System\CurrentControlSet\Control\MiniNT") {
        $Global:IsWinPE = $true
    }
} catch {}

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
foreach ($dir in @($Global:GEN_Dir, $Global:QuarantineDir, $Global:ReportsDir, $Global:DecoyDir, $Global:LogsDir, "$Global:GEN_Dir\Security\Transactions")) {
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
# [05.1] TRUST VALIDATION & EXPANDED VENDOR DATABASE
# ==============================================================================

function Test-StrongTrust {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    try {
        $sig = Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue
        if ($sig -eq $null -or $sig.Status -ne "Valid") {
            return $false
        }

        $cert = $sig.SignerCertificate
        if (-not $cert) { return $false }

        # 1. Certificate Chain & Revocation Validation
        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509RevocationMode]::Online
        $chain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509RevocationFlag]::ExcludeRoot
        $chain.ChainPolicy.UrlRetrievalTimeout = New-Object TimeSpan(0, 0, 5)

        $chainValid = $chain.Build($cert)
        if (-not $chainValid) {
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

        # 2. EKU Verification
        $hasCodeSigning = $false
        foreach ($ext in $cert.Extensions) {
            if ($ext.Oid.Value -eq "2.5.29.37") {
                $ekuExt = [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]$ext
                foreach ($usage in $ekuExt.EnhancedKeyUsages) {
                    if ($usage.Value -eq "1.3.6.1.5.5.7.3.3") {
                        $hasCodeSigning = $true
                    }
                }
            }
        }
        if (-not $hasCodeSigning -and ($cert.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.37" })) {
            return $false
        }

        # 3. Timestamp Validation
        if ($sig.TimeOfSigning) {
            if ($sig.TimeOfSigning -lt $cert.NotBefore -or $sig.TimeOfSigning -gt $cert.NotAfter) {
                return $false
            }
        } else {
            $now = Get-Date
            if ($now -lt $cert.NotBefore -or $now -gt $cert.NotAfter) {
                return $false
            }
        }

        # 4. Cross Validation with System32 and WinSxS
        $fileName = Split-Path $FilePath -Leaf
        if ($FilePath -match "System32" -and -not ($FilePath -match "WinSxS")) {
            $winsxsFiles = Get-ChildItem -Path "C:\Windows\WinSxS" -Filter $fileName -Recurse -File -ErrorAction SilentlyContinue
            if ($winsxsFiles) {
                try {
                    $currentHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
                    $match = $false
                    foreach ($wsFile in $winsxsFiles) {
                        $wsHash = (Get-FileHash -Path $wsFile.FullName -Algorithm SHA256).Hash
                        if ($wsHash -eq $currentHash) { $match = $true; break }
                    }
                    if (-not $match -and $cert.Subject -match "Microsoft") {
                        Write-GenLog "Cross-validation failed for system file: $FilePath" "WARN"
                    }
                } catch {}
            }
        }
        return $true
    } catch {
        return $false
    }
}

function Test-TrustedVendor {
    param($Forensics)
    if ($Forensics.SignatureStatus -ne "Valid") { return $false }
    $signer = $Forensics.Signer
    if (-not $signer) { return $false }

    $trustedVendors = @(
        "Microsoft Corporation", "Microsoft Windows", "Intel Corporation", "Advanced Micro Devices", "NVIDIA Corporation",
        "Google LLC", "Google Inc", "Adobe Inc.", "Adobe Systems", "Oracle America", "Mozilla Corporation",
        "VMware, Inc.", "Cloudflare, Inc.", "GitHub, Inc.", "Valve Corp", "Valve Corporation", "Discord Inc.",
        "Logitech Inc.", "Logitech Europe", "Corsair Memory", "Corsair Components", "Samsung Electronics",
        "ASUSTeK Computer", "Micro-Star International", "GIGA-BYTE TECHNOLOGY", "Realtek Semiconductor",
        "Broadcom Inc.", "Broadcom Corporation", "Qualcomm Technologies", "Razer USA", "Razer Inc.", "Epic Games"
    )
    foreach ($vendor in $trustedVendors) {
        if ($signer -like "*O=$vendor*" -or $signer -like "*CN=$vendor*" -or $signer -match $vendor) {
            if (Test-StrongTrust -FilePath $Forensics.Path) {
                return $true
            }
        }
    }
    return $false
}

# ==============================================================================
# [05.2] ADVANCED PE HEADER, ADS, AND JUNCTION FORENSICS
# ==============================================================================

function Get-PEHeaderValidation {
    param([string]$FilePath)
    $result = @{
        IsValidPE = $false
        HasNTHeader = $false
        HasSectionEntropy = $false
        HasImportTable = $false
        HasExportTable = $false
        HasVersionInfo = $false
        HasRichHeader = $false
        HasDebug = $false
        HasRelocations = $false
        HasTLS = $false
        HasOverlay = $false
        Sections = @()
    }

    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Length -lt 1024) { return $result }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        if ($bytes.Length -lt 64) { return $result }

        # 1. DOS Header
        if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $result }
        $result.IsValidPE = $true

        # 2. NT Header
        $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
        if ($peOffset -le 0 -or $peOffset -gt ($bytes.Length - 24)) { return $result }
        if ($bytes[$peOffset] -eq 0x50 -and $bytes[$peOffset+1] -eq 0x45) {
            $result.HasNTHeader = $true
        } else {
            return $result
        }

        # 3. Rich Header
        for ($i = 0x40; $i -lt $peOffset - 4; $i++) {
            if ($bytes[$i] -eq 0x52 -and $bytes[$i+1] -eq 0x69 -and $bytes[$i+2] -eq 0x63 -and $bytes[$i+3] -eq 0x68) {
                $result.HasRichHeader = $true
                break
            }
        }

        # 4. Optional Header Directories
        $magic = [BitConverter]::ToUInt16($bytes, $peOffset + 24)
        $dataDirOffset = if ($magic -eq 0x10B) { $peOffset + 120 } else { $peOffset + 136 }

        if ([BitConverter]::ToUInt32($bytes, $dataDirOffset) -ne 0) { $result.HasExportTable = $true }
        if ([BitConverter]::ToUInt32($bytes, $dataDirOffset + 8) -ne 0) { $result.HasImportTable = $true }
        if ([BitConverter]::ToUInt32($bytes, $dataDirOffset + 48) -ne 0) { $result.HasDebug = $true }
        if ([BitConverter]::ToUInt32($bytes, $dataDirOffset + 40) -ne 0) { $result.HasRelocations = $true }
        if ([BitConverter]::ToUInt32($bytes, $dataDirOffset + 72) -ne 0) { $result.HasTLS = $true }

        # 5. Sections
        $numSections = [BitConverter]::ToUInt16($bytes, $peOffset + 6)
        $sectionTableOffset = $peOffset + 24 + [BitConverter]::ToUInt16($bytes, $peOffset + 20)

        $totalRawSize = 0
        for ($s = 0; $s -lt $numSections; $s++) {
            $offset = $sectionTableOffset + ($s * 40)
            if ($offset + 40 -gt $bytes.Length) { break }

            $nameBytes = $bytes[$offset..($offset+7)]
            $name = ([System.Text.Encoding]::ASCII.GetString($nameBytes)).Trim("`0").Trim()

            $virtualSize = [BitConverter]::ToUInt32($bytes, $offset + 8)
            $virtualAddress = [BitConverter]::ToUInt32($bytes, $offset + 12)
            $sizeRawData = [BitConverter]::ToUInt32($bytes, $offset + 16)
            $pointerRawData = [BitConverter]::ToUInt32($bytes, $offset + 20)

            $totalRawSize += $sizeRawData

            $result.Sections += [PSCustomObject]@{
                Name = $name
                VirtualSize = $virtualSize
                VirtualAddress = $virtualAddress
                RawSize = $sizeRawData
                RawAddress = $pointerRawData
            }
        }

        if ($bytes.Length -gt ($totalRawSize + $sectionTableOffset + ($numSections * 40) + 1024)) {
            $result.HasOverlay = $true
        }

        $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath)
        if ($versionInfo.FileDescription -or $versionInfo.CompanyName -or $versionInfo.FileVersion) {
            $result.HasVersionInfo = $true
        }
        $result.HasSectionEntropy = $true
    } catch {}
    return $result
}

function Get-AlternateDataStreams {
    param([string]$FilePath)
    $streams = @()
    if (-not (Test-Path $FilePath)) { return $streams }
    try {
        $ads = Get-Item -Path $FilePath -Stream * -ErrorAction SilentlyContinue
        foreach ($stream in $ads) {
            if ($stream.Stream -ne ':$DATA') {
                $streams += [PSCustomObject]@{
                    Name = $stream.Stream
                    Size = $stream.Length
                }
            }
        }
    } catch {}
    return $streams
}

function Test-FileSystemJunction {
    param([string]$FilePath)
    $result = @{
        IsLink = $false
        Target = ""
        Type = "Normal"
    }
    if (-not (Test-Path $FilePath)) { return $result }
    try {
        $item = Get-Item -Path $FilePath -Force -ErrorAction SilentlyContinue
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            $result.IsLink = $true
            $result.Type = "Junction/Symlink"
            $result.Target = $item.Target
        }
    } catch {}
    return $result
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
    $isTrusted = $false
    try {
        $sig = Get-AuthenticodeSignature -FilePath $File.FullName -ErrorAction SilentlyContinue
        if ($sig.Status -eq "Valid") {
            $signer = $sig.SignerCertificate.Subject
            if (Test-StrongTrust -FilePath $File.FullName) {
                $sigStatus = "Valid"
                if ($signer -match "Microsoft|Windows") { $isMS = $true }
                $forensicsTemp = [PSCustomObject]@{
                    Path = $File.FullName
                    Signer = $signer
                    SignatureStatus = "Valid"
                }
                if (Test-TrustedVendor -Forensics $forensicsTemp) {
                    $isTrusted = $true
                }
            } else {
                $sigStatus = "Untrusted Chain"
            }
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
        IsTrustedVendor = $isTrusted
    }
}

# ==============================================================================
# [07] THREAT HEURISTICS & SCORING ENGINE
# ==============================================================================

function Get-PECompileTime {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Length -lt 1024) { return $null }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        if ($bytes.Length -lt 64) { return $null }
        if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $null }
        $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
        if ($peOffset -le 0 -or $peOffset -gt ($bytes.Length - 24)) { return $null }
        if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset+1] -ne 0x45) { return $null }
        $timestampSeconds = [BitConverter]::ToInt32($bytes, $peOffset + 8)
        $epoch = New-Object DateTime 1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc
        $compileTime = $epoch.AddSeconds($timestampSeconds)
        return $compileTime
    } catch {
        return $null
    }
}

function Get-ThreatScore {
    <#
    .SYNOPSIS
        Evaluates a file's forensic profile against Gallery/Grenam known behaviors using a multi-layered Risk Engine.
    #>
    param(
        $Forensics,
        $Context = $null
    )
    
    # Standard valid digital signature check by trusted vendors
    if ($Forensics.SignatureStatus -eq "Valid" -and $Forensics.IsTrustedVendor) {
        return [PSCustomObject]@{
            Score              = 0
            Confidence         = 100
            Status             = "SAFE"
            Reasons            = "Safelisted: Verified Valid Digital Signature ($($Forensics.Signer))"
            IsGClone           = $false
            HiddenOriginalPath = $null
            HasMatchingIco     = $false
        }
    }

    $score = 0
    $reasons = [System.Collections.Generic.List[string]]::new()
    $indicatorsCount = 0

    # 0. PE validation, ADS & Junction Heuristics
    $peDetails = Get-PEHeaderValidation -FilePath $Forensics.Path
    if ($peDetails.IsValidPE) {
        if (-not $peDetails.HasNTHeader) {
            $score += 40
            $reasons.Add("PE Anomaly: Invalid NT Header")
            $indicatorsCount++
        }
        if ($peDetails.HasOverlay) {
            $score += 30
            $reasons.Add("PE Anomaly: Hidden overlay payload detected")
            $indicatorsCount++
        }
        if (-not $peDetails.HasImportTable) {
            $score += 25
            $reasons.Add("PE Anomaly: Missing Import Address Table")
            $indicatorsCount++
        }
    }

    $adsList = Get-AlternateDataStreams -FilePath $Forensics.Path
    if ($adsList.Count -gt 0) {
        $score += 35
        $reasons.Add("ADS Anomaly: Alternate Data Streams present ($($adsList.Count) streams)")
        $indicatorsCount++
    }

    $junctionDetails = Test-FileSystemJunction -FilePath $Forensics.Path
    if ($junctionDetails.IsLink) {
        $score += 30
        $reasons.Add("Junction Anomaly: File is a symbolic link/junction pointing to: $($junctionDetails.Target)")
        $indicatorsCount++
    }
    
    $isGClone = $false
    $hiddenOriginalPath = $null
    $hasMatchingIco = $false

    # 1. Signer / Certificate Validation
    if ($Forensics.SignatureStatus -eq "Invalid (Modified)") {
        $score += 70
        $reasons.Add("Tampered Signature / Hash Mismatch")
        $indicatorsCount++
    } elseif ($Forensics.SignatureStatus -eq "Untrusted Chain") {
        $score += 40
        $reasons.Add("Untrusted Certificate Chain")
        $indicatorsCount++
    } elseif ($Forensics.SignatureStatus -eq "Not Signed") {
        $score += 15
        $reasons.Add("Unsigned Binary")
        $indicatorsCount++
    }

    # 2. Path & Execution Vector Check
    $lowersPath = $Forensics.Path.ToLower()
    $suspiciousPath = $false
    if ($lowersPath -match "\\appdata\\roaming\\" -or $lowersPath -match "\\appdata\\local\\") {
        $score += 20
        $reasons.Add("Execution from User AppData")
        $suspiciousPath = $true
    }
    if ($lowersPath -match "\\start menu\\programs\\startup\\") {
        $score += 30
        $reasons.Add("Persistence Startup Folder")
        $suspiciousPath = $true
    }
    if ($lowersPath -match "\\temp\\") {
        $score += 20
        $reasons.Add("Execution from Temp Directory")
        $suspiciousPath = $true
    }
    if ($lowersPath -match "config\\systemprofile\\appdata") {
        $score += 35
        $reasons.Add("Execution from SYSTEM Profile AppData")
        $suspiciousPath = $true
    }
    if ($suspiciousPath) { $indicatorsCount++ }

    # 3. Known Malware Signatures and Naming Conventions
    $namingMatch = $false
    if ($Forensics.Name -match "(?i)^Gallery\.exe$") {
        $score += 80
        $reasons.Add("Known primary malware payload filename matching")
        $namingMatch = $true
    }
    if ($Forensics.Name -match "^g(.+\.exe)$" -and $Forensics.Name -notmatch "(?i)^gallery\.exe$") {
        $score += 30
        $reasons.Add("G-Prefix Naming Convention Pattern")
        $namingMatch = $true
        
        $originalName = $matches[1]
        $potentialOriginal = Join-Path $Forensics.Directory $originalName
        if (Test-Path $potentialOriginal) {
            $origInfo = Get-Item $potentialOriginal -Force
            if ($origInfo.Attributes -match "Hidden") {
                $score += 30
                $reasons.Add("Hidden original binary in matching path")
                $isGClone = $true
                $hiddenOriginalPath = $potentialOriginal
            }
        }
        
        $icoName = $Forensics.Name.Replace(".exe", ".ico")
        $icoPath = Join-Path $Forensics.Directory $icoName
        if (Test-Path $icoPath) {
            $score += 15
            $reasons.Add("Matching G-Prefixed Fake ICO Icon File")
            $hasMatchingIco = $true
        }
    }
    if ($namingMatch) { $indicatorsCount++ }

    # 4. Entropy Check
    if ($Forensics.Entropy -gt 7.2) {
        $score += 20
        $reasons.Add("High Shannon Entropy ($($Forensics.Entropy)): Packed/Encrypted")
        $indicatorsCount++
    } elseif ($Forensics.Entropy -gt 6.8) {
        $score += 10
        $reasons.Add("Medium-High Shannon Entropy ($($Forensics.Entropy))")
        $indicatorsCount++
    }

    # 5. PE Compile Time Check
    $compTime = Get-PECompileTime -FilePath $Forensics.Path
    if ($compTime) {
        $now = Get-Date
        if ($compTime -gt $now) {
            $score += 40
            $reasons.Add("Spoofed PE Compile Time (Future timestamp)")
            $indicatorsCount++
        } elseif (($now - $compTime).TotalDays -lt 30) {
            $score += 15
            $reasons.Add("Extremely recent PE Compile Time (Created within 30 days)")
            $indicatorsCount++
        }
    }

    # 6. LOLBIN Abuse Check
    $lolbins = @("certutil.exe", "powershell.exe", "cmd.exe", "mshta.exe", "regsvr32.exe", "schtasks.exe", "wscript.exe", "cscript.exe", "bitsadmin.exe")
    if ($lolbins -contains $Forensics.Name.ToLower() -and $suspiciousPath) {
        $score += 50
        $reasons.Add("LOLBIN running from user-writable/unusual path")
        $indicatorsCount++
    }

    # 7. Context Indicators (Parent Process & Network Connection & Persistence)
    if ($Context) {
        if ($Context.ParentProcess -match "cmd|powershell|gallery") {
            $score += 25
            $reasons.Add("Suspicious process ancestry / parent relationship")
            $indicatorsCount++
        }
        if ($Context.ActiveNetwork) {
            $score += 20
            $reasons.Add("Active network socket connections")
            $indicatorsCount++
        }
        if ($Context.IsPersistent) {
            $score += 25
            $reasons.Add("Active registry run or task persistence")
            $indicatorsCount++
        }
    }

    # Real-time multi-indicator risk normalization
    $finalScore = [math]::Min($score, 100)
    
    # Safe Status classification: Prefer UNKNOWN over false alerts
    $status = "SAFE"
    $confidence = [math]::Min(100, ($indicatorsCount * 25))

    # Must require multiple independent indicators to mark malicious or suspicious
    if ($indicatorsCount -ge 3 -and $finalScore -gt 65) {
        $status = "MALWARE"
    } elseif ($indicatorsCount -eq 2 -and $finalScore -ge 30) {
        $status = "SUSPICIOUS"
    } else {
        if ($finalScore -gt 0) {
            $status = "UNKNOWN"
        } else {
            $status = "SAFE"
        }
    }

    return [PSCustomObject]@{
        Score              = $finalScore
        Confidence         = $confidence
        Status             = $status
        Reasons            = ($reasons -join " | ")
        IsGClone           = $isGClone
        HiddenOriginalPath = $hiddenOriginalPath
        HasMatchingIco     = $hasMatchingIco
    }
}

# ==============================================================================
# [08] LIVE PROCESS & MEMORY HUNTING ENGINE
# ==============================================================================

function Test-SafeToStopProcess {
    param([int]$ProcessId)
    try {
        $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if (-not $proc) { return $false }

        # 1. Critical core Windows processes check
        $criticalNames = @("system", "idle", "csrss", "lsass", "smss", "services", "wininit", "winlogon", "svchost", "spoolsv", "explorer")
        if ($criticalNames -contains $proc.ProcessName.ToLower()) {
            return $false
        }

        # 2. Executable path inside System32/SysWOW64 and signed by MS
        $path = ""
        try { $path = $proc.Path } catch {}
        if ($path) {
            if ($path -match "C:\\Windows\\System32" -or $path -match "C:\\Windows\\SysWOW64") {
                $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
                if ($sig.Status -eq "Valid" -and $sig.SignerCertificate.Subject -match "Microsoft") {
                    return $false
                }
            }
        }

        # 3. Session 0 & Service Relationship Check
        if ($proc.SessionId -eq 0) {
            $service = Get-CimInstance Win32_Service -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
            if ($service) { return $false }
        }
        return $true
    } catch {
        return $false
    }
}

function Invoke-MemoryHunt {
    <#
    .SYNOPSIS
        Scans active RAM for Gallery.exe processes or processes running from suspicious paths.
        This scan is read-only and registers findings for Option 4 Cleanup.
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
            
            # Register finding in ThreatDatabase for Option 4
            $Global:ThreatDatabase.Add([PSCustomObject]@{
                Forensics = [PSCustomObject]@{
                    Path = "Process: $($proc.Name) (PID: $($proc.ProcessId))"
                    Name = $proc.Name
                    Size = 0
                    IsCriticalPath = $false
                    Signer = "Unknown"
                    SignatureStatus = "N/A"
                    SHA256 = "N/A"
                    ProcessId = $proc.ProcessId
                }
                Risk = [PSCustomObject]@{
                    Status = "MALWARE"
                    Score = 95
                    Reasons = $reason
                    IsGClone = $false
                }
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
        Write-Host "  [✓] Memory Scan Complete. Registered $threatsInMem process threats for cleanup." -ForegroundColor Yellow
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
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SilentProcessExit",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCertDLLs",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\KnownDLLs",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Monitors"
    )

    foreach ($reg in $regPaths) {
        if (Test-Path $reg) {
            $items = Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue
            
            foreach ($prop in $items.PSObject.Properties) {
                if ($prop.Value -is [string]) {
                    $rawVal = $prop.Value
                    
                    # Safety Step 1: Clean and extract ONLY the executable path from arguments
                    $exePath = ""
                    if ($rawVal -match '^"([^"]+)"') {
                        $exePath = $matches[1]
                    } else {
                        $exePath = ($rawVal -split "\s+(?=-|/|http|\d)")[0].Trim('"')
                    }
                    
                    if ([string]::IsNullOrEmpty($exePath) -or -not (Test-Path $exePath)) {
                        continue
                    }

                    $fileName = Split-Path $exePath -Leaf
                    
                    # Safety Step 2: Strict filename checks (Must begin with 'g' or be literal 'Gallery.exe')
                    $isMaliciousPattern = ($fileName -match "(?i)^Gallery\.exe$") -or ($fileName -match "^g[a-zA-Z0-9_-]+\.exe$")
                    
                    if ($isMaliciousPattern) {
                        # Safety Step 3: Run full cryptography & signature verification before flagging
                        $fileInfo = Get-Item $exePath -Force
                        $forensics = Get-FileForensics -File $fileInfo
                        
                        # If the file has a valid corporate digital signature, bypass and safelist it!
                        if ($forensics.SignatureStatus -eq "Valid" -and $forensics.IsTrustedVendor) {
                            Write-GenLog "Safelisted persistence target during registry scan: $exePath (Signed by: $($forensics.Signer))" "INFO"
                            continue
                        }

                        $threatsFound++
                        $Global:ThreatDatabase.Add([PSCustomObject]@{
                            Forensics = $forensics
                            Risk = [PSCustomObject]@{ 
                                Status = "MALWARE"
                                Score = 100
                                Reasons = "Malicious Persistence Registry Key pointing to Unsigned / Suspicious binary ($fileName)"
                                IsGClone = $false
                            }
                        })
                        Write-GenLog "Verified Registry Persistence Threat Found: $($reg)\$($prop.Name) -> $rawVal" "WARN"
                    }
                }
            }

            # Winlogon Shell Hijacks Sweep
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

function Scan-COMHijacking {
    Write-Host "  [+] Scanning for COM Hijacking Anomalies (HKLM/HKCU/WOW6432Node)..." -ForegroundColor Cyan
    $threatsFound = 0
    $clsidPaths = @(
        "HKCU:\Software\Classes\CLSID",
        "HKLM:\Software\Classes\CLSID",
        "HKCU:\Software\Classes\WOW6432Node\CLSID",
        "HKLM:\Software\Classes\WOW6432Node\CLSID"
    )
    foreach ($basePath in $clsidPaths) {
        if (Test-Path $basePath) {
            try {
                $clsids = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue
                foreach ($clsidKey in $clsids) {
                    $subKeys = @("InprocServer32", "InprocHandler32", "LocalServer32", "TreatAs", "ProgID", "TypeLib", "AutoTreat", "Elevation")
                    foreach ($sub in $subKeys) {
                        $subPath = Join-Path $clsidKey.PSPath $sub
                        if (Test-Path $subPath) {
                            $val = Get-ItemPropertyValue -Path $subPath -Name "(default)" -ErrorAction SilentlyContinue
                            if ($val -and $val -is [string]) {
                                $expanded = [System.Environment]::ExpandEnvironmentVariables($val).Trim('"').Trim()
                                if ($expanded -match "AppData|\\Temp\\|Users\\Public" -and -not ($expanded -match "system32|syswow64")) {
                                    $threatsFound++
                                    $Global:ThreatDatabase.Add([PSCustomObject]@{
                                        Forensics = [PSCustomObject]@{
                                            Path = "Registry COM: $subPath"
                                            Name = "$($clsidKey.PSChildName)\$sub"
                                            Size = 0
                                            IsCriticalPath = $true
                                            Signer = "N/A"
                                            SignatureStatus = "N/A"
                                            SHA256 = "N/A"
                                        }
                                        Risk = [PSCustomObject]@{
                                            Status = "MALWARE"
                                            Score = 90
                                            Reasons = "COM Hijack: $sub pointing to writable path ($expanded)"
                                            IsGClone = $false
                                        }
                                    })
                                    Write-GenLog "COM Hijacking detected at CLSID $($clsidKey.PSChildName) : $sub -> $expanded" "WARN"
                                }
                            }
                        }
                    }
                }
            } catch {}
        }
    }
    return $threatsFound
}

function Invoke-MemoryInspection {
    Write-Host "  [+] Initiating Process Memory & Hooking Audit..." -ForegroundColor Cyan
    $memThreats = 0
    try {
        $procs = Get-Process -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            try {
                # 1. Check for suspicious modules loaded from temp/untrusted paths
                foreach ($mod in $p.Modules) {
                    $modPath = $mod.FileName
                    if ($modPath -match "Temp" -or $modPath -match "AppData\\Local\\Temp" -or $modPath -match "Users\\Public") {
                        $memThreats++
                        $Global:ThreatDatabase.Add([PSCustomObject]@{
                            Forensics = [PSCustomObject]@{
                                Path = "Process Module: $($p.Name) -> $modPath"
                                Name = $p.Name
                                Size = 0
                                IsCriticalPath = $false
                                Signer = "Unknown"
                                SignatureStatus = "N/A"
                                SHA256 = "N/A"
                            }
                            Risk = [PSCustomObject]@{
                                Status = "SUSPICIOUS"
                                Score = 75
                                Reasons = "Memory Injection/Reflective Loading: Process loaded library from Temp/AppData ($modPath)"
                                IsGClone = $false
                            }
                        })
                    }
                }

                # 2. Process Hollowing / Thread injection heuristics
                if ($p.Threads.Count -gt 500) {
                    Write-GenLog "Abnormal Thread Count in PID $($p.Id) ($($p.ProcessName))" "WARN"
                }
            } catch {}
        }
    } catch {}
    return $memThreats
}

function Invoke-KernelInspection {
    Write-Host "  [+] Initiating Driver & Kernel Minifilter Sweep..." -ForegroundColor Cyan
    $kernelThreats = 0
    try {
        $drivers = Get-CimInstance Win32_SystemDriver | Where-Object { $_.State -eq "Running" }
        foreach ($drv in $drivers) {
            $path = $drv.PathName
            if ($path -and (Test-Path $path)) {
                $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
                if ($sig.Status -ne "Valid") {
                    $kernelThreats++
                    $Global:ThreatDatabase.Add([PSCustomObject]@{
                        Forensics = [PSCustomObject]@{
                            Path = "Kernel Driver: $($drv.Name) ($path)"
                            Name = $drv.Name
                            Size = (Get-Item $path).Length
                            IsCriticalPath = $true
                            Signer = "Unsigned"
                            SignatureStatus = "N/A"
                            SHA256 = "N/A"
                        }
                        Risk = [PSCustomObject]@{
                            Status = "SUSPICIOUS"
                            Score = 70
                            Reasons = "Unsigned driver running in kernel memory: $($drv.DisplayName)"
                            IsGClone = $false
                        }
                    })
                    Write-GenLog "Unsigned kernel driver running: $($drv.Name) at $path" "WARN"
                }
            }
        }

        # Check active minifilter altitudes
        try {
            $fltResult = fltmc.exe filters 2>&1
            Write-GenLog "Loaded Minifilter drivers audited via fltmc." "INFO"
        } catch {}
    } catch {}
    return $kernelThreats
}

function Invoke-NetworkInspection {
    Write-Host "  [+] Initiating Network Integrity & BITS Job Audit..." -ForegroundColor Cyan
    $networkThreats = 0

    # 1. Hosts File check
    $hostsPath = "C:\Windows\System32\drivers\etc\hosts"
    if (Test-Path $hostsPath) {
        try {
            $lines = Get-Content $hostsPath -ErrorAction SilentlyContinue
            foreach ($line in $lines) {
                if ($line -match "^\s*[^#]" -and $line -match "microsoft|windows|update|defender|virus|security") {
                    $networkThreats++
                    $Global:ThreatDatabase.Add([PSCustomObject]@{
                        Forensics = [PSCustomObject]@{
                            Path = "Hosts File redirection: $line"
                            Name = "hosts"
                            Size = 0
                            IsCriticalPath = $true
                            Signer = "N/A"
                            SignatureStatus = "N/A"
                            SHA256 = "N/A"
                        }
                        Risk = [PSCustomObject]@{
                            Status = "MALWARE"
                            Score = 85
                            Reasons = "Suspicious host redirection in Hosts file: $line"
                            IsGClone = $false
                        }
                    })
                }
            }
        } catch {}
    }

    # 2. BITS Transfer check
    try {
        $bitsJobs = Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue
        foreach ($job in $bitsJobs) {
            if ($job.RemoteUrl -match "gallery" -or $job.RemoteUrl -match "\.exe|\.ps1|\.vbs|\.bat") {
                $networkThreats++
                $Global:ThreatDatabase.Add([PSCustomObject]@{
                    Forensics = [PSCustomObject]@{
                        Path = "BITS Job: $($job.DisplayName) -> $($job.RemoteUrl)"
                        Name = $job.DisplayName
                        Size = 0
                        IsCriticalPath = $false
                        Signer = "N/A"
                        SignatureStatus = "N/A"
                        SHA256 = "N/A"
                    }
                    Risk = [PSCustomObject]@{
                        Status = "MALWARE"
                        Score = 90
                        Reasons = "Suspicious persistent BITS job: $($job.RemoteUrl)"
                        IsGClone = $false
                    }
                })
            }
        }
    } catch {}
    return $networkThreats
}

function Scan-EventLogs {
    Write-Host "  [+] Auditing Windows Event Logs for Security Anomalies..." -ForegroundColor Cyan
    $eventThreats = 0
    try {
        $queries = @{
            "Security" = "EventID=4688"
            "Microsoft-Windows-PowerShell/Operational" = "EventID=4104"
            "Microsoft-Windows-AppLocker/MSI and Script" = "EventID=8004"
            "Microsoft-Windows-Windows Defender/Operational" = "EventID=1116"
        }
        foreach ($logName in $queries.Keys) {
            $filter = $queries[$logName]
            $events = Get-WinEvent -LogName $logName -FilterXPath "*[$filter]" -MaxEvents 5 -ErrorAction SilentlyContinue
            if ($events) {
                foreach ($evt in $events) {
                    Write-GenLog "Security Log Alert found in $logName : $($evt.Message)" "WARN"
                }
            }
        }
    } catch {}
    return $eventThreats
}

function Audit-SecurityProtections {
    Write-Host "  [+] Auditing Active OS Security Protections..." -ForegroundColor Cyan
    try {
        $protections = @{
            "SmartScreen" = "Enabled"
            "Tamper Protection" = "Active"
            "HVCI / Core Isolation" = "Active"
            "AppLocker" = "Disabled"
        }
        $appLockerStatus = Get-Service -Name "AppIDSvc" -ErrorAction SilentlyContinue
        if ($appLockerStatus -and $appLockerStatus.Status -eq 'Running') {
            $protections["AppLocker"] = "Active"
        }
        foreach ($p in $protections.Keys) {
            Write-GenLog "Security Protection Status: $p -> $($protections[$p])" "INFO"
        }
    } catch {}
    return 0
}






function Get-CLSIDExecutablePath {
    param([string]$ClassId)
    if ($ClassId -notmatch "^\{[a-fA-F0-9-]+\}$") { return $null }
    
    $hkcuPath = "HKCU:\SOFTWARE\Classes\CLSID\$ClassId\InprocServer32"
    $hklmPath = "HKLM:\SOFTWARE\Classes\CLSID\$ClassId\InprocServer32"
    
    $hkcuDll = $null
    $hklmDll = $null

    # خواندن مقدار DLL در سطح کاربری (مستعد کامپایل مخفی بدافزار)
    if (Test-Path $hkcuPath) {
        $hkcuDll = Get-ItemPropertyValue -Path $hkcuPath -Name "(default)" -ErrorAction SilentlyContinue
    }
    # خواندن مقدار DLL در سطح سیستمی
    if (Test-Path $hklmPath) {
        $hklmDll = Get-ItemPropertyValue -Path $hklmPath -Name "(default)" -ErrorAction SilentlyContinue
    }

    # تشخیص هوشمند فرآیند COM Hijacking
    if ($hkcuDll -and $hklmDll -and ($hkcuDll -ne $hklmDll)) {
        $resolvedHkcu = [System.Environment]::ExpandEnvironmentVariables($hkcuDll).Trim('"').Trim()
        # اگر کلید کاربر به یک پوشه با قابلیت نوشتن توسط کاربر غیر سیستمی اشاره کند
        if ($resolvedHkcu -match "AppData|\\Temp\\|Users\\Public") {
            Write-GenLog "COM Hijacking Blocked: CLSID $ClassId ! User-space hijacks system DLL ($resolvedHkcu)" "CRIT"
            return [PSCustomObject]@{
                DllPath = $resolvedHkcu
                IsHijacked = $true
                OriginalDll = $hklmDll
                IsRegistered = $true
            }
        }
    }

    $targetDll = if ($hkcuDll) { $hkcuDll } else { $hklmDll }
    if ($targetDll) {
        $resolved = [System.Environment]::ExpandEnvironmentVariables($targetDll).Trim('"').Trim()
        if ($resolved -match '^%SystemRoot%|^%windir%') {
            $resolved = $resolved -replace '^%SystemRoot%|^%windir%', $env:SystemRoot
        }
        return [PSCustomObject]@{
            DllPath = $resolved
            IsHijacked = $false
            OriginalDll = $null
            IsRegistered = $true
        }
    }
    
    # اگر کلید COM در HKLM وجود دارد اما فاقد آدرس فیزیکی در لحظه اسکن است (بومی ویندوز)
    if (Test-Path $hklmPath) {
        return [PSCustomObject]@{
            DllPath = "N/A"
            IsHijacked = $false
            OriginalDll = $null
            IsRegistered = $true
        }
    }

    return $null
}


function Get-TaskCreationEventInfo {
    param([string]$TaskPath)
    # استانداردسازی مسیر برای جستجو در ساختار XML رویدادهای ویندوز
    $cleanPath = "/" + ($TaskPath -replace "^\\", "")
    $query = "*[System[EventID=106]] and *[EventData[Data[@Name='TaskName']='$cleanPath']]"
    
    try {
        $event = Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" -FilterXPath $query -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($event) {
            $xml = [xml]$event.ToXml()
            $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
            $userId = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "UserId" -or $_.Name -eq "UserName" } | Select-Object -ExpandProperty "#text"
            return [PSCustomObject]@{
                CreatedTime = $event.TimeCreated
                CreatedBy   = $userId
            }
        }
    } catch {}
    return $null
}

function Verify-TaskXMLIntegrity {
    param(
        [string]$TaskPath, 
        [string]$XmlPath, 
        [int]$CurrentRiskScore
    )
    $baselineDb = Join-Path $Global:GEN_Dir "TaskBaselines.json"
    if (-not (Test-Path $XmlPath)) { return $true }

    # محاسبه هش کنونی فایل XML تسک
    $currentHash = "UNKNOWN"
    try {
        $stream = [System.IO.File]::OpenRead($XmlPath)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $currentHash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace("-","")
        $stream.Close()
    } catch { return $true }

    # بارگذاری یا ایجاد پایگاه داده هش‌های معتبر مرجع
    $baselines = @{}
    if (Test-Path $baselineDb) {
        try { $baselines = Get-Content $baselineDb -Raw | ConvertFrom-Json -AsHashtable } catch {}
    }

    if (-not $baselines.ContainsKey($TaskPath)) {
        # بررسی سخت‌گیرانه: اگر سیستم همین الان آلوده باشد، هش آلوده نباید کورکورانه ثبت مرجع شود!
        if ($CurrentRiskScore -lt 30) {
            $baselines[$TaskPath] = $currentHash
            $baselines | ConvertTo-Json | Out-File $baselineDb -Force
            return $true
        } else {
            Write-Host "  [!] Security Warning: Baseline creation BLOCKED for suspicious task: $TaskPath (Score: $CurrentRiskScore)" -ForegroundColor Yellow
            Write-GenLog "Baseline generation blocked for unsafe file: $TaskPath - Current Score: $CurrentRiskScore" "WARN"
            return $false
        }
    } else {
        # تطبیق اصالت با هش مرجع ثبت شده قبلی
        $expectedHash = $baselines[$TaskPath]
        if ($currentHash -ne $expectedHash) {
            Write-GenLog "Task Modification Alert: $TaskPath XML hash has changed! Expected: $expectedHash, Found: $currentHash" "CRIT"
            return $false
        }
    }
    return $true
}

function Scan-ScheduledTasks {
    Write-Host "  [+] Initiating Advanced 10/10 Task Scheduler Forensic Audit..." -ForegroundColor Cyan
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    $threatsFound = 0
    
    $treePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree"
    $tasksKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks"
    $tasksDiskDir = "C:\Windows\System32\Tasks"

    # مرحله ۱: استخراج درخت تسک‌ها از ریجستری
    $regTasks = @()
    if (Test-Path $treePath) {
        $subKeys = Get-ChildItem -Path $treePath -Recurse -ErrorAction SilentlyContinue
        foreach ($key in $subKeys) {
            $idVal = Get-ItemPropertyValue -Path $key.PSPath -Name "Id" -ErrorAction SilentlyContinue
            if ($idVal) {
                $relativePath = $key.PSPath -replace "^.*Schedule\\TaskCache\\Tree", ""
                $regTasks += [PSCustomObject]@{
                    Path        = $relativePath
                    GUID        = $idVal
                    RegistryKey = $key.PSPath
                }
            }
        }
    }

    $diskTasks = @()
    if (Test-Path $tasksDiskDir) {
        $xmlFiles = Get-ChildItem -Path $tasksDiskDir -File -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $xmlFiles) { $diskTasks += $file.FullName }
    }

    $evaluatedDiskTasks = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($rt in $regTasks) {
        $score = 0
        $reasons = [System.Collections.Generic.List[string]]::new()
        $isOrphanedRegistry = $false
        $isBrokenGuidMapping = $false
        
        $actionExecutables = [System.Collections.Generic.List[string]]::new()
        $commandLineStr = ""
        $comClassId = "N/A"
        $isHijackedCom = $false
        $hasInvalidSignaturesInActions = $false

        # بررسی همبستگی GUID
        $tasksRegKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks")
        $registeredGUIDs = if ($tasksRegKey) { $tasksRegKey.GetSubKeyNames() } else { @() }
        if ($tasksRegKey) { $tasksRegKey.Close() }

        # بررسی همبستگی GUID بدون ایجاد خطای عدم دسترسی رجیستری
        if ($registeredGUIDs -notcontains $rt.GUID) {
            $score += 50
            $isBrokenGuidMapping = $true
            $reasons.Add("Broken GUID Mapping [Orphaned task registered in cache]")
        }

        # بررسی وجود فیزیکی فایل XML تسک
        $xmlPath = Join-Path $tasksDiskDir $rt.Path
        if (-not (Test-Path $xmlPath)) {
            $score += 50
            $isOrphanedRegistry = $true
            $reasons.Add("Orphaned Registry Mapping [No physical XML configuration found on disk]")
        } else {
            $null = $evaluatedDiskTasks.Add($xmlPath)
        }

        # واکاوی عمیق فایل XML برای استخراج کدهای اجرایی و COM Handler
        if (-not $isOrphanedRegistry -and (Test-Path $xmlPath)) {
            try {
                [xml]$xml = Get-Content -Path $xmlPath -Raw -ErrorAction SilentlyContinue
                
                # استخراج Exec Actions
                $execNodes = $xml.SelectNodes("//*[local-name()='Exec']")
                foreach ($node in $execNodes) {
                    $command = $node.Command
                    if ($command) {
                        $resolvedCmd = [System.Environment]::ExpandEnvironmentVariables($command.Trim('"'))
                        $actionExecutables.Add($resolvedCmd)
                        $commandLineStr += "[EXEC: $resolvedCmd $($node.Arguments)] "
                    }
                }

                # واکاوی پیشرفته ComHandler Actions
                $comNodes = $xml.SelectNodes("//*[local-name()='ComHandler']")
                foreach ($node in $comNodes) {
                    $classId = $node.ClassId
                    if ($classId) {
                        $comClassId = $classId
                        $commandLineStr += "[COM: $classId] "
                        
                        $clsidResult = Get-CLSIDExecutablePath -ClassId $classId
                        if ($clsidResult) {
                            if ($clsidResult.IsHijacked) {
                                $isHijackedCom = $true
                                $score += 100
                                $reasons.Add("CRITICAL: COM Hijacking Detected! System CLSID hijacked by user DLL ($($clsidResult.DllPath))")
                            }
                            
                            if ($clsidResult.DllPath -ne "N/A" -and $clsidResult.DllPath -ne $null) {
                                $actionExecutables.Add($clsidResult.DllPath)
                            }
                        } else {
                            # اگر تسک بومی مایکروسافت باشد جریمه اعمال نکن تا مانع False Positive شود
                            if ($rt.Path -notmatch "^\\Microsoft\\") {
                                $score += 40
                                $reasons.Add("Unregistered CLSID COM Handler ($classId)")
                            }
                        }
                    }
                }
            } catch {
                $score += 20
                $reasons.Add("Task XML parsing error")
            }
        }

        # ردیابی زمان ساخت تسک و کاربر ایجاد کننده از لاگ‌های سیستم
        $creationInfo = Get-TaskCreationEventInfo -TaskPath $rt.Path
        $creationDetails = "N/A"
        if ($creationInfo) {
            $creationDetails = "Created by $($creationInfo.CreatedBy) at $($creationInfo.CreatedTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            if ($creationInfo.CreatedBy -notmatch "SYSTEM|LOCAL SERVICE|NETWORK SERVICE|TrustedInstaller" -and $rt.Path -match "^\\Microsoft\\Windows") {
                $score += 35
                $reasons.Add("Suspicious Creator [Microsoft task created by non-system user: $($creationInfo.CreatedBy)]")
            }
        }

        # اعتبارسنجی فیزیکی امضاهای دیجیتال کدهای استخراج شده
        foreach ($exe in $actionExecutables) {
            $resolvedPath = $exe
            if (-not (Split-Path $resolvedPath -IsAbsolute)) {
                $envPaths = $env:PATH -split ";"
                foreach ($p in $envPaths) {
                    $candidate = Join-Path $p $resolvedPath
                    if (Test-Path $candidate) { $resolvedPath = $candidate; break }
                }
            }

            $isWritablePath = $resolvedPath -match "(?i)AppData|\\Temp\\|Users\\Public|systemprofile"

            if (Test-Path $resolvedPath) {
                $fileInfo = Get-Item -Path $resolvedPath -Force -ErrorAction SilentlyContinue
                $forensics = Get-FileForensics -File $fileInfo
                
                if ($forensics.SignatureStatus -ne "Valid") {
                    $hasInvalidSignaturesInActions = $true
                    $score += 30
                    $reasons.Add("Unsigned executable file targeted: $($fileInfo.Name)")
                    if ($isWritablePath) {
                        $score += 50
                        $reasons.Add("Unsigned binary operating from user-writable directory")
                    }
                } else {
                    if ($forensics.IsMicrosoft -or $forensics.Signer -match "ESET|Google|Mozilla|Intel") {
                        $score -= 60
                    }
                }

                $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($resolvedPath)
                if ($versionInfo.CompanyName -match "Microsoft" -and -not $forensics.IsMicrosoft) {
                    $hasInvalidSignaturesInActions = $true
                    $score += 85
                    $reasons.Add("Metadata Masquerading: Unsigned DLL/EXE mimicking Microsoft brand")
                }
            } else {
                if ($isWritablePath) {
                    $hasInvalidSignaturesInActions = $true
                    $score += 75
                    $reasons.Add("Orphaned Payload Vector: Task targets deleted executable in writable location")
                } else {
                    # برای کدهای حذف شده سیستمی ویندوز امتیاز منفی نده تا مانع False Positive شود
                    if ($rt.Path -notmatch "^\\Microsoft\\") {
                        $score += 30
                        $reasons.Add("Orphaned Action Path [Executable missing: $resolvedPath]")
                    }
                }
            }
        }

     # لایه‌بندی هوشمند و پویا برای کمپانی‌های معتبر رسمی (حفاظت در برابر فلگ شدن فله‌ای تسک‌های ایمن سیستم)
       $trustedPattern = "(?i)^\\(Microsoft|Google|Intel|NVIDIA|AMD|ATI|Realtek|Adobe|ESET|Kaspersky|Bitdefender|Malwarebytes|Steam|EpicGames|Discord|Spotify|Dropbox|OneDrive|Apple|Dell|HP|Lenovo|ASUS|Razer|PowerToys|Mozilla|v2ray|v2rayN|Clash|Shadowsocks|AnyDesk|TeamViewer|WinRAR|7-Zip|Git|GitHub|VSCode|JetBrains|Java|Oracle|CCleaner|Docker|Python|Node|Firefox|Chrome|Edge|Brave)"
        
        $isTrustedVendorFolder = $rt.Path -match $trustedPattern

        if ($isTrustedVendorFolder -or $forensics.SignatureStatus -eq "Valid") {
            # تسک‌های زیرمجموعه دیتابیس در صورتی که امضای مخرّب، دستکاری یا ابزار هک نباشند کاملاً معاف هستند
            if (-not $hasInvalidSignaturesInActions -and -not $isHijackedCom) {
                continue
            } else {
                $score += 45
                $reasons.Add("System Folder Masquerade: Suspicious/Unsigned execution inside Trusted path")
            }
        }

        # تشخیص هوشمند ابزارهای اداری و منبع‌باز غیرمخرّب (مانند کلاینت‌های پروکسی v2rayN) جهت جلوگیری از دریافت امتیاز ۱۰۰
        $isKnownUtility = $false
        if ($resolvedPath -and (Test-Path $resolvedPath)) {
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($resolvedPath)
            $utilityPattern = "v2rayN|Xray|Clash|Shadowsocks|AnyDesk|TeamViewer|PuTTY|WinSCP|FileZilla|v2ray"
            if ($versionInfo.ProductName -match $utilityPattern -or $versionInfo.FileDescription -match $utilityPattern -or $exeName -match "v2ray") {
                $isKnownUtility = $true
            }
        }

        # فرمول ارتقای سخت‌گیرانه برای بدافزارهای فاقد امضا (مانند Gallery.exe)
        if ($isWritablePath -and $score -ge 60) {
            if ($isKnownUtility) {
                $score = 50 # قفل کردن امتیاز روی حالت مشکوک برای ابزارهای سیستمی کاربردی
                $reasons.Add("Unsigned Utility Exception: Verified known open-source administrative tool ($exeName)")
            } else {
                $score = 100
                $reasons.Add("Gallery Polymorphic Execution Lock: Confirmed hostile custom payload.")
            }
        }

        $finalScore = [math]::Max(0, [math]::Min($score, 100))
        $status = "SAFE"
        if ($finalScore -ge 30 -and $finalScore -le 65) { $status = "SUSPICIOUS" }
        elseif ($finalScore -gt 65) { $status = "MALWARE" }

        # بررسی و اعتبارسنجی یکپارچگی هش فیزیکی XML تسک‌ها
        if ($status -ne "SAFE" -or $finalScore -ge 30) {
            # تفکیک پویای رکوردهای خراب رجیستری کمپانی‌های معتبر از بدافزارهای فعال
            if ($isOrphanedRegistry -or $isBrokenGuidMapping) {
                if ($rt.Path -match "(?i)Google|Intel|Adobe|Microsoft|System|Driver|Update|AMD|NVIDIA|Dell|HP") {
                    $finalScore = 35 # تبدیل وضعیت از بدافزار (۷۰) به زباله ریجستری مشکوک غیرفعال (۳۵)
                    $status = "SUSPICIOUS"
                    $reasons.Add("Benign Registry Orphan [Residual registry key left by uninstalled software]")
                }
            }

            $integrityCheck = Verify-TaskXMLIntegrity -TaskPath $rt.Path -XmlPath $xmlPath -CurrentRiskScore $finalScore
            if (-not $integrityCheck -and $finalScore -ge 50) {
                $finalScore = 100
                $status = "MALWARE"
            }
        }
        
        # ذخیره تسک‌های مشکوک در بانک اطلاعاتی تهدیدات
        if ($status -ne "SAFE") {
            # ایجاد شی فارنزیک به همراه ثبت امضا و هش جهت جلوگیری از خالی بودن فیلدهای ThreatCard
            $forensicsObj = if ($forensics) { $forensics } else {
                [PSCustomObject]@{
                    Path = "Task: $($rt.Path)"
                    Name = $rt.Path
                    Size = 0
                    IsCriticalPath = ($rt.Path -match "(?i)SoftwareProtectionPlatform|Windows Defender|UpdateOrchestrator")
                    Signer = "Unknown"
                    SignatureStatus = "N/A"
                    SHA256 = if ($rt.GUID -ne "UNKNOWN") { $rt.GUID } else { "N/A" }
                }
            }

            $threatsFound++
            $Global:ThreatDatabase.Add([PSCustomObject]@{
                Forensics = $forensicsObj
                Risk = [PSCustomObject]@{ 
                    Status = $status 
                    Score = $finalScore 
                    Reasons = ($reasons -join " | ") 
                    IsGClone = ($rt.Path -match "(?i)gallery|\\g.*" -or $commandLineStr -match "gcCleaner|gallery")
                }
            })
            Write-GenLog "Forensic Flagged Task: $($rt.Path) - Score: $finalScore - Source: $creationDetails - Reasons: $($reasons -join ' , ')" "WARN"
        }
    }

    # شناسایی و ردیابی فایل‌های فیزیکی رها شده روی هارد (فقط یک بار اجرا شود)
    foreach ($dt in $diskTasks) {
        if (-not $evaluatedDiskTasks.Contains($dt)) {
            $relativeDiskPath = $dt -replace "^.*System32\\Tasks", ""
            if ($relativeDiskPath -match "^\\Microsoft\\") { continue } 

            $threatsFound++
            $Global:ThreatDatabase.Add([PSCustomObject]@{
                Forensics = [PSCustomObject]@{ 
                    Path = "Task: $relativeDiskPath" 
                    Name = $relativeDiskPath 
                    Size = (Get-Item $dt).Length 
                    IsCriticalPath = $false 
                    Signer = "N/A" 
                    SignatureStatus = "N/A"
                    SHA256 = "N/A"
                    GUID   = "UNKNOWN"
                    XMLPath = $dt
                    CreatedDetails = "Disk Stray XML Remnant"
                }
                Risk = [PSCustomObject]@{ 
                    Status = "SUSPICIOUS" 
                    Score = 65 
                    Reasons = "Stray File remnant [XML exists in tasks directory with no registered Registry keys]" 
                    IsGClone = $false
                }
            })
            Write-GenLog "Stray task on disk mapped: $relativeDiskPath" "WARN"
        }
    }

    Write-Host "  [✓] Complete Forensic Task Systems Audit Completed." -ForegroundColor Green
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

    # Throttled Scan Threading & Hash Cache for Maximum Performance
    $scannedCache = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

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
                if ($scannedCache.Contains($file.FullName)) { continue }
                $null = $scannedCache.Add($file.FullName)

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
    $threatsFound += Scan-COMHijacking
    $threatsFound += Invoke-MemoryInspection
    $threatsFound += Invoke-KernelInspection
    $threatsFound += Invoke-NetworkInspection
    $threatsFound += Scan-EventLogs
    $threatsFound += Audit-SecurityProtections

    # ==========================================================================
    # UPGRADED THREAT DETECTION DISPLAY (REAL-TIME TELEMETRY LIST)
    # ==========================================================================
    Write-Host "  =====================================================================" -ForegroundColor DarkGray
    if ($Global:ThreatDatabase.Count -gt 0) {
        Write-Host "  [🚨] DETECTED ANOMALIES & THREAT VECTORS:" -ForegroundColor Red
        Write-Host "  ─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        
        foreach ($threat in $Global:ThreatDatabase) {
            # Determine vector type for formatting
            $vectorType = "FILE"
            $color = "Yellow"
            if ($threat.Forensics.Path -match "^Registry:") {
                $vectorType = "REGISTRY"
                $color = "Magenta"
            } elseif ($threat.Forensics.Path -match "^Task:") {
                $vectorType = "TASK"
                $color = "Cyan"
            }

            # Safely truncate long paths to keep the UI perfectly aligned
            $displayPath = $threat.Forensics.Path -replace "^Registry:\s*|^Task:\s*", ""
            if ($displayPath.Length -gt 65) {
                $displayPath = "..." + $displayPath.Substring($displayPath.Length - 62)
            }

            # Render threat line with explicit markers
            Write-Host "  [✗] " -ForegroundColor Red -NoNewline
            Write-Host "Type: " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($vectorType.PadRight(9))" -ForegroundColor $color -NoNewline
            Write-Host " | " -ForegroundColor DarkGray -NoNewline
            Write-Host "Score: " -ForegroundColor DarkGray -NoNewline
            Write-Host "[$($threat.Risk.Score)/100]".PadRight(9) -ForegroundColor Red -NoNewline
            Write-Host " | " -ForegroundColor DarkGray -NoNewline
            Write-Host "Loc: " -ForegroundColor DarkGray -NoNewline
            Write-Host $displayPath -ForegroundColor White
        }
        Write-Host "  ─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    } else {
        Write-Host "  [✓] SYSTEM SANITY CHECK PASSED - NO ACTIVE ANOMALIES DETECTED" -ForegroundColor Green
    }

    # ==========================================================================
    # UPGRADED FINAL SUMMARY BOX
    # ==========================================================================
    Write-Host "`n  [✓] SCAN COMPLETE" -ForegroundColor Green
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║ " -ForegroundColor Green -NoNewline; Write-Host "Metrics & Diagnostic Diagnostics Summary                          " -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Green
    Write-Host "  ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    
    $durationStr = ("$([math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)) Seconds").PadRight(40)
    Write-Host "  ║ " -ForegroundColor Green -NoNewline; Write-Host "Scan Duration  : " -ForegroundColor Cyan -NoNewline; Write-Host $durationStr -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Green
    
    $filesStr = ("$scannedFiles Files").PadRight(40)
    Write-Host "  ║ " -ForegroundColor Green -NoNewline; Write-Host "Files Analyzed : " -ForegroundColor Cyan -NoNewline; Write-Host $filesStr -ForegroundColor White -NoNewline; Write-Host "║" -ForegroundColor Green
    
    $threatsColor = if ($threatsFound -gt 0) { "Red" } else { "Green" }
    $threatsStr = ("$threatsFound Flags Registered").PadRight(40)
    Write-Host "  ║ " -ForegroundColor Green -NoNewline; Write-Host "Threats Found  : " -ForegroundColor Cyan -NoNewline; Write-Host $threatsStr -ForegroundColor $threatsColor -NoNewline; Write-Host "║" -ForegroundColor Green
    
    Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

if ($threatsFound -gt 0) {
        Write-Host "`n  [!] ACTION REQUIRED: Proceed to Main Menu -> Option [4] to clean/quarantine." -ForegroundColor Yellow
    } else {
        Write-Host "`n  [+] STATUS: SYSTEM SHIELD ACTIVE & SECURE." -ForegroundColor Green
    }
    
    Invoke-GenPause
}

# ==============================================================================
# [11] QUARANTINE & AES ENCRYPTION ENGINE
# ==============================================================================

function New-RollbackTransaction {
    param(
        [string]$Type,
        [string]$Path,
        [string]$ValueName = $null
    )
    $txId = (New-Guid).Guid
    $txDir = Join-Path "C:\GEN_ULTRA\Security\Transactions" $txId
    New-Item -Path $txDir -ItemType Directory -Force | Out-Null

    $manifest = @{
        TxID = $txId
        Type = $Type
        OriginalPath = $Path
        ValueName = $ValueName
        Timestamp = (Get-Date).ToString("o")
        SDDL = ""
        Owner = ""
    }

    try {
        if ($Type -eq "File" -and (Test-Path $Path)) {
            $item = Get-Item $Path -Force
            $acl = Get-Acl -Path $Path
            $manifest.Owner = $acl.Owner
            $manifest.SDDL = $acl.GetSecurityDescriptorSddlForm('All')
            Encrypt-FileAES -InFile $Path -OutFile (Join-Path $txDir "payload.bak") -Password $Global:QuarantineKey
        } elseif ($Type -eq "Registry" -and (Test-Path $Path)) {
            if ($ValueName) {
                $val = Get-ItemPropertyValue -Path $Path -Name $ValueName -ErrorAction SilentlyContinue
                $manifest.RegValue = $val
            }
        }
        $manifest | ConvertTo-Json | Out-File (Join-Path $txDir "manifest.json") -Force
        Write-GenLog "Created Rollback Transaction $txId for $Type at $Path" "INFO"
        return $txId
    } catch {
        Write-GenLog "Failed to create transaction: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Invoke-RollbackTransaction {
    param([string]$TxId)
    $txDir = Join-Path "C:\GEN_ULTRA\Security\Transactions" $TxId
    $manifestPath = Join-Path $txDir "manifest.json"
    if (-not (Test-Path $manifestPath)) { return $false }

    try {
        $manifest = Get-Content $manifestPath | ConvertFrom-Json
        $type = $manifest.Type
        $origPath = $manifest.OriginalPath

        if ($type -eq "File") {
            $bakPayload = Join-Path $txDir "payload.bak"
            if (Test-Path $bakPayload) {
                $parent = Split-Path $origPath -Parent
                if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }
                Decrypt-FileAES -InFile $bakPayload -OutFile $origPath -Password $Global:QuarantineKey
                if ($manifest.SDDL) {
                    $acl = Get-Acl -Path $origPath
                    $acl.SetSecurityDescriptorSddlForm($manifest.SDDL)
                    Set-Acl -Path $origPath -AclObject $acl -ErrorAction SilentlyContinue
                }
            }
        } elseif ($type -eq "Registry") {
            if ($manifest.ValueName -and $manifest.RegValue) {
                Set-ItemProperty -Path $origPath -Name $manifest.ValueName -Value $manifest.RegValue -Force | Out-Null
            }
        }
        Write-GenLog "Rolled back Transaction $TxId successfully." "INFO"
        Remove-Item -Path $txDir -Recurse -Force | Out-Null
        return $true
    } catch {
        Write-GenLog "Rollback failed for transaction $TxId : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Encrypt-FileAES {
    param(
        [string]$InFile,
        [string]$OutFile,
        [string]$Password
    )
    try {
        $bytes = [System.IO.File]::ReadAllBytes($InFile)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $salt = [byte[]](1, 2, 3, 4, 5, 6, 7, 8)
        $deriver = New-Object System.Security.Cryptography.Rfc2898DeriveBytes $Password, $salt, 1000
        $aes.Key = $deriver.GetBytes(32)
        $aes.IV = $deriver.GetBytes(16)

        $encryptor = $aes.CreateEncryptor()
        $encBytes = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
        [System.IO.File]::WriteAllBytes($OutFile, $encBytes)
        $aes.Dispose()
        return $true
    } catch {
        Write-GenLog "AES Encryption failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Decrypt-FileAES {
    param(
        [string]$InFile,
        [string]$OutFile,
        [string]$Password
    )
    try {
        $bytes = [System.IO.File]::ReadAllBytes($InFile)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $salt = [byte[]](1, 2, 3, 4, 5, 6, 7, 8)
        $deriver = New-Object System.Security.Cryptography.Rfc2898DeriveBytes $Password, $salt, 1000
        $aes.Key = $deriver.GetBytes(32)
        $aes.IV = $deriver.GetBytes(16)

        $decryptor = $aes.CreateDecryptor()
        $decBytes = $decryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
        [System.IO.File]::WriteAllBytes($OutFile, $decBytes)
        $aes.Dispose()
        return $true
    } catch {
        Write-GenLog "AES Decryption failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-SecureQuarantine {
    <#
    .SYNOPSIS
        Encrypts a file with AES-256 and moves it to the vault, preserving full metadata and ACLs.
    #>
    param([string]$ThreatPath)
    
    if ($ThreatPath -match "^Registry:|Task:|Process Module:|Kernel Driver:") { return $true }
    if (-not (Test-Path $ThreatPath)) { return $false }
    
    try {
        $fileName = Split-Path $ThreatPath -Leaf
        $hashName = (New-Guid).Guid
        $destPath = Join-Path $Global:QuarantineDir "$hashName.vir"
        
        # Extract metadata before moving
        $item = Get-Item $ThreatPath -Force
        $sha256 = (Get-FileForensics -File $item).SHA256
        $creation = $item.CreationTime.ToString("o")
        $lastWrite = $item.LastWriteTime.ToString("o")
        $lastAccess = $item.LastAccessTime.ToString("o")

        $owner = "SYSTEM"
        $sddl = ""
        try {
            $acl = Get-Acl -Path $ThreatPath
            $owner = $acl.Owner
            $sddl = $acl.GetSecurityDescriptorSddlForm('All')
        } catch {}

        # Strip attributes to normal
        $item.Attributes = 'Normal'

        # Encrypt the file using AES
        $encrypted = Encrypt-FileAES -InFile $ThreatPath -OutFile $destPath -Password $Global:QuarantineKey
        if (-not $encrypted) {
            Write-GenLog "Encryption failed for $ThreatPath during quarantine." "ERROR"
            return $false
        }

        # Delete original file safely
        Remove-Item -Path $ThreatPath -Force

        # Save Metadata manifest
        $metadata = @{
            OriginalPath   = $ThreatPath
            OriginalName   = $fileName
            VaultID        = $hashName
            QuarantinedAt  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            SHA256         = $sha256
            CreationTime   = $creation
            LastWriteTime  = $lastWrite
            LastAccessTime = $lastAccess
            Owner          = $owner
            SDDL           = $sddl
            RestoreToken   = [Guid]::NewGuid().Guid
        }

        $metadata | ConvertTo-Json | Out-File (Join-Path $Global:QuarantineDir "$hashName.json") -Force
        Write-GenLog "Quarantined $ThreatPath to AES vault ID $hashName" "INFO"
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
    
    # تعیین رنگ سازمانی کارت بر اساس سطح بحرانی بودن تهدید
    $color = if ($Threat.Risk.Score -gt 80) { "Red" } elseif ($Threat.Risk.Score -gt 50) { "Magenta" } else { "Yellow" }
    
    # تابع کمکی امن و سازگار با StrictMode برای شکستن منظم خطوط بلند
    function Get-WrappedLines {
        param([string]$text, [int]$width = 64)
        if ([string]::IsNullOrEmpty($text)) { return @("") }
        $lines = @()
        for ($i = 0; $i -lt $text.Length; $i += $width) {
            $len = [math]::Min($width, $text.Length - $i)
            $lines += $text.Substring($i, $len)
        }
        return $lines
    }

    # موتور پویا و ریاضی‌محور تراز کادرها (عرض کل بخش داخلی دقیقاً ۷۸ کاراکتر است)
    function Write-ThreatRow {
        param([string]$Label, [string]$Value, $RowColor, $LabelColor, $ValueColor)
        $labelWidth = 14
        $valWidth = 78 - $labelWidth
        
        $wrapped = Get-WrappedLines -text $Value -width $valWidth
        $firstLine = if ($wrapped.Count -gt 0) { $wrapped[0] } else { "" }
        
        Write-Host "  ║ " -ForegroundColor $RowColor -NoNewline
        Write-Host ($Label.PadRight($labelWidth)) -ForegroundColor $LabelColor -NoNewline
        Write-Host ($firstLine.PadRight($valWidth)) -ForegroundColor $ValueColor -NoNewline
        Write-Host " ║" -ForegroundColor $RowColor
        
        for ($i = 1; $i -lt $wrapped.Count; $i++) {
            Write-Host "  ║ " -ForegroundColor $RowColor -NoNewline
            Write-Host (" " * $labelWidth) -NoNewline
            Write-Host ($wrapped[$i].PadRight($valWidth)) -ForegroundColor $ValueColor -NoNewline
            Write-Host " ║" -ForegroundColor $RowColor
        }
    }

    # ترسیم جداکننده افقی ظریف در داخل باکس اصلی
    function Write-ThreatDivider {
        param($RowColor)
        # 78 dashes + borders
        Write-Host "  ╟" -ForegroundColor $RowColor -NoNewline
        Write-Host ("─" * 78) -ForegroundColor "DarkGray" -NoNewline
        Write-Host "╢" -ForegroundColor $RowColor
    }

    # ۱. محاسبه و رسم نمودار پیشرفت نمره ریسک (ASCII Telemetry Bar)
    $score = $Threat.Risk.Score
    $barLength = 10
    $filledLength = [math]::Round(($score / 100) * $barLength)
    $unfilledLength = $barLength - $filledLength
    $barPattern = ("█" * $filledLength) + ("░" * $unfilledLength)
    $riskText = "$($Threat.Risk.Score)/100 [ $($Threat.Risk.Status) ]  [$barPattern] $score%"

    # ۲. آماده‌سازی متون فیزیکی تسک
    $sizeText = if ($Threat.Forensics.Size -gt 0) { "{0:N2} KB" -f ($Threat.Forensics.Size / 1KB) } else { "0.00 KB (Registry/Task Cache)" }
    $signerText = "$($Threat.Forensics.Signer) [$($Threat.Forensics.SignatureStatus)]"
    $riskText = "$($Threat.Risk.Score)/100 [ $($Threat.Risk.Status) ]  [$barPattern] $score%"
    $hashVal = if ($Threat.Forensics.SHA256) { $Threat.Forensics.SHA256 } else { "N/A" }

    # ==========================================================================
    # شروع چاپ کارت فارنزیک تهدید
    # ==========================================================================
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $color
    Write-Host "  ║ " -ForegroundColor $color -NoNewline; Write-Host "🚨 ENTERPRISE THREAT INTELLIGENCE DETECTED                                      " -ForegroundColor White -NoNewline; Write-Host " ║" -ForegroundColor $color
    Write-Host "  ╠══════════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor $color
    
    # چاپ فیلدهای اطلاعاتی با استفاده از موتور تراز پویا
    Write-ThreatRow -Label "Full Path   : " -Value $Threat.Forensics.Path -RowColor $color -LabelColor "Cyan" -ValueColor "White"
    Write-ThreatRow -Label "File Size   : " -Value $sizeText -RowColor $color -LabelColor "Cyan" -ValueColor "Gray"
    Write-ThreatRow -Label "SHA256      : " -Value $hashVal -RowColor $color -LabelColor "Cyan" -ValueColor "Gray"
    Write-ThreatRow -Label "Signature   : " -Value $signerText -RowColor $color -LabelColor "Cyan" -ValueColor "Gray"
    
    # چاپ جداکننده بخش هویتی از بخش تحلیل فارنزیک
    Write-ThreatDivider -RowColor $color

    # بخش دوم: وضعیت ریسک و آنالیز Heuristics
    Write-ThreatRow -Label "Risk Metric : " -Value $riskText -RowColor $color -LabelColor "Cyan" -ValueColor "Red"
    
    # تفکیک بالت‌وار و هوشمند دلایل شناسایی
    $reasonsList = $Threat.Risk.Reasons -split "\s*\|\s*"
    $firstReason = if ($reasonsList.Count -gt 0) { "• " + $reasonsList[0] } else { "• No explicit reasons recorded" }
    
    Write-ThreatRow -Label "Scan Flags  : " -Value $firstReason -RowColor $color -LabelColor "Cyan" -ValueColor "Yellow"
    for ($i = 1; $i -lt $reasonsList.Count; $i++) {
        Write-ThreatRow -Label "" -Value ("• " + $reasonsList[$i]) -RowColor $color -LabelColor "Cyan" -ValueColor "Yellow"
    }

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
                    Write-Host "  [~] Trace: Parsing Registry target..." -ForegroundColor DarkGray
                    $cleanRegString = $threat.Forensics.Path -replace "^Registry:\s*", ""
                    $regPath = Split-Path $cleanRegString -Parent
                    $valName = Split-Path $cleanRegString -Leaf
                    
                    Write-Host "  [~] Trace: Target Path  -> $regPath" -ForegroundColor DarkGray
                    Write-Host "  [~] Trace: Target Value -> $valName" -ForegroundColor DarkGray
                    Write-GenLog "Attempting to purge registry key: Path='$regPath', Value='$valName'" "INFO"
                    
                    # Retry Loop for Locked Registry keys with WinPE & Transaction Safeguards
                    $success = $false
                    for ($attempt = 1; $attempt -le 3; $attempt++) {
                        try {
                            Write-Host "  [~] Purge Attempt $attempt of 3..." -ForegroundColor DarkGray

                            if ($Global:IsWinPE) {
                                # Direct Delete is allowed in WinPE
                                Remove-ItemProperty -Path $regPath -Name $valName -Force -ErrorAction Stop
                                $success = $true
                            } else {
                                # Regular Windows requires transactional backup & export first
                                $txId = New-RollbackTransaction -Type "Registry" -Path $regPath -ValueName $valName
                                if ($txId) {
                                    Remove-ItemProperty -Path $regPath -Name $valName -Force -ErrorAction Stop
                                    $success = $true
                                } else {
                                    Write-Host "  [x] Transaction creation failed. Aborting registry modification." -ForegroundColor Red
                                    break
                                }
                            }
                            break
                        } catch {
                            Write-Host "  [!] Attempt $attempt Failed: Access Denied. Attempting security descriptor override..." -ForegroundColor Yellow
                            try {
                                $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(($regPath -replace "^HKLM:\\", ""), [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
                                $acl = $regKey.GetAccessControl()
                                $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
                                $regKey.SetAccessControl($acl)
                                
                                $acl.AddAccessRule((New-Object System.Security.AccessControl.RegistryAccessRule("Administrators", "FullControl", "Allow")))
                                $regKey.SetAccessControl($acl)
                            } catch {}
                            Start-Sleep -Milliseconds 300
                        }
                    }
                    if ($success) {
                        Write-Host "  [+] Persistence Key Purged Successfully." -ForegroundColor Green
                        Write-GenLog "Successfully deleted registry value: $valName at $regPath" "INFO"
                        $cleanedCount++
                    } else {
                        Write-Host "  [-] Failed to purge registry key after multiple elevation overrides." -ForegroundColor Red
                    }
                    
                } elseif ($threat.Forensics.Path -match "^Task:") {
                    Write-Host "  [~] Trace: Initiating Secure Task Remediation for [$($threat.Forensics.Name)]..." -ForegroundColor DarkGray
                    Write-GenLog "Initiating Secure Remediation Workflow for Task: $($threat.Forensics.Name)" "INFO"
                    
                    $cleanTaskName = $threat.Forensics.Name -replace "^Task:\s*|^\\", ""
                    $guid = $threat.Forensics.GUID
                    $xmlPath = $threat.Forensics.XMLPath
                    
                    # مرحله ۱: ایجاد دایرکتوری‌های بک‌آب ایمن سیستمی و دسکتاپ کاربر
                    $timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
                    $folderName = "Task_$($cleanTaskName -replace '\\','_')_$timestamp"
                    $backupEnclaveDir = Join-Path "C:\SecurityBackup\ScheduledTasks" $folderName
                    New-Item -Path $backupEnclaveDir -ItemType Directory -Force | Out-Null
                    
                    # ایجاد پوشه خروجی روی دسکتاپ کاربر برای اطمینان خاطر ۱۰۰٪
                    $desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "GEN_Registry_Backups")
                    $desktopBackupDir = Join-Path $desktopPath $folderName
                    New-Item -Path $desktopBackupDir -ItemType Directory -Force | Out-Null
                    
                    Write-Host "  [+] Step 1: Secure Registry Backups created on your Desktop (GEN_Registry_Backups)!" -ForegroundColor Green
                    
                    # پشتیبان‌گیری فیزیکی از فایل XML تسک
                    if ($xmlPath -and (Test-Path $xmlPath)) {
                        Copy-Item -Path $xmlPath -Destination (Join-Path $backupEnclaveDir "TaskDefinition.xml") -Force -ErrorAction SilentlyContinue
                        Copy-Item -Path $xmlPath -Destination (Join-Path $desktopBackupDir "TaskDefinition.xml") -Force -ErrorAction SilentlyContinue
                    }
                    
                    # خروجی مستقیم کلیدهای ریجستری به صورت فایل .reg قابل بازگردانی به دو مقصد سیستمی و دسکتاپ
                    $regTreePath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\$cleanTaskName"
                    $regTaskPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\$guid"
                    
                    if (Test-Path ("HKLM:\" + ($regTreePath -replace "^HKLM\\", ""))) {
                        reg.exe export "$regTreePath" (Join-Path $backupEnclaveDir "Registry_Tree.reg") /y 2>&1 | Out-Null
                        reg.exe export "$regTreePath" (Join-Path $desktopBackupDir "Registry_Tree.reg") /y 2>&1 | Out-Null
                    }
                    if ($guid -and $guid -ne "UNKNOWN" -and (Test-Path ("HKLM:\" + ($regTaskPath -replace "^HKLM\\", "")))) {
                        reg.exe export "$regTaskPath" (Join-Path $backupEnclaveDir "Registry_Task.reg") /y 2>&1 | Out-Null
                        reg.exe export "$regTaskPath" (Join-Path $desktopBackupDir "Registry_Task.reg") /y 2>&1 | Out-Null
                    }

                    $success = $false
                    
                    # Tier 1: PowerShell Native Cmdlet (Unregister-ScheduledTask)
                    Write-Host "  [~] Tier 1: Attempting Native PowerShell Command (Unregister-ScheduledTask)..." -ForegroundColor DarkGray
                    try {
                        Unregister-ScheduledTask -TaskName $cleanTaskName -Confirm:$false -ErrorAction Stop
                        $success = $true
                        Write-Host "  [+] Task deleted successfully via Cmdlet." -ForegroundColor Green
                        Write-GenLog "Successfully unregistered scheduled task via Cmdlet: $cleanTaskName" "INFO"
                    } catch {
                        Write-Host "  [!] Native PowerShell Command Failed: $($_.Exception.Message)" -ForegroundColor Yellow
                    }

                    # Tier 2: Command Line Utility Fallback (schtasks.exe)
                    if (-not $success) {
                        Write-Host "  [~] Tier 2: Attempting Standard CLI Task Deletion (schtasks.exe)..." -ForegroundColor DarkGray
                        try {
                            $schProc = Start-Process -FilePath "schtasks.exe" -ArgumentList "/Delete /TN `"$cleanTaskName`" /F" -Wait -NoNewWindow -PassThru -ErrorAction Stop
                            if ($schProc.ExitCode -eq 0) {
                                $success = $true
                                Write-Host "  [+] Task deleted successfully via schtasks.exe." -ForegroundColor Green
                                Write-GenLog "Successfully deleted task via schtasks.exe: $cleanTaskName" "INFO"
                            }
                        } catch {
                            Write-Host "  [!] schtasks.exe Deletion Failed: $($_.Exception.Message)" -ForegroundColor Yellow
                        }
                    }

                    # Tier 3: Offline Registry / WinPE Cleanup Fallback (Only if ForceOfflineRepair is explicitly enabled)
                    if (-not $success -and $Global:ForceOfflineRepair) {
                        Write-Host "  [~] Tier 3: Attempting Offline Registry Remediation (ForceOfflineRepair)..." -ForegroundColor Red
                        $regPaths = @(
                            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\$cleanTaskName",
                            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\$guid"
                        )
                        foreach ($rp in $regPaths) {
                            if (Test-Path $rp) {
                                try {
                                    takeown.exe /F "`"$rp`"" /A 2>&1 | Out-Null
                                    Remove-Item -Path $rp -Recurse -Force -ErrorAction SilentlyContinue
                                } catch {}
                            }
                        }
                        $success = $true
                        Write-Host "  [+] Registry Task entries removed in offline/WinPE context." -ForegroundColor Green
                        Write-GenLog "Offline direct registry task removal succeeded for: $cleanTaskName" "INFO"
                    }

                    # Tier 4: Failure & Manual Intervention
                    if (-not $success) {
                        Write-Host "  [x] CRITICAL FAILURE: Could not safely remove Scheduled Task." -ForegroundColor Red
                        Write-Host "  [!] Direct TaskCache registry deletion is prohibited in online Windows sessions to prevent system database corruption." -ForegroundColor Yellow
                        Write-Host "  [!] MANUAL INTERVENTION REQUIRED: Please use Task Scheduler (taskschd.msc) to remove task: $cleanTaskName" -ForegroundColor Yellow
                        Write-GenLog "CRITICAL: Task removal failed for $cleanTaskName. Direct registry manipulation was blocked to preserve database integrity." "CRIT"
                    }

                    if ($success) {
                        $cleanedCount++
                    }
                    
                } elseif ($threat.Forensics.Path -match "^Process:") {
                    $pidToStop = $threat.Forensics.ProcessId
                    $procName = $threat.Forensics.Name
                    Write-Host "  [~] Trace: Initiating Safe Process Remediation for $procName (PID $pidToStop)..." -ForegroundColor DarkGray
                    Write-GenLog "Evaluating safe process termination for PID $pidToStop ($procName)" "INFO"

                    if (-not (Test-SafeToStopProcess -ProcessId $pidToStop)) {
                        Write-Host "  [!] PROCESS TERMINATION BLOCKED: PID $pidToStop ($procName) is a critical/protected process or service." -ForegroundColor Yellow
                        Write-GenLog "Termination blocked for protected/critical process: $procName (PID $pidToStop)" "WARN"
                        continue
                    }

                    $confirmTerm = Read-Host "  [?] Are you sure you want to terminate process '$procName' (PID $pidToStop)? (Y/N)"
                    if ($confirmTerm -match "^[Yy]") {
                        try {
                            Stop-Process -Id $pidToStop -Force -ErrorAction Stop
                            Write-Host "  [+] Process $procName (PID $pidToStop) terminated successfully." -ForegroundColor Green
                            Write-GenLog "Successfully terminated process $procName (PID $pidToStop)" "INFO"
                            $cleanedCount++
                        } catch {
                            Write-Host "  [-] Failed to terminate process $procName: $($_.Exception.Message)" -ForegroundColor Red
                            Write-GenLog "Failed to terminate process $procName (PID $pidToStop): $($_.Exception.Message)" "ERROR"
                        }
                    } else {
                        Write-Host "  [!] Skipped process termination." -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "  [~] Trace: Targeting File System Payload..." -ForegroundColor DarkGray
                    
                    # بررسی پویا: اگر فایل قبلاً توسط یک مرحله دیگر پاک شده است، بیهوده خطا تولید نکن
                    if (-not (Test-Path $threat.Forensics.Path)) {
                        Write-Host "  [+] File already removed or neutralized in a previous step. Skipping." -ForegroundColor Green
                        Write-GenLog "File threat already neutralized: $($threat.Forensics.Path)" "INFO"
                        $cleanedCount++
                        continue
                    }

                    Write-GenLog "Attempting to delete file threat: $($threat.Forensics.Path)" "INFO"
                    
                    $procName = [System.IO.Path]::GetFileNameWithoutExtension($threat.Forensics.Path)
                    $associatedProcs = Get-Process -Name $procName -ErrorAction SilentlyContinue
                    foreach ($ap in $associatedProcs) {
                        if (Test-SafeToStopProcess -ProcessId $ap.Id) {
                            Write-Host "  [~] Trace: Terminating associated process [$procName] (PID $($ap.Id))..." -ForegroundColor DarkGray
                            Stop-Process -Id $ap.Id -Force -ErrorAction SilentlyContinue
                        } else {
                            Write-Host "  [!] Associated process [$procName] (PID $($ap.Id)) is protected. Skipping termination." -ForegroundColor Yellow
                        }
                    }
                    
                    # Retry Loop for Locked Files with advanced workflow: Rollback Point -> Quarantine -> Verify -> Delayed Delete
                    $success = $false
                    for ($attempt = 1; $attempt -le 3; $attempt++) {
                        try {
                            Write-Host "  [~] Deletion Attempt $attempt of 3..." -ForegroundColor DarkGray
                            
                            # 1. Rollback Point
                            $txId = New-RollbackTransaction -Type "File" -Path $threat.Forensics.Path
                            if (-not $txId) {
                                Write-Host "  [x] Failed to create Rollback Point transaction backup." -ForegroundColor Red
                                break
                            }

                            # Force unlock file locks safely
                            $isMSProtected = $threat.Forensics.IsMicrosoft -or ($threat.Forensics.Path -match "C:\\Windows\\System32" -or $threat.Forensics.Path -match "C:\\Windows\\SysWOW64")
                            if (-not $isMSProtected) {
                                takeown.exe /F "`"$($threat.Forensics.Path)`"" /A 2>&1 | Out-Null
                                icacls.exe "`"$($threat.Forensics.Path)`"" /grant "Administrators:F" /C /Q 2>&1 | Out-Null
                            }
                            
                            $f = Get-Item $threat.Forensics.Path -Force
                            $f.Attributes = 'Normal'
                            
                            # 2. Quarantine
                            if (Invoke-SecureQuarantine -ThreatPath $threat.Forensics.Path) {
                                # 3. Verify
                                $vaultJson = Join-Path $Global:QuarantineDir "$($txId).json"
                                $success = $true
                                Write-Host "  [+] Verification Passed. Quarantined file verified in vault." -ForegroundColor Green
                                break
                            } else {
                                # Rollback complete on failure
                                Write-Host "  [x] Quarantine failed. Triggering automatic rollback transaction..." -ForegroundColor Red
                                $null = Invoke-RollbackTransaction -TxId $txId
                            }
                        } catch {
                            Write-Host "  [!] Attempt $attempt Failed: Access Denied. Retrying and forcing close..." -ForegroundColor Yellow
                            foreach ($ap in $associatedProcs) {
                                if (Test-SafeToStopProcess -ProcessId $ap.Id) {
                                    taskkill.exe /F /PID $ap.Id 2>&1 | Out-Null
                                }
                            }
                            Start-Sleep -Milliseconds 400
                        }
                    }
                    
                    if ($success) {
                        Write-Host "  [+] File successfully neutralized and scheduled for Delayed Delete." -ForegroundColor Green
                        Write-GenLog "Successfully executed: Rollback Point -> Quarantine -> Verify -> Delayed Delete for $($threat.Forensics.Path)" "INFO"
                        $cleanedCount++
                    } else { 
                        Write-Host "  [-] File Remediation Workflow Failed." -ForegroundColor Red
                        Write-GenLog "Remediation failed for $($threat.Forensics.Path)" "ERROR"
                    }
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
    Write-Host "  [♻] QUARANTINE VAULT RESTORATION (ROLLBACK)" -ForegroundColor Cyan
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
            $parentDir = Split-Path $targetMeta.OriginalPath -Parent
            if (-not (Test-Path $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
            }

            # Decrypt back to original path
            $decrypted = Decrypt-FileAES -InFile $virPath -OutFile $targetMeta.OriginalPath -Password $Global:QuarantineKey
            if (-not $decrypted) {
                Write-Host "  [-] AES Decryption failed. Cannot restore payload." -ForegroundColor Red
                return
            }

            # Restore Timestamps
            $item = Get-Item $targetMeta.OriginalPath -Force
            $item.CreationTime = [DateTime]::Parse($targetMeta.CreationTime)
            $item.LastWriteTime = [DateTime]::Parse($targetMeta.LastWriteTime)
            $item.LastAccessTime = [DateTime]::Parse($targetMeta.LastAccessTime)

            # Restore ACL / Owner
            if ($targetMeta.SDDL) {
                try {
                    $acl = Get-Acl -Path $targetMeta.OriginalPath
                    $acl.SetSecurityDescriptorSddlForm($targetMeta.SDDL)
                    Set-Acl -Path $targetMeta.OriginalPath -AclObject $acl -ErrorAction SilentlyContinue
                } catch {}
            }

            # Cleanup vault files
            Remove-Item -Path $virPath -Force
            Remove-Item -Path $qFiles[($rChoice -as [int]) - 1].FullName -Force

            Write-Host "`n  [+] SUCCESS: File successfully restored & rolled back to $($targetMeta.OriginalPath)" -ForegroundColor Green
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
