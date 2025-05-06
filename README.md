# Windows Development PC Setup with Puppet

This repository contains Puppet manifests and scripts to automate the setup of a Windows development environment. It installs and configures common development tools and utilities.

## Prerequisites

- Windows 10/11
- Administrator privileges
- PowerShell 5.1 or higher

## Installation

1. Clone this repository:
```powershell
git clone https://github.com/yourusername/workspace-puppet-maindevpc.git
cd workspace-puppet-maindevpc
```

2. Run the installation script:
```powershell
.\scripts\install_puppet.ps1
```

This script will:
- Check for administrator privileges
- Install Puppet agent if not present
- Install required Puppet modules
- Apply the configuration

## What Gets Installed

### Development Tools
- Visual Studio Code
- Docker Desktop
- Git
- PowerToys (with custom configuration)

### Browsers and Communication
- Google Chrome
- Discord
- Zoom
- Chrome Remote Desktop Host

### Graphics and Gaming
- NVIDIA Display Driver (if NVIDIA GPU is detected)
- Steam

## Configuration Details

### PowerToys Configuration
The manifest configures PowerToys with the following features enabled:
- FancyZones
- FileExplorerPreview
- ImageResizer
- PowerRename

### Directory Structure
```
workspace-puppet-maindevpc/
├── manifests/
│   └── init.pp       # Main Puppet manifest
├── scripts/
│   └── install_puppet.ps1  # Installation script
├── puppet_build/    # Contains Puppet MSI installer
└── README.md
```

## Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure you're running as Administrator
2. **Chocolatey Package Failures**: Try running with `--ignore-checksums`
3. **Missing Puppet**: Verify Puppet installation in `C:\Program Files\Puppet Labs\Puppet`

### Logs
- Puppet logs: `C:\ProgramData\PuppetLabs\puppet\var\log`
- Installation log: `.\puppet_build\install.log`

## Development

### Adding New Packages
To add new Chocolatey packages, add them to `manifests/init.pp`:

```puppet
package { 'package-name':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}
```

## License

MIT License (or your chosen license)