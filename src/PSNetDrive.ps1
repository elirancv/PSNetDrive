# PSNetDrive.ps1 - Network Drive Management Script
#Requires -Version 5.1
#Requires -RunAsAdministrator

# Override PowerShell's built-in help system
$PSDefaultParameterValues = @{
    'Get-Help:Full' = $false
    'Get-Help:Detailed' = $false
    'Get-Help:Examples' = $false
}

<#
.SYNOPSIS
    PSNetDrive - CLI tool for managing network drive connections.
.DESCRIPTION
    PSNetDrive provides a command-line interface for managing network drives with operations like:
    - Connect single or all drives
    - Disconnect single or all drives
    - Reconnect (refresh) drives
    - List current connections
    - Test connection status
.NOTES
    Version:        1.0.0
    Author:         [Your Name]
    Creation Date:  2024-04-05
    License:        MIT
    Requirements:   Windows OS, PowerShell 5.1+, Admin rights
    Project:        https://github.com/yourusername/PSNetDrive
.EXAMPLE
    .\PSNetDrive.ps1 -Connect All
    .\PSNetDrive.ps1 -Connect S
    .\PSNetDrive.ps1 -Disconnect M
    .\PSNetDrive.ps1 -List
    .\PSNetDrive.ps1 -Status
    .\PSNetDrive.ps1 -Reconnect All
#>

# Function to show command-specific help
function Show-CommandHelp {
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    $helpText = switch ($Command) {
        'Connect' {
@"
Connect Network Drive(s)

Usage:
    .\PSNetDrive.ps1 Connect <drive|All> [-y]

Parameters:
    <drive>  Drive letter to connect (A-Z)
    All      Connect all configured drives
    -y       Automatic yes to prompts

Examples:
    .\PSNetDrive.ps1 Connect S      # Connect S: drive
    .\PSNetDrive.ps1 Connect All -y # Connect all drives without prompting
"@
        }
        'Disconnect' {
@"
Disconnect Network Drive(s)

Usage:
    .\PSNetDrive.ps1 Disconnect <drive|All> [-y]

Parameters:
    <drive>  Drive letter to disconnect (A-Z)
    All      Disconnect all network drives
    -y       Automatic yes to prompts

Examples:
    .\PSNetDrive.ps1 Disconnect M      # Disconnect M: drive
    .\PSNetDrive.ps1 Disconnect All -y # Disconnect all drives without prompting
"@
        }
        'Reconnect' {
@"
Reconnect Network Drive(s)

Usage:
    .\PSNetDrive.ps1 Reconnect <drive|All> [-y]

Parameters:
    <drive>  Drive letter to reconnect (A-Z)
    All      Reconnect all configured drives
    -y       Automatic yes to prompts

Examples:
    .\PSNetDrive.ps1 Reconnect T      # Reconnect T: drive
    .\PSNetDrive.ps1 Reconnect All -y # Reconnect all drives without prompting
"@
        }
        'List' {
@"
List Network Drives

Usage:
    .\PSNetDrive.ps1 List

Description:
    Shows all currently connected network drives with their paths and status.

Example:
    .\PSNetDrive.ps1 List
"@
        }
        'Status' {
@"
Show Network Drive Status

Usage:
    .\PSNetDrive.ps1 Status

Description:
    Shows detailed connection status for all configured network drives,
    including whether they are connected and accessible.

Example:
    .\PSNetDrive.ps1 Status
"@
        }
    }

    Write-Host $helpText -ForegroundColor Cyan
}

# Function to show general help
function Show-Help {
    Write-Host @"
PSNetDrive CLI

Usage:
    .\PSNetDrive.ps1 <command> [options]

Commands:
    Connect <drive|All>    Connect specified drive letter or all drives from .env
    Disconnect <drive|All> Disconnect specified drive letter or all network drives
    Reconnect <drive|All>  Reconnect (refresh) specified drive or all drives
    List                   List all currently connected network drives
    Status                 Show connection status of all configured drives
    Help                   Show this help message

Options:
    -y                     Automatic yes to prompts (no confirmation needed)

For command-specific help, use: .\PSNetDrive.ps1 <command> -?

Examples:
    .\PSNetDrive.ps1 Connect All -y     # Connect all drives without prompting
    .\PSNetDrive.ps1 Connect S          # Connect specific drive (S:)
    .\PSNetDrive.ps1 Disconnect M -y    # Disconnect specific drive (M:)
    .\PSNetDrive.ps1 Disconnect All -y  # Disconnect all network drives without prompting
    .\PSNetDrive.ps1 List               # List current connections
    .\PSNetDrive.ps1 Status             # Show connection status
    .\PSNetDrive.ps1 Reconnect All -y   # Reconnect all drives without prompting

"@ -ForegroundColor Cyan
}

# Parse command line arguments
$Command = $args[0]
$Drive = $args[1]
$y = $args -contains '-y'

# Show help if no parameters or help requested
if (-not $Command -or $Command -eq 'Help' -or $args -contains '-?' -or $args -contains '?' -or $args -contains '-help' -or $args -contains '--help') {
    if ($Command -and $Command -ne 'Help' -and $Command -in @('Connect', 'Disconnect', 'Reconnect', 'List', 'Status')) {
        Show-CommandHelp -Command $Command
        exit 0
    }
    Show-Help
    exit 0
}

# Validate command
$validCommands = @('Connect', 'Disconnect', 'Reconnect', 'List', 'Status', 'Help')
if ($Command -notin $validCommands) {
    Write-Error "Invalid command: $Command"
    Show-Help
    exit 1
}

# Validate drive letter if required
$validDrives = @('All') + (65..90 | ForEach-Object { [char]$_ }) # A-Z
if ($Command -in @('Connect', 'Disconnect', 'Reconnect')) {
    if (-not $Drive) {
        Write-Error "Drive letter or 'All' required for $Command command"
        Show-CommandHelp -Command $Command
        exit 1
    }
    if ($Drive -notin $validDrives) {
        Write-Error "Invalid drive letter: $Drive. Must be a single letter (A-Z) or 'All'"
        Show-CommandHelp -Command $Command
        exit 1
    }
}

# Import core functionality
$coreScript = Join-Path $PSScriptRoot "PSNetDrive.Core.ps1"
if (-not (Test-Path $coreScript)) {
    Write-Error "Core script not found: $coreScript"
    Show-Help
    exit 1
}
. $coreScript

# Verify .env file exists
$envPath = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
if (-not (Test-Path $envPath)) {
    Write-Error "Configuration file .env not found. Please copy .env.example to .env and configure your shares."
    Show-Help
    exit 1
}

# Function to get specific share config
function Get-ShareConfig {
    param (
        [Parameter(Mandatory)]
        [string]$DriveLetter
    )
    
    if ($DriveLetter -notmatch '^[A-Z]$') {
        Write-Error "Invalid drive letter format: $DriveLetter"
        return $null
    }
    
    $configs = Get-ShareConfiguration
    if (-not $configs) {
        Write-Warning "No valid configurations found in .env file"
        return $null
    }
    
    $config = $configs | Where-Object { $_.Name -eq $DriveLetter }
    if (-not $config) {
        Write-Warning "No configuration found for drive $DriveLetter"
    }
    return $config
}

# Function to list network drives
function Show-NetworkDrives {
    Write-Host "`nCurrently Connected Network Drives:" -ForegroundColor Yellow
    $drives = Get-CimInstance Win32_NetworkConnection | 
        Where-Object { $_.Status -eq 'OK' -and $_.RemoteName -notlike '*\IPC$' } |
        Select-Object @{N='Name';E={$_.LocalName.TrimEnd(':')}}, 
                    @{N='Path';E={$_.RemoteName}},
                    @{N='Status';E={$_.Status}}
    
    if ($drives) {
        $drives | Format-Table -AutoSize
    } else {
        Write-Host "No network drives currently connected." -ForegroundColor Gray
    }
}

# Function to show connection status
function Show-ConnectionStatus {
    Write-Host "`nNetwork Drive Connection Status:" -ForegroundColor Yellow
    $configs = Get-ShareConfiguration
    $currentDrives = Get-CimInstance Win32_NetworkConnection | 
        Where-Object { $_.RemoteName -notlike '*\IPC$' } |
        Select-Object LocalName, RemoteName, @{N='Connected';E={$_.Status -eq 'OK'}}

    # Test all servers at once for efficiency
    $servers = $configs | ForEach-Object { ($_.Path -split '\\')[2] } | Select-Object -Unique
    Write-Host "Checking server connectivity..." -ForegroundColor Gray
    $serverStatus = @{}
    foreach ($server in $servers) {
        Write-Host "Testing connection to $server..." -ForegroundColor Gray
        try {
            $isReachable = Test-NetConnection -ComputerName $server -Port 445 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction Stop
            $serverStatus[$server] = $isReachable
        }
        catch {
            Write-Warning "Failed to test connection to $server : $_"
            $serverStatus[$server] = $false
        }
    }

    foreach ($config in $configs) {
        $server = ($config.Path -split '\\')[2]
        $driveLetter = "$($config.Name):"
        $driveStatus = $currentDrives | Where-Object { $_.LocalName -eq $driveLetter }
        
        $status = @{
            Drive = $config.Name
            Path = $config.Path
            Connected = [bool]$driveStatus.Connected
            Accessible = $serverStatus[$server]
        }

        # Display status with color coding
        $statusColor = if ($status.Connected -and $status.Accessible) { 'Green' }
                      elseif ($status.Accessible) { 'Yellow' }
                      else { 'Red' }

        $statusText = if ($status.Connected -and $status.Accessible) { "Connected & Accessible" }
                     elseif ($status.Connected) { "Connected but Server Inaccessible" }
                     elseif ($status.Accessible) { "Server Accessible but Drive Not Connected" }
                     else { "Server Not Accessible" }

        Write-Host "$($status.Drive): $($status.Path) - $statusText" -ForegroundColor $statusColor
    }
}

# Function to disconnect a network drive
function Disconnect-NetworkDrive {
    param (
        [Parameter(Mandatory)]
        [string]$DriveLetter
    )

    try {
        # First try to remove using net use
        $netOutput = net use "$DriveLetter`:" /delete /y 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully disconnected drive $DriveLetter"
            return $true
        }
        else {
            Write-Verbose "net use failed with output: $netOutput"
            # If net use fails, try Remove-PSDrive as fallback
            Remove-PSDrive -Name $DriveLetter -Force -ErrorAction Stop
            Write-Host "Successfully disconnected drive $DriveLetter (using Remove-PSDrive)"
            return $true
        }
    }
    catch {
        Write-Error "Failed to disconnect drive $DriveLetter : $_"
        return $false
    }
}

# Function to disconnect all network drives
function Disconnect-AllNetworkDrives {
    param(
        [switch]$AutoYes
    )

    # Get all network drives
    $networkDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*" -and $_.Name -ne "" }
    
    if ($networkDrives.Count -eq 0) {
        Write-Host "No network drives found to disconnect."
        return
    }

    Write-Host "Found $($networkDrives.Count) network drive(s) to disconnect:`n"
    $networkDrives | Format-Table Name, DisplayRoot

    if (-not $AutoYes) {
        $confirmation = Read-Host "`nDo you want to disconnect all these drives? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Host "Operation cancelled."
            return
        }
    }

    $successCount = 0
    foreach ($drive in $networkDrives) {
        if (Disconnect-NetworkDrive -DriveLetter $drive.Name) {
            $successCount++
        }
    }

    if ($successCount -eq $networkDrives.Count) {
        Write-Host "`nAll network drives have been disconnected."
    }
    else {
        Write-Host "`nDisconnected $successCount out of $($networkDrives.Count) network drives."
    }
}

# Main execution
try {
    # Handle each parameter set
    switch ($Command) {
        'Connect' {
            if ($Drive -eq 'All' -or (Get-ShareConfig -DriveLetter $Drive)) {
                $configs = if ($Drive -eq 'All') { 
                    Get-ShareConfiguration 
                } else { 
                    @(Get-ShareConfig -DriveLetter $Drive) 
                }
                Connect-NetworkShares -Configs $configs
            } else {
                Write-Error "Drive letter '$Drive' not found in configuration"
                Show-Help
                exit 1
            }
        }
        'Disconnect' {
            if ($Drive -eq 'All') {
                Disconnect-AllNetworkDrives -AutoYes:$y
            } else {
                # Check if the drive exists
                $existingDrive = Get-PSDrive -Name $Drive -ErrorAction SilentlyContinue
                if (-not $existingDrive) {
                    Write-Error "Drive $Drive`: is not connected"
                    exit 1
                }
                if ($existingDrive.DisplayRoot -notlike "\\*") {
                    Write-Error "Drive $Drive`: is not a network drive"
                    exit 1
                }
                Disconnect-NetworkDrive -DriveLetter $Drive
            }
        }
        'Reconnect' {
            if ($Drive -eq 'All' -or (Get-ShareConfig -DriveLetter $Drive)) {
                if ($Drive -eq 'All') {
                    Disconnect-AllNetworkDrives -AutoYes:$y
                } else {
                    # Check if the drive exists
                    $existingDrive = Get-PSDrive -Name $Drive -ErrorAction SilentlyContinue
                    if ($existingDrive) {
                        Disconnect-NetworkDrive -DriveLetter $Drive
                    }
                }
                Start-Sleep -Seconds 2  # Wait for disconnection
                $configs = if ($Drive -eq 'All') { 
                    Get-ShareConfiguration 
                } else { 
                    @(Get-ShareConfig -DriveLetter $Drive) 
                }
                Connect-NetworkShares -Configs $configs
            } else {
                Write-Error "Drive letter '$Drive' not found in configuration"
                Show-Help
                exit 1
            }
        }
        'List' {
            Show-NetworkDrives
        }
        'Status' {
            Show-ConnectionStatus
        }
    }
} catch {
    Write-Error $_.Exception.Message
    Show-Help
    exit 1
} 