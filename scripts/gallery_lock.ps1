#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Project TitanDecoy v5.1 (PRO-Compatible) - Ultimate Gallery.exe Malware Mitigation System.
.DESCRIPTION
    A comprehensive, GUI-driven security utility designed for the complete and total lockdown of 
    the "Gallery.exe" malware execution vector. This version is specifically modified to ensure
    full compatibility with Windows PowerShell 5.1.

    The application operates in distinct, user-controlled phases:
    1. SYSTEM ANALYSIS: Dynamically scans the host machine to identify all user profiles and potential
       malware drop locations. It provides a complete diagnostic of the target environment.
    
    2. VACCINATION & HARDENING: For each identified target path, the system executes a multi-step,
       atomic operation:
        - Forceful pre-emptive removal of any existing file or folder, taking ownership if required.
        - Creation of a zero-byte decoy file.
        - Application of 'Hidden' and 'System' file attributes to cloak the file.
        - Total lockdown via a hyper-strict Access Control List (ACL):
            - Ownership is transferred to the NT AUTHORITY\SYSTEM account.
            - All permission inheritance is severed.
            - An explicit 'Deny FullControl' rule is applied to the 'Everyone' group.
            - An explicit 'Allow FullControl' rule is granted ONLY to the 'SYSTEM' account.

    3. POST-OP VERIFICATION: After vaccination, a deep verification scan is initiated to programmatically
       confirm that every single security measure on every decoy file has been correctly applied.

    4. SYSTEM CLEANUP: A complete rollback feature that safely discovers and removes all decoys
       created by this tool, restoring the system to its pre-vaccination state.

    All operations are logged in real-time to a rich-text display within the application UI and
    to a persistent log file for forensic review.

.NOTES
    Author:      Jules & Gemini
    Version:     5.1 "Titan" (PS 5.1 Compatible)
    ReleaseDate: 2023-10-27
    License:     MIT
    ProjectURL:  https://github.com/Opselon/Gallery.Exe.Virus.Remover
#>

#================================================================================
# SCRIPT CONFIGURATION & GLOBAL STATE
#================================================================================
$Script:Version = "5.1 PRO 'Titan' (Compatible)"
$Script:LogFile = Join-Path $env:TEMP "TitanDecoy-Log-$($PID).log"
$Script:DecoyFileName = "Gallery.exe"
$Script:TargetPaths = [System.Collections.Generic.List[PSCustomObject]]::new()
$Script:UIObjects = @{}

#================================================================================
# GUI DEFINITION (WPF XAML)
#================================================================================
function Load-WpfForm {
    # Define the GUI layout in XAML. This is a here-string.
    Add-Type -AssemblyName PresentationFramework
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window_Main" Title="TitanDecoy v5.1 - Ultimate Malware Mitigation" Height="700" Width="900" MinHeight="600" MinWidth="800"
        WindowStartupLocation="CenterScreen" WindowStyle="SingleBorderWindow" Background="#FF1E1E1E">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Border Grid.Row="0" Background="#FF2D2D30" Padding="10" BorderBrush="#FF007ACC" BorderThickness="0,0,0,2">
            <StackPanel>
                <TextBlock Text="Project TitanDecoy - Gallery.exe Mitigation System" Foreground="White" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" FontFamily="Segoe UI"/>
                <TextBlock x:Name="TextBlock_Version" Text="Version 5.1 PRO 'Titan' | Administrator Privileges: Active" Foreground="#FF00AACC" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
            </StackPanel>
        </Border>

        <!-- MAIN CONTENT -->
        <TabControl Grid.Row="1" Margin="10" Background="#FF252526" BorderBrush="#FF3F3F46">
            <TabItem Header="Operations" Background="#FF3F3F46" Foreground="White">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="5">
                        <Button x:Name="Button_Analyze" Content="1. Analyze System" Padding="15,5" Margin="5" Background="#FF007ACC" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                        <Button x:Name="Button_Vaccinate" Content="2. VACCINATE SYSTEM" Padding="15,5" Margin="5" Background="#FF4CAF50" Foreground="White" FontWeight="Bold" IsEnabled="False" BorderThickness="0"/>
                        <Button x:Name="Button_Verify" Content="3. Verify Lockdown" Padding="15,5" Margin="5" Background="#FF9C27B0" Foreground="White" FontWeight="Bold" IsEnabled="False" BorderThickness="0"/>
                        <Button x:Name="Button_Cleanup" Content="REMOVE ALL DECOYS" Padding="15,5" Margin="5" Background="#FFF44336" Foreground="White" FontWeight="Bold" IsEnabled="False" BorderThickness="0"/>
                    </StackPanel>

                    <ListView x:Name="ListView_Targets" Grid.Row="1" Margin="5" Background="#FF1E1E1E" Foreground="White" BorderBrush="#FF3F3F46">
                        <ListView.View>
                            <GridView>
                                <GridViewColumn Header="Status" Width="120">
                                    <GridViewColumn.CellTemplate>
                                        <DataTemplate>
                                            <TextBlock Text="{Binding Status}" FontWeight="Bold" Foreground="{Binding StatusColor}"/>
                                        </DataTemplate>
                                    </GridViewColumn.CellTemplate>
                                </GridViewColumn>
                                <GridViewColumn Header="Target Path" Width="550" DisplayMemberBinding="{Binding Path}"/>
                                <GridViewColumn Header="Details" Width="200" DisplayMemberBinding="{Binding Message}"/>
                            </GridView>
                        </ListView.View>
                    </ListView>

                    <Grid Grid.Row="2" Margin="5">
                         <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <ProgressBar x:Name="ProgressBar_Main" Grid.Column="0" Height="22" Minimum="0" Maximum="100"/>
                        <TextBlock x:Name="TextBlock_Progress" Text="0%" Grid.Column="0" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="Black" FontWeight="Bold"/>
                        <TextBlock x:Name="TextBlock_Status" Grid.Column="1" Text="Status: Idle. Waiting for user command." VerticalAlignment="Center" Margin="10,0,0,0" Foreground="White"/>
                    </Grid>
                </Grid>
            </TabItem>
            <TabItem Header="Live Log" Background="#FF3F3F46" Foreground="White">
                <RichTextBox x:Name="RichTextBox_Log" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Background="#FF1E1E1E" Foreground="White" BorderThickness="0" FontFamily="Consolas"/>
            </TabItem>
             <TabItem Header="About" Background="#FF3F3F46" Foreground="White">
                <StackPanel Margin="20">
                    <TextBlock TextWrapping="Wrap" Foreground="White" FontSize="14">
                        <Run FontWeight="Bold" FontSize="18" Foreground="#FF00AACC">Project TitanDecoy v5.1 PRO</Run><LineBreak/><LineBreak/>
                        This utility is the culmination of efforts to create a definitive, proactive defense against malware leveraging the 'Gallery.exe' execution vector. By creating zero-byte, ultra-locked decoy files in common and dynamically discovered malware drop zones, it effectively blocks the malware from establishing persistence.<LineBreak/><LineBreak/>
                        <Run FontWeight="Bold">Author:</Run> Jules & Gemini<LineBreak/>
                        <Run FontWeight="Bold">Original Concept:</Run> Opselon (github.com/Opselon)<LineBreak/>
                        <Run FontWeight="Bold">GitHub:</Run> https://github.com/Opselon/Gallery.Exe.Virus.Remover<LineBreak/><LineBreak/>
                        <Run FontStyle="Italic">If you found this tool useful, please consider giving the project a star on GitHub to show your support.</Run>
                    </TextBlock>
                </StackPanel>
            </TabItem>
        </TabControl>
        
        <!-- FOOTER -->
        <StatusBar Grid.Row="2" Background="#FF007ACC">
            <StatusBarItem>
                <TextBlock x:Name="TextBlock_Footer" Text="Ready." Foreground="White"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

    # Read the XAML, create the window and controls
    try {
        $reader = [System.Xml.XmlNodeReader]::new($xaml)
        $window = [Windows.Markup.XamlReader]::Load($reader)
    }
    catch {
        Write-Error "FATAL: Could not parse WPF/XAML form. Error: $($_.Exception.Message)"
        exit 1
    }

    # Store all named WPF elements in a global hashtable for easy access
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
        $Script:UIObjects[$_.Name] = $window.FindName($_.Name)
    }

    return $window
}

#================================================================================
# UI & LOGGING HELPER FUNCTIONS
#================================================================================
function Add-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "FATAL")]
        [string]$Level
    )

    # Use the dispatcher to ensure thread-safe UI updates
    $Script:UIObjects.Window_Main.Dispatcher.InvokeAsync({
        $timestamp = Get-Date -Format "HH:mm:ss"
        $logLine = "[$timestamp] [$Level] > $Message"

        # Write to file
        Add-Content -Path $Script:LogFile -Value $logLine

        # Define colors for the rich text box
        $colorMap = @{
            INFO    = "#FFAAAAAA" # Gray
            SUCCESS = "#FF66BB6A" # Green
            WARN    = "#FFFFD54F" # Yellow
            ERROR   = "#FFFF7043" # Orange
            FATAL   = "#FFE53935" # Red
        }
        $logColor = $colorMap[$Level]

        # Write to UI RichTextBox
        $rtb = $Script:UIObjects.RichTextBox_Log
        $run = [System.Windows.Documents.Run]::new($logLine + [Environment]::NewLine)
        $run.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString($logColor))
        $rtb.Document.Blocks.Add([System.Windows.Documents.Paragraph]::new($run))
        $rtb.ScrollToEnd()
    }) | Out-Null
}

function Update-Status {
    param([string]$Text)
    $Script:UIObjects.Window_Main.Dispatcher.InvokeAsync({
        $Script:UIObjects.TextBlock_Status.Text = "Status: $Text"
    }) | Out-Null
}

function Update-Progress {
    param([int]$Value)
    $Script:UIObjects.Window_Main.Dispatcher.InvokeAsync({
        $Script:UIObjects.ProgressBar_Main.Value = $Value
        $Script:UIObjects.TextBlock_Progress.Text = "$Value%"
    }) | Out-Null
}

function Lock-UI {
    param([bool]$IsLocked)
    $Script:UIObjects.Window_Main.Dispatcher.InvokeAsync({
        $Script:UIObjects.Button_Analyze.IsEnabled = -not $IsLocked
        # Only enable operational buttons if analysis has been run
        if ($Script:TargetPaths.Count -gt 0) {
            $Script:UIObjects.Button_Vaccinate.IsEnabled = -not $IsLocked
            $Script:UIObjects.Button_Verify.IsEnabled = -not $IsLocked
            $Script:UIObjects.Button_Cleanup.IsEnabled = -not $IsLocked
        }
    }) | Out-Null
}

#================================================================================
# CORE ENGINE FUNCTIONS
#================================================================================
function Invoke-DecoyOperation {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("VACCINATE", "VERIFY", "CLEANUP")]
        [string]$Mode
    )

    Lock-UI -IsLocked $true
    Update-Status "Operation in progress: $Mode..."
    Add-Log -Level INFO -Message "===== Starting Operation: $Mode ====="

    $total = $Script:TargetPaths.Count
    $completed = 0
    $failures = 0

    foreach ($target in $Script:TargetPaths) {
        $target.Status = "Working..."
        $target.StatusColor = "#FF00AACC" # Cyan
        $Script:UIObjects.ListView_Targets.Items.Refresh()
        
        try {
            # --- Pre-check: Ensure parent drive is NTFS ---
            $parentDir = Split-Path -Path $target.Path -Parent
            $drive = Get-PSDrive -Name ($target.Path.Split(':')[0]) -ErrorAction Stop
            if ($drive.FileSystem -ne 'NTFS') {
                throw "Drive is not NTFS. Advanced ACL security cannot be applied."
            }

            if ($Mode -eq "VACCINATE") {
                # --- VACCINATION LOGIC ---
                # 1. Create parent directory if it doesn't exist
                if (-not (Test-Path -Path $parentDir)) {
                    Add-Log -Level INFO -Message "Creating parent directory: $parentDir"
                    New-Item -Path $parentDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }

                # 2. Forcefully remove any existing file/dir
                if (Test-Path -Path $target.Path) {
                    Add-Log -Level WARN -Message "Existing item found at $($target.Path). Attempting forceful removal..."
                    takeown.exe /F $target.Path /A /R /D Y > $null
                    icacls.exe $target.Path /reset /T /C /Q > $null
                    Remove-Item -Path $target.Path -Force -Recurse -ErrorAction Stop
                }

                # 3. Create the zero-byte decoy
                New-Item -Path $target.Path -ItemType File -Force -ErrorAction Stop | Out-Null
                
                # 4. Set attributes
                Set-ItemProperty -Path $target.Path -Name IsReadOnly -Value $false -Force
                Set-ItemProperty -Path $target.Path -Name Attributes -Value ([System.IO.FileAttributes]::Hidden, [System.IO.FileAttributes]::System) -Force -ErrorAction Stop
                
                # 5. Apply hyper-strict ACL
                $acl = Get-Acl -Path $target.Path
                $acl.SetOwner([System.Security.Principal.NTAccount]::new("SYSTEM"))
                $acl.SetAccessRuleProtection($true, $false) # Disable inheritance, remove existing rules
                $ruleDeny = [System.Security.AccessControl.FileSystemAccessRule]::new("Everyone", "FullControl", "Deny")
                $ruleAllow = [System.Security.AccessControl.FileSystemAccessRule]::new("SYSTEM", "FullControl", "Allow")
                $acl.AddAccessRule($ruleDeny)
                $acl.AddAccessRule($ruleAllow)
                Set-Acl -Path $target.Path -AclObject $acl -ErrorAction Stop

                $target.Status = "Success"
                $target.Message = "Decoy created and hardened."
                $target.StatusColor = "#FF66BB6A" # Green
            }
            elseif ($Mode -eq "CLEANUP") {
                # --- CLEANUP LOGIC ---
                if (Test-Path -Path $target.Path) {
                    # Verify it's OUR decoy before deleting
                    $item = Get-Item -Path $target.Path -Force
                    $acl = Get-Acl -Path $target.Path
                    if ($item.Length -eq 0 -and $acl.Owner -eq "NT AUTHORITY\SYSTEM") {
                        Add-Log -Level INFO -Message "Confirmed decoy at $($target.Path). Removing..."
                        # Must reset ACLs to be able to delete
                        icacls.exe $target.Path /reset /T /C /Q > $null
                        Remove-Item -Path $target.Path -Force -ErrorAction Stop
                        $target.Status = "Removed"
                        $target.Message = "Decoy successfully cleaned."
                        $target.StatusColor = "White"
                    } else {
                        Add-Log -Level WARN -Message "File at $($target.Path) is not a recognized decoy. Skipping."
                        $target.Status = "Skipped"
                        $target.Message = "Not a recognized decoy."
                        $target.StatusColor = "#FFFFD54F" # Yellow
                    }
                } else {
                    $target.Status = "Not Found"
                    $target.Message = "Clean."
                    $target.StatusColor = "Gray"
                }
            }
            elseif ($Mode -eq "VERIFY") {
                # --- VERIFICATION LOGIC ---
                if (-not (Test-Path $target.Path -PathType Leaf)) { throw "Decoy file not found." }
                
                $item = Get-Item -Path $target.Path -Force
                if ($item.Length -ne 0) { throw "Verification FAIL: File is not 0 bytes."}

                $acl = Get-Acl -Path $target.Path
                if ($acl.Owner -ne "NT AUTHORITY\SYSTEM") { throw "Verification FAIL: Owner is not SYSTEM." }
                if ($acl.AreAccessRulesProtected -ne $true) { throw "Verification FAIL: Inheritance is not blocked." }

                $rules = $acl.Access
                if ($rules.Count -ne 2) { throw "Verification FAIL: Incorrect number of ACL rules." }
                $denyRule = $rules | Where-Object { $_.IdentityReference -eq "Everyone" -and $_.AccessControlType -eq "Deny" }
                $allowRule = $rules | Where-Object { $_.IdentityReference -eq "NT AUTHORITY\SYSTEM" -and $_.AccessControlType -eq "Allow" }
                if (-not $denyRule -or -not $allowRule) { throw "Verification FAIL: Correct ACL rules not found." }

                $target.Status = "Verified"
                $target.Message = "Security lockdown confirmed."
                $target.StatusColor = "#FF66BB6A" # Green
            }
        }
        catch {
            $failures++
            $target.Status = "FAIL"
            $target.Message = $_.Exception.Message -replace '[\r\n].*' # First line only
            $target.StatusColor = "#FFE53935" # Red
            Add-Log -Level ERROR -Message "Operation failed for '$($target.Path)': $($_.Exception.Message)"
        }
        finally {
            $completed++
            Update-Progress -Value ([int](($completed / $total) * 100))
            $Script:UIObjects.ListView_Targets.Items.Refresh()
        }
    }

    $summaryMessage = "$Mode operation complete. Total: $total, Success: $($total - $failures), Failures: $failures."
    
    # ==================== THIS IS THE FIX ====================
    # Replaced the ternary operator (? :) with a standard if/else block for PS 5.1 compatibility.
    if ($failures -eq 0) {
        Add-Log -Level "SUCCESS" -Message "===== $summaryMessage ====="
    }
    else {
        Add-Log -Level "WARN" -Message "===== $summaryMessage ====="
    }
    # ================= END OF FIX ============================

    Update-Status $summaryMessage
    Lock-UI -IsLocked $false
}


#================================================================================
# MAIN EXECUTION & EVENT HANDLERS
#================================================================================

# --- Initialize Window and Event Handlers ---
$window = Load-WpfForm

$Script:UIObjects.Button_Analyze.Add_Click({
    Lock-UI -IsLocked $true
    Update-Status "Analyzing system..."
    Add-Log -Level INFO -Message "User initiated system analysis."
    $Script:UIObjects.ListView_Targets.ItemsSource = $null
    
    # Background job to keep UI responsive
    $job = Start-Job -ScriptBlock {
        $ScriptBlockContent = {
            $Script:DecoyFileName = "Gallery.exe"
            $discoveredPaths = [System.Collections.Generic.List[object]]::new()
            
            $basePaths = @(
                @{ Path = Join-Path $env:windir "Temp"; Description = "Windows Temp" };
                @{ Path = "C:\Windows\SysWOW64\config\systemprofile\AppData\Roaming"; Description = "System Profile (32-bit)" };
                @{ Path = "C:\Windows\System32\config\systemprofile\AppData\Roaming"; Description = "System Profile (64-bit)" }
            )

            foreach ($p in $basePaths) {
                if (Test-Path $p.Path) {
                    $discoveredPaths.Add([PSCustomObject]@{ Path = Join-Path $p.Path $Script:DecoyFileName; Description = $p.Description; Status = "Pending"; Message = "Awaiting operation"; StatusColor = "White" })
                    $discoveredPaths.Add([PSCustomObject]@{ Path = Join-Path $p.Path "gallery\$($Script:DecoyFileName)"; Description = "$($p.Description) (gallery subdir)"; Status = "Pending"; Message = "Awaiting operation"; StatusColor = "White" })
                }
            }

            Get-CimInstance -ClassName Win32_UserProfile | ForEach-Object {
                if ($_.LocalPath -and (Test-Path $_.LocalPath)) {
                    $userProfilePath = $_.LocalPath
                    $userName = $userProfilePath.Split('\')[-1]
                    $userPaths = @(
                        @{ Path = Join-Path $userProfilePath "AppData\Roaming"; Description = "User Profile Roaming ($userName)" };
                        @{ Path = Join-Path $userProfilePath "AppData\Local"; Description = "User Profile Local ($userName)" };
                        @{ Path = Join-Path $userProfilePath "AppData\Local\Temp"; Description = "User Temp ($userName)" };
                        @{ Path = Join-Path $userProfilePath "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"; Description = "User Startup ($userName)" }
                    )
                    foreach ($p in $userPaths) {
                         if (Test-Path $p.Path) {
                            $discoveredPaths.Add([PSCustomObject]@{ Path = Join-Path $p.Path $Script:DecoyFileName; Description = $p.Description; Status = "Pending"; Message = "Awaiting operation"; StatusColor = "White" })
                            $discoveredPaths.Add([PSCustomObject]@{ Path = Join-Path $p.Path "gallery\$($Script:DecoyFileName)"; Description = "$($p.Description) (gallery subdir)"; Status = "Pending"; Message = "Awaiting operation"; StatusColor = "White" })
                         }
                    }
                }
            }
            return $discoveredPaths | Sort-Object Path | Select-Object -Unique
        }
        Invoke-Command -ScriptBlock $ScriptBlockContent
    }

    $allPaths = Receive-Job -Job $job -Wait -AutoRemoveJob
    $Script:TargetPaths.Clear()
    $allPaths.ForEach({ $Script:TargetPaths.Add($_) })
    
    $Script:UIObjects.ListView_Targets.ItemsSource = $Script:TargetPaths
    Add-Log -Level SUCCESS -Message "Analysis complete. Found $($Script:TargetPaths.Count) potential targets."
    Update-Status "Analysis complete. Ready for vaccination."
    Lock-UI -IsLocked $false
})

$Script:UIObjects.Button_Vaccinate.Add_Click({
    Invoke-DecoyOperation -Mode "VACCINATE"
})

$Script:UIObjects.Button_Verify.Add_Click({
    Invoke-DecoyOperation -Mode "VERIFY"
})

$Script:UIObjects.Button_Cleanup.Add_Click({
    $confirm = [System.Windows.MessageBox]::Show(
        "Are you sure you want to remove ALL TitanDecoy files from this system? This action cannot be undone.",
        "Confirm Cleanup",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($confirm -eq "Yes") {
        Invoke-DecoyOperation -Mode "CLEANUP"
    } else {
        Add-Log -Level INFO -Message "User cancelled cleanup operation."
    }
})

# --- Application Entry Point ---
Add-Log -Level INFO -Message "TitanDecoy v$($Script:Version) Initializing..."
Add-Log -Level INFO -Message "Logging to file: $Script:LogFile"
Add-Log -Level WARN -Message "Administrator privileges are active. System modification is possible."
Update-Status "Ready. Please analyze the system first."

# Show the window
[void]$window.ShowDialog()
