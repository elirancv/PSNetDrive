# PSNetDrive

<div align="center">
  <img src="docs/images/logo.svg" alt="PSNetDrive Logo" width="200"/>
  <p><em>PowerShell Network Drive Management Tool</em></p>
  
  [![License](https://img.shields.io/badge/license-MIT-blue.png)](docs/LICENSE)
  [![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D5.1-blue.png)](https://github.com/PowerShell/PowerShell)
  [![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.png)](https://www.microsoft.com/windows)
</div>

## Overview

PSNetDrive is a PowerShell CLI tool for managing network drive connections in Windows environments. It provides a simple interface for connecting, disconnecting, and monitoring network drives with features like parallel processing, retry mechanisms, and secure credential handling.

## Quick Start

1. **Install**
   ```powershell
   git clone https://github.com/elirancv/PSNetDrive.git
   cd PSNetDrive
   Copy-Item examples\.env.example .env
   ```

2. **Configure** - Edit `.env` with your network shares:
   ```
   SHARE_NAME=DRIVE_LETTER|UNC_PATH|DESCRIPTION|USERNAME|PASSWORD
   ```

3. **Use**
   ```powershell
   # Connect all drives
   .\src\PSNetDrive.ps1 Connect All

   # Connect specific drive
   .\src\PSNetDrive.ps1 Connect S

   # List current connections
   .\src\PSNetDrive.ps1 List
   ```

## Features

- **Drive Management**: Connect, disconnect, or reconnect network drives
- **Bulk Operations**: Manage all configured drives with `All` parameter
- **Smart Connectivity**: Server accessibility verification before connections
- **Retry Mechanism**: Exponential backoff for reliable connections
- **Parallel Processing**: Efficient handling of multiple drives
- **Secure Credentials**: Support for authenticated shares
- **Non-Interactive Mode**: Use `-y` flag for automated operations

## Requirements

- Windows 10/11 or Windows Server 2016/2019/2022
- PowerShell 5.1+
- Network access to target shares

## Configuration

The `.env` file uses a simple format:
```
SHARE_NAME=DRIVE_LETTER|UNC_PATH|DESCRIPTION|USERNAME|PASSWORD
```

Example:
```
# Anonymous share
PUBLIC=P|\\192.168.1.100\public|Public Share||

# Authenticated share
DATA=S|\\10.0.0.50\data|Data Files|domain\user|password
```

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `Connect <drive\|All>` | Connect drive(s) | `Connect All -y` |
| `Disconnect <drive\|All>` | Disconnect drive(s) | `Disconnect M` |
| `Reconnect <drive\|All>` | Refresh connection(s) | `Reconnect All` |
| `List` | Show connections | `List` |
| `Status` | Check drive status | `Status` |

## Security

- Credentials stored in `.env` file (keep secure)
- Standard Windows networking protocols
- No administrator privileges required
- Detailed error handling without exposing sensitive data

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

MIT License - see [LICENSE](docs/LICENSE) for details.

---

<div align="center">
  <p>Made with ❤️ by <a href="https://github.com/elirancv">elirancv</a></p>
</div>