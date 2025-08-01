param (
    [string]$Path
)

# Exit if path not provided
if (-not $Path) {
    Write-Host "INSECURE:No path provided."
    exit 1
}

# 1. Check Existence
if (-not (Test-Path $Path)) {
    Write-Host "NOT_FOUND"
    exit 0
}

# 2. Check File Size
try {
    if ((Get-Item $Path -ErrorAction Stop).Length -ne 0) {
        Write-Host "INSECURE:File size is not 0 bytes."
        exit 0
    }
} catch {
    Write-Host "INSECURE:Could not get file size. Error: $($_.Exception.Message)"
    exit 0
}

# 3. Check Owner
try {
    $owner = (Get-Acl $Path).Owner
    # On some systems, the owner might be the Administrators group if run from an admin shell,
    # while SYSTEM is expected when run with PsExec. Both are secure principals.
    if ($owner -ne "BUILTIN\Administrators" -and $owner -ne "NT AUTHORITY\SYSTEM") {
        Write-Host "INSECURE:Owner is '$owner', not SYSTEM or Administrators."
        exit 0
    }
} catch {
    Write-Host "INSECURE:Could not get file owner. Error: $($_.Exception.Message)"
    exit 0
}

# 4. Check ACL for "Deny Everyone"
try {
    $acl = Get-Acl $Path
    # Check for a rule that explicitly denies FullControl to the "Everyone" group.
    $denyRule = $acl.Access | Where-Object { $_.IdentityReference.Value -eq "Everyone" -and $_.AccessControlType -eq "Deny" -and $_.FileSystemRights -eq "FullControl" }
    if (-not $denyRule) {
        Write-Host "INSECURE:Missing 'Deny Everyone FullControl' rule."
        exit 0
    }
} catch {
    Write-Host "INSECURE:Could not get file ACLs. Error: $($_.Exception.Message)"
    exit 0
}

# If all checks pass
Write-Host "SECURE"
exit 0
