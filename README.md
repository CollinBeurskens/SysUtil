# System Utility Dashboard

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
- Internet access (for downloading avatar and checking updates)

## Installation
1. Download the script.
2. Ensure PowerShell execution policy allows running scripts:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ```
3. Run the script as an administrator.

## Usage
- Double-click the script to launch the GUI.
- Select the desired utility from the available buttons.
- Follow on-screen instructions for each feature.

## Notes
- The script automatically relaunches with administrative privileges if not already elevated.
- Log files are saved to the desktop for certain operations (e.g., system info, repair logs).
- The UI design includes a custom close button and a toolbar.

## Credits
- Developed by [Collin Beurskens](https://github.com/CollinBeurskens)
- Uses Windows PowerShell and .NET Framework for UI components.
