# PSNetDrive

<div align="center">
  <img src="docs/images/logo.svg" alt="PSNetDrive Logo" width="200"/>
  <p><em>PowerShell Network Drive Management Tool</em></p>
  
  [![License](https://img.shields.io/badge/license-MIT-blue.png)](docs/LICENSE)
  [![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D5.1-blue.png)](https://github.com/PowerShell/PowerShell)
  [![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.png)](https://www.microsoft.com/windows)
</div>

## Overview

PSNetDrive is a robust PowerShell-based command-line interface (CLI) tool designed for efficient management of network drive connections in Windows environments. It provides a comprehensive set of features for connecting, disconnecting, and monitoring network drives with enhanced reliability and user experience.

## Key Features

- **Intelligent Drive Management**: Connect, disconnect, or reconnect network drives with a single command
- **Bulk Operations**: Manage all configured drives simultaneously with the `All` parameter
- **Smart Connectivity Checks**: Automatically verifies server accessibility before attempting connections
- **Retry Mechanism**: Implements exponential backoff for reliable connections in unstable networks
- **Detailed Status Reporting**: Color-coded status information for quick visual assessment
- **Comprehensive Help System**: Command-specific help with detailed examples
- **Secure Credential Handling**: Support for both anonymous and authenticated shares
- **Non-Interactive Mode**: Use the `-y` flag for automated operations without prompts
- **Parallel Processing**: Optimized for connecting multiple drives efficiently
- **Robust Error Handling**: Detailed error messages and fallback mechanisms

## Requirements

- **Operating System**: Windows 10/11 or Windows Server 2016/2019/2022
- **PowerShell**: Version 5.1 or later
- **Permissions**: Administrator privileges
- **Network**: Access to the network shares you want to connect

## Installation

1. Clone this repository:
   ```powershell
   git clone https://github.com/elirancv/PSNetDrive.git
   cd PSNetDrive
   ```

2. Copy the example configuration file:
   ```powershell
   Copy-Item examples\.env.example .env
   ```

3. Edit the `.env` file with your network share configurations (see [Configuration](#configuration) section)

## Usage

```powershell
.\src\PSNetDrive.ps1 <command> [options]
```

### Commands

| Command | Description |
|---------|-------------|
| `Connect <drive\|All>` | Connect specified drive letter or all configured drives |
| `Disconnect <drive\|All>` | Disconnect specified drive letter or all network drives |
| `Reconnect <drive\|All>` | Reconnect (refresh) specified drive or all drives |
| `List` | Show currently connected network drives |
| `Status` | Show detailed connection status of all configured drives |
| `Help` | Display help information |

### Options

| Option | Description |
|--------|-------------|
| `-y` | Automatic yes to prompts (no confirmation needed) |

### Examples

```powershell
# Connect all drives without prompting
.\src\PSNetDrive.ps1 Connect All -y

# Connect specific drive (S:)
.\src\PSNetDrive.ps1 Connect S

# Disconnect specific drive without prompting
.\src\PSNetDrive.ps1 Disconnect M -y

# Disconnect all network drives
.\src\PSNetDrive.ps1 Disconnect All

# List current connections
.\src\PSNetDrive.ps1 List

# Show connection status
.\src\PSNetDrive.ps1 Status

# Reconnect all drives
.\src\PSNetDrive.ps1 Reconnect All -y

# Show help for specific command
.\src\PSNetDrive.ps1 Connect -?
```

## Configuration

The `.env` file uses a simple format for configuring network shares:

```
SHARE_NAME=DRIVE_LETTER|UNC_PATH|DESCRIPTION|USERNAME|PASSWORD
```

### Configuration Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `SHARE_NAME` | Unique identifier for the share | Yes |
| `DRIVE_LETTER` | Single letter (A-Z) to assign to the drive | Yes |
| `UNC_PATH` | Network path in the format `\\server\share` | Yes |
| `DESCRIPTION` | Brief description of the share | No |
| `USERNAME` | Domain username for authentication | No |
| `PASSWORD` | Password for authentication | No |

### Example Configuration

```powershell
# Network Share by IP (Anonymous)
PUBLIC=P|\\192.168.1.100\public|Public Share||

# Network Share by IP (Domain Auth)
DEPT=D|\\192.168.1.101\department|Department Files|%USERDOMAIN%\%USERNAME%|

# Network Share by IP (Local Auth)
DATA=S|\\10.0.0.50\data|Data Files|localuser|password123

# Network Share by Hostname
TEAM=T|\\fileserver\team|Team Files|domain\username|

# Multiple shares on same server
DOCS=M|\\192.168.1.100\documents|Documents||
APPS=A|\\192.168.1.100\applications|Applications||
```

## Advanced Features

### Retry Mechanism

PSNetDrive implements a sophisticated retry mechanism with exponential backoff:

- Automatically retries failed connections up to 3 times
- Increases delay between retries (2s, 4s, 6s)
- Provides detailed status messages during retry attempts

### Server Connectivity Verification

Before attempting to connect to a drive, PSNetDrive:

1. Verifies server accessibility using `Test-NetConnection`
2. Groups shares by server to minimize connectivity checks
3. Provides clear status messages about server accessibility

### Drive Existence Handling

When connecting a drive, PSNetDrive:

1. Checks if the drive already exists
2. Verifies if it points to the same path
3. Removes and reconnects if it points to a different path
4. Provides clear status messages about existing drives

## Security Considerations

- **Credential Handling**: Credentials are stored in the `.env` file and should be kept secure
- **Administrator Privileges**: The script requires administrator privileges to manage network drives
- **Secure Connection Methods**: Uses standard Windows networking protocols with proper authentication
- **Validation**: Validates server accessibility and drive configurations before attempting connections
- **Error Handling**: Provides detailed error messages without exposing sensitive information

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Drive letter not found in configuration" | Ensure the drive letter is correctly configured in the `.env` file |
| "Cannot reach server" | Verify network connectivity and server availability |
| "Access is denied" | Ensure you have proper permissions to access the share |
| "Drive is already connected" | Use the `Reconnect` command to refresh the connection |

### Debugging

For detailed debugging information, run the script with the `-Verbose` parameter:

```powershell
.\src\PSNetDrive.ps1 Connect All -Verbose
```

## Performance Optimization

PSNetDrive is optimized for performance:

- **Server Grouping**: Groups shares by server to minimize connectivity checks
- **Parallel Processing**: Processes multiple shares efficiently
- **Minimal Dependencies**: Uses only built-in PowerShell cmdlets
- **Efficient Validation**: Validates configurations before attempting connections

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

PSNetDrive includes comprehensive tests using Pester:

```powershell
# Install Pester if not already installed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests
Invoke-Pester -Path .\tests
```

## License

This project is licensed under the MIT License - see the [LICENSE](docs/LICENSE) file for details.

## Roadmap

- [ ] Support for Azure File Shares
- [ ] Integration with Windows Credential Manager
- [ ] GUI interface option
- [ ] Scheduled connection management
- [ ] Connection history and logging

---

<div align="center">
  <p>Made with ❤️ by <a href="https://github.com/elirancv">elirancv</a></p>
</div>