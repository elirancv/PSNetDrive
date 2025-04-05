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
    Author:         Your Name
    Creation Date:  $(Get-Date -Format 'yyyy-MM-dd')
#>

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
    return $Path -match '^\\\\[^\\]+\\[^\\]+$'
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
        [array]$Configs
    )

    # Group shares by server to optimize connectivity checks
    $serverGroups = $Configs | Group-Object { ($_.Path -split '\\')[2] }
    
    foreach ($group in $serverGroups) {
        $serverName = $group.Name
        Write-Host "Checking connection to server $serverName..." -ForegroundColor Cyan
        
        # Test server connectivity with retry
        $maxRetries = 3
        $retryCount = 0
        $isServerReachable = $false
        
        while (-not $isServerReachable -and $retryCount -lt $maxRetries) {
            try {
                $isServerReachable = Test-NetConnection -ComputerName $serverName -Port 445 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction Stop
                if ($isServerReachable) { break }
            }
            catch {
                Write-Warning "Attempt $($retryCount + 1) of $maxRetries to reach server $serverName failed"
            }
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Start-Sleep -Seconds (2 * $retryCount)  # Exponential backoff
            }
        }
        
        if (-not $isServerReachable) {
            Write-Warning "Cannot reach server $serverName after $maxRetries attempts - skipping related shares"
            continue
        }

        # Process all shares for this server
        foreach ($config in $group.Group) {
            try {
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
                        }
                    }
                }
            }
            catch {
                Write-Error "Error processing drive $($config.Name): $_"
            }
        }
    }
}

# Function to initialize and connect all shares
function Initialize-NetworkShares {
    $start = Get-Date
    Write-Host "Starting network drive connections..." -ForegroundColor Cyan

    # Get share configurations
    $shareConfigs = Get-ShareConfiguration
    if ($shareConfigs.Count -eq 0) {
        throw "No valid share configurations found"
    }

    # Connect shares in parallel
    Connect-NetworkShares -Configs $shareConfigs

    # List all connected drives
    Write-Host "`nCurrently Connected Network Drives:" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | 
        Where-Object { $_.DisplayRoot -like '\\*' } |
        Format-Table Name, DisplayRoot, Description

    $duration = (Get-Date) - $start
    Write-Host "`nOperation completed in $($duration.TotalSeconds) seconds" -ForegroundColor Green
} 