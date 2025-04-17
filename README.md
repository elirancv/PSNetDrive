# PSNetDrive

<div align="center">
  <img src="docs/images/logo.svg" alt="PSNetDrive Logo" width="200"/>
  <h3>🚀 Supercharge Your Network Drive Management</h3>
  
  [![License](https://img.shields.io/badge/license-MIT-blue.png)](docs/LICENSE)
  [![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D5.1-blue.png)](https://github.com/PowerShell/PowerShell)
  [![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.png)](https://www.microsoft.com/windows)
  [![Windows Server](https://img.shields.io/badge/Windows%20Server-2016%2F2019%2F2022-blue.png)](https://www.microsoft.com/windows-server)
  [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/elirancv/PSNetDrive/graphs/commit-activity)
</div>

<p align="center">
  <b>PSNetDrive</b> is a powerful PowerShell CLI tool that revolutionizes network drive management in Windows environments. Say goodbye to manual drive mapping and hello to automated, secure, and efficient network drive operations.
</p>

<p align="center">
  <a href="#-key-features">Key Features</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-configuration">Configuration</a> •
  <a href="#-security">Security</a> •
  <a href="#-contributing">Contributing</a>
</p>

## ✨ Key Features

- **Smart Connectivity** - Verifies server accessibility before attempting connections
- **Parallel Processing** - Efficiently handles multiple drives simultaneously
- **Secure Credentials** - Built-in support for authenticated shares
- **Automation Ready** - Perfect for scripts with non-interactive mode
- **Retry Mechanism** - Exponential backoff for reliable connections
- **Status Monitoring** - Real-time connection status and server accessibility
- **WebDAV Support** - Connect to WebDAV shares with the same ease as network shares
- **Connection Verification** - Validates both SMB and WebDAV connections before completing

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 or Windows Server 2016/2019/2022
- PowerShell 5.1 or higher
- Network access to target shares
- WebDAV client support (built into Windows)
- For WebDAV: Valid SSL certificate or proper certificate validation configuration

### Installation
```powershell
# Clone the repository
git clone https://github.com/elirancv/PSNetDrive.git

# Navigate to the project
cd PSNetDrive

# Create your configuration
Copy-Item examples\.env.example .env

# Move to source directory
cd src
```

## 🔧 Configuration

Configure your network shares in `.env`:

```ini
# SMB/CIFS share examples
PUBLIC=P|\\192.168.1.100\public|Public Share||
DATA=S|\\10.0.0.50\data|Data Files|domain\user|password

# WebDAV share examples
WEBDAV=W|https://webdav.example.com/share|WebDAV Storage|username|password
WEBDAV_SECURE=W|https://secure.example.com/dav|Secure WebDAV|domain\user|password

# Format:
# SHARE_NAME=DRIVE_LETTER|PATH|DESCRIPTION|USERNAME|PASSWORD
# 
# For SMB/CIFS: PATH should be UNC format (\\server\share)
# For WebDAV: PATH should be URL format (https://server/path)
# 
# Notes:
# - WebDAV paths must start with http:// or https://
# - For secure WebDAV, ensure your SSL certificate is valid
# - WebDAV credentials are optional but recommended for security
```

## 📖 Usage

```powershell
# Connect drives
.\PSNetDrive.ps1 Connect S          # Connect specific drive
.\PSNetDrive.ps1 Connect All -y     # Connect all drives with auto-confirm

# Disconnect drives
.\PSNetDrive.ps1 Disconnect M       # Disconnect specific drive
.\PSNetDrive.ps1 Disconnect All -y  # Disconnect all drives with auto-confirm

# Reconnect drives
.\PSNetDrive.ps1 Reconnect T        # Reconnect specific drive
.\PSNetDrive.ps1 Reconnect All -y   # Reconnect all drives with auto-confirm

# List network drives
.\PSNetDrive.ps1 List              # Show all drives with status
```

> **Pro Tip:** Use the `-y` switch with any command to automatically confirm operations - perfect for automation!

### WebDAV Specific Features

- **Automatic Protocol Detection**: Automatically detects and handles WebDAV URLs
- **Pre-connection Verification**: Checks WebDAV server accessibility before attempting connection
- **SSL Support**: Full support for secure WebDAV connections (https://)
- **Credential Management**: Secure handling of WebDAV credentials
- **Connection Validation**: Verifies WebDAV connections are working after mapping

### WebDAV Troubleshooting

If you encounter issues with WebDAV connections:

1. **Certificate Issues**:
   - Ensure your SSL certificate is valid
   - For self-signed certificates, add them to the trusted root store
   - Check if the WebDAV server requires specific SSL/TLS versions

2. **Authentication Problems**:
   - Verify credentials are correct
   - Check if the WebDAV server requires specific authentication methods
   - Ensure the user has proper permissions on the WebDAV share

3. **Connection Issues**:
   - Verify the WebDAV server is accessible (try accessing via browser)
   - Check if any firewalls are blocking WebDAV traffic
   - Ensure the WebDAV service is running on the server

## 🔒 Security

- **Configuration**: Sensitive data stored in `.env` file (keep this secure!)
- **Protocols**: Uses standard Windows networking protocols (SMB/CIFS and WebDAV)
- **Permissions**: No administrator privileges required
- **Error Handling**: Detailed errors without exposing sensitive information

## 🧪 Testing

Comprehensive testing suite using Pester:

```powershell
# Install Pester (if needed)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run the test suite
cd ..
Invoke-Pester -Path .\tests
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](docs/LICENSE) for details.

---

<div align="center">
  <p>Made with ❤️ by <a href="https://github.com/elirancv">elirancv</a></p>
  <p>
    <a href="https://github.com/elirancv/PSNetDrive/issues/new?template=bug_report.md&labels=bug&title=[Bug]:">Report Bug</a>
    •
    <a href="https://github.com/elirancv/PSNetDrive/issues/new?template=feature_request.md&labels=enhancement&title=[Feature]:">Request Feature</a>
  </p>
</div>