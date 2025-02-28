Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SysUtil Installer"
$form.Size = New-Object System.Drawing.Size(500,200)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "SysUtil Installer"
$label.AutoSize = $true
$label.Font = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Bold)
$label.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($label)

# Create a checkbox for adding a shortcut
$shortcutCheckbox = New-Object System.Windows.Forms.CheckBox
$shortcutCheckbox.Text = "Add shortcut to Desktop"
$shortcutCheckbox.Location = New-Object System.Drawing.Point(20,60)
$shortcutCheckbox.AutoSize = $true
$shortcutCheckbox.Font = New-Object System.Drawing.Font("Arial",10)
$form.Controls.Add($shortcutCheckbox)

# Create an install button
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install"
$installButton.Location = New-Object System.Drawing.Point(200,100)
$installButton.Size = New-Object System.Drawing.Size(100,35)
$installButton.Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
$installButton.BackColor = [System.Drawing.Color]::LightBlue
$installButton.FlatStyle = 'Flat'
$installButton.Add_Click({
    $desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "SysUtil")
    if (!(Test-Path -Path $desktopPath)) {
        New-Item -ItemType Directory -Path $desktopPath | Out-Null
    }
    $installPath = Join-Path -Path $desktopPath -ChildPath "SysUtil.ps1"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/CollinBeurskens/SysUtil/refs/heads/main/SysUtil.ps1" -OutFile $installPath
    
    # Create a batch file to open SysUtil.ps1
    $batchFilePath = Join-Path -Path $desktopPath -ChildPath "RunSysUtil.bat"
    $batchContent = "@echo off`r`npowershell -ExecutionPolicy Bypass -File `"$installPath`""
    Set-Content -Path $batchFilePath -Value $batchContent
    
    # Create a shortcut if the checkbox is checked
    if ($shortcutCheckbox.Checked) {
        $shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "RunSysUtil.lnk")
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $batchFilePath
        $shortcut.Save()
    }
    
    [System.Windows.Forms.MessageBox]::Show("Installation Complete! Script saved to: $installPath", "Success", "OK", "Information")
    Start-Process explorer.exe -ArgumentList $desktopPath
    $form.Close()
})
$form.Controls.Add($installButton)

# Show the form
$form.ShowDialog()
