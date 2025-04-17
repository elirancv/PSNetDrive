#Requires -Version 5.1
<#
.SYNOPSIS
    Connects network drives using configurations from a .env file.
.DESCRIPTION
    This script provides functionality to connect network drives with support for:
    - Multiple share configurations from .env file
    - Secure credential handling
    - Error handling and logging
    - Status reporting
    - Both temporary and persistent connections
.NOTES
    Version:        1.0
    Author:         elirancv
    Creation Date:  2025-04-05
#>

# Set maximum number of retry attempts for connections
$maxRetries = 3

# Function to validate drive letter format
function Test-DriveLetter {
    param (
        [Parameter(Mandatory)]
        [string]$DriveLetter
    )
    return $DriveLetter -cmatch '^[A-Z]$'  # Use -cmatch for case-sensitive matching
}

# Function to validate network path format
function Test-NetworkPathFormat {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Support both UNC paths and WebDAV URLs
    return ($Path -match '^\\\\[^\\]+\\[^\\]+$') -or ($Path -match '^https?://[^/]+/.*$')
}

# Function to determine if a path is WebDAV
function Test-IsWebDAV {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    return $Path -match '^https?://'
}

# Function to read and parse .env file
function Get-ShareConfiguration {
    [CmdletBinding()]
    param()
    
    $envPath = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
    if (-not (Test-Path $envPath)) {
        Write-Error "Configuration file .env not found!"
        return @()
    }

    $configs = @()
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.+)$') {
            $shareName = $matches[1].Trim()
            $values = $matches[2].Split('|')
            if ($values.Count -ge 5) {
                # Only create credential if username is provided
                $credential = $null
                if ($values[3].Trim()) {
                    $credential = New-Object System.Management.Automation.PSCredential(
                        $values[3].Trim(),
                        (ConvertTo-SecureString $values[4].Trim() -AsPlainText -Force)
                    )
                }
                
                $configs += @{
                    Name = $values[0].Trim()  # Drive letter
                    Path = $values[1].Trim()  # UNC path
                    Description = $values[2].Trim()  # Description
                    Persist = $true
                    Credential = $credential
                    ShareName = $shareName  # Store the share name for reference
                }
            }
        }
    }
    return $configs
}

# Function to connect network shares in parallel
function Connect-NetworkShares {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [array]$Configs,
        
        [Parameter()]
        [switch]$AutoYes
    )

    # If there are multiple drives to connect and AutoYes is not set, ask for confirmation
    if ($Configs.Count -gt 1 -and -not $AutoYes) {
        Write-Host "Found $($Configs.Count) network drive(s) to connect:`n"
        
        # Create a table of drives to connect
        $drivesToConnect = $Configs | Select-Object @{N='Drive';E={$_.Name}}, @{N='Path';E={$_.Path}}, @{N='Type';E={if (Test-IsWebDAV $_.Path) { 'WebDAV' } else { 'SMB' }}}, @{N='Description';E={$_.Description}}
        $drivesToConnect | Format-Table Drive, Path, Type, Description -AutoSize | Out-String | Write-Host
        
        $confirmation = Read-Host "`nDo you want to connect all these drives? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Host "Operation cancelled."
            return $false
        }
    }

    $success = $true
    foreach ($config in $Configs) {
        try {
            if (Test-IsWebDAV $config.Path) {
                # WebDAV connection
                Write-Host "Connecting to WebDAV share at $($config.Path)..." -ForegroundColor Cyan
                
                # Check if drive already exists
                $existingDrive = Get-PSDrive -Name $config.Name -ErrorAction SilentlyContinue
                if ($existingDrive) {
                    # Check if it's the same path
                    if ($existingDrive.DisplayRoot -eq $config.Path) {
                        Write-Host "Drive $($config.Name): already connected to $($config.Path)" -ForegroundColor Yellow
                        continue
                    }
                    else {
                        Write-Host "Drive $($config.Name): exists but points to different path. Removing..." -ForegroundColor Yellow
                        # Use net use to remove the drive
                        $netUse = New-Object System.Diagnostics.ProcessStartInfo
                        $netUse.FileName = "net.exe"
                        $netUse.Arguments = "use $($config.Name): /delete /y"
                        $netUse.UseShellExecute = $false
                        $netUse.RedirectStandardOutput = $true
                        $netUse.RedirectStandardError = $true
                        $netUse.CreateNoWindow = $true
                        
                        $process = New-Object System.Diagnostics.Process
                        $process.StartInfo = $netUse
                        $process.Start() | Out-Null
                        $process.WaitForExit()
                        
                        # Wait a moment for the drive to be fully released
                        Start-Sleep -Seconds 2
                    }
                }
                
                # Map the WebDAV drive using net use
                $netUse = New-Object System.Diagnostics.ProcessStartInfo
                $netUse.FileName = "net.exe"
                $netUse.Arguments = "use $($config.Name): `"$($config.Path)`""
                
                # Add credentials if provided
                if ($config.Credential) {
                    $username = $config.Credential.UserName
                    $password = $config.Credential.GetNetworkCredential().Password
                    $netUse.Arguments += " /user:$username $password"
                }
                
                $netUse.UseShellExecute = $false
                $netUse.RedirectStandardOutput = $true
                $netUse.RedirectStandardError = $true
                $netUse.CreateNoWindow = $true
                
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $netUse
                $process.Start() | Out-Null
                $errorOutput = $process.StandardError.ReadToEnd()
                $process.WaitForExit()
                
                if ($process.ExitCode -ne 0) {
                    Write-Error "Failed to map WebDAV drive $($config.Name): $errorOutput"
                    $success = $false
                } else {
                    # Verify the connection is working
                    $testPath = Join-Path -Path "$($config.Name):" -ChildPath "."
                    if (Test-Path -Path $testPath -ErrorAction Stop) {
                        Write-Host "Successfully connected WebDAV drive $($config.Name) to $($config.Path)" -ForegroundColor Green
                    } else {
                        Write-Error "WebDAV drive $($config.Name) connected but path is not accessible"
                        $success = $false
                    }
                }
            } else {
                # SMB connection (existing code)
                # Check if drive already exists
                $existingDrive = Get-PSDrive -Name $config.Name -ErrorAction SilentlyContinue
                if ($existingDrive) {
                    # Check if it's the same path
                    if ($existingDrive.DisplayRoot -eq $config.Path) {
                        Write-Host "Drive $($config.Name): already connected to $($config.Path)" -ForegroundColor Yellow
                        continue
                    }
                    else {
                        Write-Host "Drive $($config.Name): exists but points to different path. Removing..." -ForegroundColor Yellow
                        Remove-PSDrive -Name $config.Name -Force -ErrorAction Stop
                    }
                }

                # Prepare connection parameters
                $params = @{
                    Name = $config.Name
                    PSProvider = 'FileSystem'
                    Root = $config.Path
                    Description = $config.Description
                    Scope = 'Global'
                    Persist = $true
                    ErrorAction = 'Stop'
                }

                # Handle credentials
                if ($config.Credential) {
                    $params['Credential'] = $config.Credential
                }

                # Try to connect with retry
                $driveConnected = $false
                $retryCount = 0
                
                while (-not $driveConnected -and $retryCount -lt $maxRetries) {
                    try {
                        Write-Host "Attempting to connect drive $($config.Name) to $($config.Path) (Attempt $($retryCount + 1) of $maxRetries)..." -ForegroundColor Cyan
                        $null = New-PSDrive @params
                        $driveConnected = $true
                        
                        # Verify the connection is working
                        $testPath = Join-Path -Path "$($config.Name):" -ChildPath "."
                        if (-not (Test-Path -Path $testPath -ErrorAction Stop)) {
                            throw "Drive connected but path is not accessible"
                        }
                        
                        Write-Host "Successfully connected drive $($config.Name) to $($config.Path)" -ForegroundColor Green
                    }
                    catch {
                        $retryCount++
                        if ($retryCount -lt $maxRetries) {
                            Write-Warning "Attempt $retryCount of $maxRetries to connect drive $($config.Name) failed: $_"
                            Start-Sleep -Seconds (2 * $retryCount)
                            # Clean up failed connection attempt
                            Remove-PSDrive -Name $config.Name -Force -ErrorAction SilentlyContinue
                        }
                        else {
                            Write-Error "Failed to connect drive $($config.Name) after $maxRetries attempts: $_"
                            $success = $false
                        }
                    }
                }
            }
        } catch {
            Write-Error "Failed to connect drive $($config.Name): $_"
            $success = $false
        }
    }
    return $success
}

# Function to initialize and connect all shares
function Initialize-NetworkShares {
    param(
        [switch]$AutoYes
    )
    
    $start = Get-Date
    Write-Host "Starting network drive connections..." -ForegroundColor Cyan

    # Get share configurations
    $shareConfigs = Get-ShareConfiguration
    if ($shareConfigs.Count -eq 0) {
        throw "No valid share configurations found"
    }

    # Connect shares in parallel
    Connect-NetworkShares -Configs $shareConfigs -AutoYes:$AutoYes

    # List all connected drives
    Write-Host "`nCurrently Connected Network Drives:" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | 
        Where-Object { $_.DisplayRoot -like '\\*' } |
        Format-Table Name, DisplayRoot, Description

    $duration = (Get-Date) - $start
    Write-Host "`nOperation completed in $($duration.TotalSeconds) seconds" -ForegroundColor Green
} 