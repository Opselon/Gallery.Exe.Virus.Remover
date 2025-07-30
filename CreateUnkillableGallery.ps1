function Lock-FileUltraSecure($targetPath) {
    # Delete previous file if exists
    if (Test-Path $targetPath) {
        try {
            Remove-Item -Path $targetPath -Force -ErrorAction Stop
            Write-Host "🧨 Deleted previous file: $targetPath"
        } catch {
            Write-Host "⚠️ Could not delete existing file: $targetPath (might be locked)"
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
Lock-FileUltraSecure -targetPath $userPath

# ==== SYSTEM PROFILE ====
$systemPath = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
$systemFolder = Split-Path $systemPath
if (-Not (Test-Path $systemFolder)) {
    New-Item -ItemType Directory -Path $systemFolder -Force | Out-Null
    Write-Host "📁 SystemProfile Roaming folder created."
}
Lock-FileUltraSecure -targetPath $systemPath
