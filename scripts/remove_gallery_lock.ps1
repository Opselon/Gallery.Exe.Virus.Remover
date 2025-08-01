# This script removes the Gallery-Lock decoy files.
# It must be run as an Administrator.

function Remove-LockedFile($targetPath) {
    if (-not (Test-Path $targetPath)) {
        Write-Host "  [INFO] Decoy not found at $targetPath. Nothing to do."
        return $true # Indicate success as there's nothing to remove
    }

    Write-Host "--- Attempting to remove decoy: $targetPath ---"

    try {
        Write-Host "  - Taking ownership..."
        takeown /f $targetPath /a | Out-Null

        Write-Host "  - Resetting permissions..."
        icacls $targetPath /reset /t /c /q | Out-Null

        Write-Host "  - Deleting file..."
        Remove-Item -Path $targetPath -Force -ErrorAction Stop

        Write-Host "  [SUCCESS] Decoy successfully removed."
        return $true
    } catch {
        Write-Host "  [FAIL] Failed to remove decoy at $targetPath."
        Write-Host "  Error: $($_.Exception.Message)"
        return $false
    }
}

# --- Main Execution ---
$userPath = "$env:APPDATA\Gallery.exe"
$systemPath = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"

$userResult = Remove-LockedFile -targetPath $userPath
$systemResult = Remove-LockedFile -targetPath $systemPath

# --- Final Summary ---
Write-Host ""
Write-Host "--- Removal Summary ---"
if ($userResult -and $systemResult) {
    Write-Host "✅ Removal complete. Both decoys have been cleaned up."
} else {
    Write-Host "⚠️ Removal finished with one or more errors. Please review the log. Manual cleanup may be required."
}
