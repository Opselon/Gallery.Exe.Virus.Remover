# This script removes the Gallery-Lock decoy files.
# It must be run as an Administrator.

# User Profile
$userFile = "$env:APPDATA\Gallery.exe"
if (Test-Path $userFile) {
    takeown /f $userFile
    icacls $userFile /reset
    Remove-Item -Path $userFile -Force
}

# System Profile
$systemFile = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Gallery.exe"
if (Test-Path $systemFile) {
    takeown /f $systemFile
    icacls $systemFile /reset
    Remove-Item -Path $systemFile -Force
}
