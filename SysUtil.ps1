# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    # Relaunch as Administrator with hidden window
    $scriptPath = $MyInvocation.MyCommand.Path
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -WindowStyle Hidden
        exit
    } catch {
        Write-Error "Failed to elevate privileges: $($_.Exception.Message)"
        exit 1
    }
}

# Proceed with GUI if already elevated
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create the main form (non-movable)
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(480,400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(18,18,22)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.MaximizeBox = $false

# Download avatar image once and store it
$avatarUrl = "https://avatars.githubusercontent.com/u/96735577?v=4"
$tempImagePath = [System.IO.Path]::Combine($env:TEMP, "avatar_$([Guid]::NewGuid()).jpg")
try {
    Invoke-WebRequest -Uri $avatarUrl -OutFile $tempImagePath -ErrorAction Stop
    $global:avatarImage = [System.Drawing.Image]::FromFile($tempImagePath)
} catch {
    $global:avatarImage = $null
    Write-Warning "Failed to download avatar: $($_.Exception.Message)"
}

# Create custom toolbar panel for main window (no dragging)
$toolbarPanel = New-Object System.Windows.Forms.Panel
$toolbarPanel.Size = New-Object System.Drawing.Size(480,40)
$toolbarPanel.BackColor = [System.Drawing.Color]::FromArgb(30,30,38)
$form.Controls.Add($toolbarPanel)

# Toolbar title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10,8)
$titleLabel.Size = New-Object System.Drawing.Size(400,24)
$titleLabel.Text = "System Utility Dashboard"
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(200,200,200)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$toolbarPanel.Controls.Add($titleLabel)

# Custom close button in toolbar
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(445,5)
$closeButton.Size = New-Object System.Drawing.Size(30,30)
$closeButton.Text = "X"
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(198,40,40)
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Add_Click({ $form.Close() })
$toolbarPanel.Controls.Add($closeButton)

# Function to create styled buttons with rounded corners
function New-StyledButton {
    param($X, $Y, $Text, $Color, $Width = 180, $Height = 45)
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($X,$Y)
    $button.Size = New-Object System.Drawing.Size($Width,$Height)
    $button.Text = $Text
    $button.BackColor = $Color
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Regular)
    $button.FlatAppearance.BorderSize = 0
    $hoverR = [Math]::Min(255, $Color.R + 20)
    $hoverG = [Math]::Min(255, $Color.G + 20)
    $hoverB = [Math]::Min(255, $Color.B + 20)
    $button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb($hoverR, $hoverG, $hoverB)
    $radius = 10
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $buttonWidth = [int]$button.Width
    $buttonHeight = [int]$button.Height
    $rect = New-Object System.Drawing.Rectangle(0, 0, ($buttonWidth - 1), ($buttonHeight - 1))
    $path.AddArc($rect.X, $rect.Y, $radius*2, $radius*2, 180, 90)
    $path.AddArc($rect.Width-$radius*2, $rect.Y, $radius*2, $radius*2, 270, 90)
    $path.AddArc($rect.Width-$radius*2, $rect.Height-$radius*2, $radius*2, $radius*2, 0, 90)
    $path.AddArc($rect.X, $rect.Height-$radius*2, $radius*2, $radius*2, 90, 90)
    $path.CloseFigure()
    $button.Region = New-Object System.Drawing.Region($path)
    return $button
}

# System Info button
$sysInfoButton = New-StyledButton -X 50 -Y 60 -Text "System Info" -Color ([System.Drawing.Color]::FromArgb(0,120,215))
$sysInfoButton.Add_Click({
    $statusBar.Text = "Generating system info..."
    $info = Get-ComputerInfo
    $output = @"
System Information - $(Get-Date)
------------------------
OS: $($info.WindowsProductName)
Version: $($info.WindowsVersion)
RAM: $([math]::Round($info.CsTotalPhysicalMemory/1GB,2)) GB
Processor: $($info.CsProcessors.Name)
Motherboard: $($info.CsManufacturer) $($info.CsModel)
"@
    $filePath = "$env:USERPROFILE\Desktop\SystemInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $output | Out-File -FilePath $filePath -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("System info saved and opened:`n$filePath", "System Information")
    try {
        Start-Process -FilePath $filePath
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error opening file: $($_.Exception.Message)", "Open Error")
        $statusBar.Text = "File open failed"
    }
    $statusBar.Text = "System info saved and opened"
})
$form.Controls.Add($sysInfoButton)

# Check Disk button
$diskButton = New-StyledButton -X 250 -Y 60 -Text "Check Disk Space" -Color ([System.Drawing.Color]::FromArgb(0,150,136))
$diskButton.Add_Click({
    $statusBar.Text = "Checking disk space..."
    $disk = Get-Disk | Select-Object -First 1
    $space = Get-PSDrive C | Select-Object Used,Free
    [System.Windows.Forms.MessageBox]::Show("Disk Health: $($disk.HealthStatus)`nUsed: $([math]::Round($space.Used/1GB,2)) GB`nFree: $([math]::Round($space.Free/1GB,2)) GB", "Disk Information")
    $statusBar.Text = "Disk space checked"
})
$form.Controls.Add($diskButton)

# Repair Windows button
$repairButton = New-StyledButton -X 50 -Y 125 -Text "Repair Windows" -Color ([System.Drawing.Color]::FromArgb(156,39,176))
$repairButton.Add_Click({
    $statusBar.Text = "Starting Windows repair..."
    $form.Refresh()
    $logFile = "$env:USERPROFILE\Desktop\RepairLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    try {
        $statusBar.Text = "Checking component store health..."
        $form.Refresh()
        $dismCheckOutput = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth" -NoNewWindow -Wait -RedirectStandardOutput "$env:TEMP\dism_check.txt" -PassThru
        $dismCheck = Get-Content "$env:TEMP\dism_check.txt" -Raw
        $dismCheck | Out-File -FilePath $logFile -Append
        Remove-Item "$env:TEMP\dism_check.txt" -Force
        
        if ($dismCheckOutput.ExitCode -eq 0 -and $dismCheck -match "No component store corruption detected") {
            $dismStatus = "No corruption detected"
        } else {
            $statusBar.Text = "Repairing component store..."
            $form.Refresh()
            $dismRestoreOutput = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -RedirectStandardOutput "$env:TEMP\dism_restore.txt" -PassThru
            $dismRestore = Get-Content "$env:TEMP\dism_restore.txt" -Raw
            $dismRestore | Out-File -FilePath $logFile -Append
            Remove-Item "$env:TEMP\dism_restore.txt" -Force
            
            if ($dismRestoreOutput.ExitCode -eq 0 -and $dismRestore -match "The restore operation completed successfully") {
                $dismStatus = "Component store repaired"
            } else {
                $dismStatus = "Component store repair failed (Exit Code: $($dismRestoreOutput.ExitCode))"
            }
        }

        $statusBar.Text = "Running SFC scan..."
        $form.Refresh()
        $sfcOutput = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -RedirectStandardOutput "$env:TEMP\sfc.txt" -PassThru
        $sfcResult = Get-Content "$env:TEMP\sfc.txt" -Raw
        $sfcResult | Out-File -FilePath $logFile -Append
        Remove-Item "$env:TEMP\sfc.txt" -Force

        if ($sfcOutput.ExitCode -eq 0) {
            if ($sfcResult -match "Windows Resource Protection did not find any integrity violations") {
                $sfcStatus = "No issues found"
            } elseif ($sfcResult -match "Windows Resource Protection found corrupt files and successfully repaired them") {
                $sfcStatus = "Corrupt files repaired"
            } elseif ($sfcResult -match "Windows Resource Protection found corrupt files but was unable to fix some of them") {
                $sfcStatus = "Corrupt files found, some not repaired"
            } else {
                $sfcStatus = "SFC completed with unexpected result"
            }
        } else {
            $sfcStatus = "SFC failed (Exit Code: $($sfcOutput.ExitCode))"
        }

        $message = "DISM Result: $dismStatus`nSFC Result: $sfcStatus`nLog saved to: $logFile"
        if ($dismStatus -match "failed" -or $sfcStatus -match "not repaired|failed") {
            [System.Windows.Forms.MessageBox]::Show("$message`n`nReview the log for details. If issues persist, try specifying a Windows ISO as a source for DISM.", "Repair Completed with Issues")
            $statusBar.Text = "Repair completed with issues"
        } else {
            [System.Windows.Forms.MessageBox]::Show("$message", "Repair Completed Successfully")
            $statusBar.Text = "Windows repair completed"
        }
    } catch {
        $errorMsg = "Error during repair: $($_.Exception.Message)`nLog (if created): $logFile"
        [System.Windows.Forms.MessageBox]::Show($errorMsg, "Repair Error")
        $statusBar.Text = "Repair failed"
    }
})
$form.Controls.Add($repairButton)

# Network Status button
$networkButton = New-StyledButton -X 250 -Y 125 -Text "Network Status" -Color ([System.Drawing.Color]::FromArgb(255,87,34))
$networkButton.Add_Click({
    $statusBar.Text = "Checking network..."
    $status = Test-Connection google.com -Count 2 -ErrorAction SilentlyContinue
    if ($status) {
        [System.Windows.Forms.MessageBox]::Show("Network: Connected`nPing: $($status[0].ResponseTime)ms", "Network Status")
    } else {
        [System.Windows.Forms.MessageBox]::Show("Network: Disconnected", "Network Status")
    }
    $statusBar.Text = "Network status checked"
})
$form.Controls.Add($networkButton)

# Clean Tool button (opens cleanmgr.exe)
$cleanToolButton = New-StyledButton -X 50 -Y 190 -Text "Clean Tool" -Color ([System.Drawing.Color]::FromArgb(46,125,50))
$cleanToolButton.Add_Click({
    $statusBar.Text = "Opening Disk Cleanup..."
    try {
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/D C:"
        $statusBar.Text = "Disk Cleanup opened"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error opening Disk Cleanup: $($_.Exception.Message)", "Clean Tool Error")
        $statusBar.Text = "Clean Tool failed"
    }
})
$form.Controls.Add($cleanToolButton)

# Check for Updates button
$updateButton = New-StyledButton -X 250 -Y 190 -Text "Check for Updates" -Color ([System.Drawing.Color]::FromArgb(2,136,209))
$updateButton.Add_Click({
    $statusBar.Text = "Checking for updates..."
    $form.Refresh()
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
        if ($searchResult.Updates.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No updates available.", "Update Check")
        } else {
            $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($update in $searchResult.Updates) {
                $updatesToInstall.Add($update)
            }
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $updatesToInstall
            $installResult = $installer.Install()
            [System.Windows.Forms.MessageBox]::Show("Updates installed: $($updatesToInstall.Count)`nReboot may be required.", "Update Complete")
        }
        $statusBar.Text = "Update check completed"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error checking updates: $($_.Exception.Message)", "Update Error")
        $statusBar.Text = "Update check failed"
    }
})
$form.Controls.Add($updateButton)

# Credits button
$creditsButton = New-StyledButton -X 50 -Y 255 -Text "Credits" -Color ([System.Drawing.Color]::FromArgb(100,100,100))
$creditsButton.Add_Click({
    $creditsForm = New-Object System.Windows.Forms.Form
    $creditsForm.Size = New-Object System.Drawing.Size(300,300)
    $creditsForm.StartPosition = "CenterScreen"
    $creditsForm.BackColor = [System.Drawing.Color]::FromArgb(18,18,22)
    $creditsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $creditsForm.MaximizeBox = $false

    $creditsToolbar = New-Object System.Windows.Forms.Panel
    $creditsToolbar.Size = New-Object System.Drawing.Size(300,40)
    $creditsToolbar.BackColor = [System.Drawing.Color]::FromArgb(30,30,38)
    $creditsForm.Controls.Add($creditsToolbar)

    $creditsTitleLabel = New-Object System.Windows.Forms.Label
    $creditsTitleLabel.Location = New-Object System.Drawing.Point(10,8)
    $creditsTitleLabel.Size = New-Object System.Drawing.Size(240,24)
    $creditsTitleLabel.Text = "Credits"
    $creditsTitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(200,200,200)
    $creditsTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
    $creditsToolbar.Controls.Add($creditsTitleLabel)

    $creditsCloseButton = New-Object System.Windows.Forms.Button
    $creditsCloseButton.Location = New-Object System.Drawing.Point(265,5)
    $creditsCloseButton.Size = New-Object System.Drawing.Size(30,30)
    $creditsCloseButton.Text = "X"
    $creditsCloseButton.BackColor = [System.Drawing.Color]::FromArgb(198,40,40)
    $creditsCloseButton.ForeColor = [System.Drawing.Color]::White
    $creditsCloseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $creditsCloseButton.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $creditsCloseButton.FlatAppearance.BorderSize = 0
    $creditsCloseButton.Add_Click({ $creditsForm.Close() })
    $creditsToolbar.Controls.Add($creditsCloseButton)

    if ($global:avatarImage) {
        $pictureBox = New-Object System.Windows.Forms.PictureBox
        $pictureBox.Location = New-Object System.Drawing.Point(100,50)
        $pictureBox.Size = New-Object System.Drawing.Size(100,100)
        $pictureBox.Image = $global:avatarImage
        $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $creditsForm.Controls.Add($pictureBox)
    }

    $creditsLabel = New-Object System.Windows.Forms.Label
    $creditsLabel.Location = New-Object System.Drawing.Point(10,160)
    $creditsLabel.Size = New-Object System.Drawing.Size(280,40)
    $creditsLabel.Text = "Made by @CollinBeurskens"
    $creditsLabel.ForeColor = [System.Drawing.Color]::FromArgb(180,180,180)
    $creditsLabel.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Regular)
    $creditsLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $creditsForm.Controls.Add($creditsLabel)

    $githubButton = New-StyledButton -X 60 -Y 210 -Text "Visit GitHub" -Color ([System.Drawing.Color]::FromArgb(36,41,46)) -Width 180 -Height 40
    $githubButton.Add_Click({
        try {
            Start-Process "https://github.com/CollinBeurskens"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error opening GitHub: $($_.Exception.Message)", "Error")
        }
    })
    $creditsForm.Controls.Add($githubButton)

    $creditsForm.ShowDialog()
})
$form.Controls.Add($creditsButton)

# Activate Windows/Office button (using MAS)
$activateButton = New-StyledButton -X 250 -Y 255 -Text "Activate Windows/Office" -Color ([System.Drawing.Color]::FromArgb(255,87,34))
$activateButton.Add_Click({
    $statusBar.Text = "Launching Microsoft Activation Scripts (MAS)..."
    try {
        # Download and run MAS using the online method (PowerShell one-liner as per massgrave.dev)
        $masUrl = "https://massgrave.dev/get"
        Invoke-Expression (Invoke-RestMethod $masUrl)
        [System.Windows.Forms.MessageBox]::Show("MAS launched successfully. Follow the on-screen instructions to activate Windows or Office.", "MAS Activation")
        $statusBar.Text = "MAS activation launched"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error launching MAS: $($_.Exception.Message)`nEnsure you have an internet connection and run as Administrator.", "Activation Error")
        $statusBar.Text = "MAS activation failed"
    }
})
$form.Controls.Add($activateButton)

# Exit button (moved to new position)
$exitButton = New-StyledButton -X 150 -Y 320 -Text "Exit" -Color ([System.Drawing.Color]::FromArgb(198,40,40))
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Status bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Location = New-Object System.Drawing.Point(0,378)
$statusBar.Size = New-Object System.Drawing.Size(480,22)
$statusBar.Text = "Ready"
$statusBar.ForeColor = [System.Drawing.Color]::FromArgb(180,180,180)
$statusBar.BackColor = [System.Drawing.Color]::FromArgb(30,30,38)
$statusBar.Font = New-Object System.Drawing.Font("Segoe UI",9)
$form.Controls.Add($statusBar)

# Clean up avatar image when main form closes
$form.Add_FormClosed({
    if ($global:avatarImage) {
        $global:avatarImage.Dispose()
        $global:avatarImage = $null
    }
    if (Test-Path $tempImagePath) {
        Remove-Item $tempImagePath -Force
    }
})

# Show the form
$form.ShowDialog()