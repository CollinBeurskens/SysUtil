# System Utility Dashboard

# Quick Disclaimer!
On my [website](https://sysutil.netlify.app/) it stays up to date. Im not willing to update it each time on this github page.

## Overview
This PowerShell script provides a graphical user interface (GUI) for various system utilities, including system information retrieval, disk space checking, Windows repair, network status, disk cleanup, and update checking.

![image alt](https://github.com/CollinBeurskens/SysUtil/blob/584249fc9b9cabd2f5dfae9fabbb5296671abbbf/screenshot.png)

## Features
- **System Info**: Retrieves and saves system details to a text file.
- **Check Disk Space**: Displays disk health, used, and free space.
- **Repair Windows**: Runs DISM and SFC scans to fix system integrity issues.
- **Network Status**: Checks internet connectivity.
- **Clean Tool**: Opens Windows Disk Cleanup.
- **Check for Updates**: Searches for and installs pending Windows updates.
- **Custom UI**: Styled interface.

## Requirements
- Windows operating system
- PowerShell with administrative privileges
- Internet access (obviously)

## Installation
1. Open Powershell (With Adminstrator Permissions)
2. Run this command!
   ```Powershell
   iwr https://raw.githubusercontent.com/CollinBeurskens/SysUtil/refs/heads/main/install.ps1 | iex
   ```
4. Your all set!

## Other Installation Options
This command only downloads the needed script for this program (NO INSTALLER, NO SHORTCUT, NO SPECIAL DIRECTORY and downloads to desktop!)
```Powershell
iwr "https://raw.githubusercontent.com/CollinBeurskens/SysUtil/refs/heads/main/SysUtil.ps1" -OutFile "$([System.Environment]::GetFolderPath('Desktop'))\SysUtil.ps1"
```

## Memory Installation
This doesn't actually install it instead it stores it in the memory. So this wont take up any storage at all.
```Powershell
iwr https://raw.githubusercontent.com/CollinBeurskens/SysUtil/refs/heads/main/SysUtil.ps1 | iex
```

## Notes
- The script automatically relaunches with administrative privileges if not already elevated.
- Log files are saved to the desktop for certain operations (e.g., system info, repair logs).

## Credits
- Developed by [Collin Beurskens](https://github.com/CollinBeurskens)
- Uses Windows PowerShell and .NET Framework for UI components.
