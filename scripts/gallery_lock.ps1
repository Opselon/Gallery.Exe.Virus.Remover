function Lock-FileUltraSecure($targetPath) {
    # Ensure parent directory exists
    $parentDir = Split-Path $targetPath
    if (-not (Test-Path $parentDir)) {
        Write-Host "  [INFO] Parent directory not found. Creating: $parentDir"
        try {
            New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
            Write-Host "  [SUCCESS] Created parent directory."
        } catch {
            Write-Host "  [CRITICAL] Failed to create parent directory at $parentDir. Cannot proceed with this path."
            return # Stop processing for this path
        }
    }

    # Delete previous file if exists, with retries and forceful methods
    if (Test-Path $targetPath) {
        $maxRetries = 3
        $retryDelaySeconds = 2
        $deleted = $false

        for ($i = 1; $i -le $maxRetries; $i++) {
            Write-Host "Attempting to delete pre-existing file: $targetPath (Attempt $i of $maxRetries)"

            # --- Attempt 1: Simple Deletion ---
            try {
                Remove-Item -Path $targetPath -Force -ErrorAction Stop
                Write-Host "  [SUCCESS] Deleted file with simple removal."
                $deleted = $true
                break # Exit loop on success
            } catch {
                Write-Host "  [INFO] Simple deletion failed. Escalating to forceful removal..."
            }

            # --- Attempt 2: Forceful Deletion (Take Ownership & Reset ACLs) ---
            try {
                takeown /f $targetPath /a | Out-Null
                icacls $targetPath /reset /t /c /q | Out-Null
                Remove-Item -Path $targetPath -Force -ErrorAction Stop
                Write-Host "  [SUCCESS] Deleted file with forceful removal (takeown + icacls)."
                $deleted = $true
                break # Exit loop on success
            } catch {
                Write-Host "  [FAIL] Forceful deletion failed: $($_.Exception.Message)"
            }

            if ($i -lt $maxRetries) {
                Write-Host "  [INFO] Waiting for $retryDelaySeconds seconds before retrying..."
                Start-Sleep -Seconds $retryDelaySeconds
            }
        }

        if (-not $deleted) {
            Write-Host "  [CRITICAL] Failed to delete pre-existing file at $targetPath after $maxRetries attempts. The decoy cannot be created."
            # Continue anyway, as the New-Item might fail informatively.
        }
    }

    # Create dummy file
    try {
        New-Item -ItemType File -Path $targetPath -Force | Out-Null
        Write-Host "🧱 Created new dummy file at: $targetPath"
    } catch {
        Write-Host "❌ Failed to create file: $targetPath"
        return
    }

    # Make file Hidden + System
    try {
        Attrib +H +S $targetPath
        Write-Host "👻 File set to Hidden + System"
    } catch {
        Write-Host "⚠️ Couldn't set file attributes."
    }

    # Set ACL: Remove all rules, only allow SYSTEM, deny Everyone
    try {
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $deny = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Deny")
        $system = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")

        $acl.SetAccessRuleProtection($true, $false)
        $acl.AddAccessRule($deny)
        $acl.AddAccessRule($system)

        Set-Acl -Path $targetPath -AclObject $acl
        Write-Host "🔒 File ACL hardened: Deny Everyone, Allow SYSTEM only"
    } catch {
        Write-Host "❌ Failed to apply ACL."
    }
}

# ==== USER PROFILE ====
$userPath = "$env:APPDATA\Gallery.exe"
Write-Host "--- Processing User Profile Decoy ---"
Lock-FileUltraSecure -targetPath $userPath

# ==== SYSTEM PROFILE ====
$systemPath = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
Write-Host "--- Processing System Profile Decoy ---"
Lock-FileUltraSecure -targetPath $systemPath

# ==== FINAL SUMMARY ====
Write-Host ""
Write-Host "--- Final Status ---"
$successCount = 0

# Check User Decoy
try {
    if ((Test-Path $userPath) -and ((Get-Item $userPath -ErrorAction Stop).Length -eq 0)) {
        Write-Host "  [SUCCESS] User Profile Decoy: INSTALLED and verified."
        $successCount++
    } else {
        Write-Host "  [FAIL] User Profile Decoy: Verification failed."
    }
} catch {
    Write-Host "  [FAIL] User Profile Decoy: Could not be verified. Error: $($_.Exception.Message)"
}


# Check System Decoy
try {
    if ((Test-Path $systemPath) -and ((Get-Item $systemPath -ErrorAction Stop).Length -eq 0)) {
        Write-Host "  [SUCCESS] System Profile Decoy: INSTALLED and verified."
        $successCount++
    } else {
        Write-Host "  [FAIL] System Profile Decoy: Verification failed."
    }
} catch {
    Write-Host "  [FAIL] System Profile Decoy: Could not be verified. Error: $($_.Exception.Message)"
}


Write-Host "--------------------"
if ($successCount -eq 2) {
    Write-Host "✅ Gallery-Lock installation complete. Both decoys are active."
} else {
    Write-Host "⚠️ Gallery-Lock finished with one or more errors. Please review the log."
}
