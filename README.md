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

2. Run the installation script from the project root:
```powershell
.\scripts\les_go.ps1
```

This script will:
- Check for administrator privileges
- Install Puppet agent if not present
- Install required Puppet modules
- Apply the configuration

## What Gets Installed

### Development Tools
- Visual Studio Code (`vscode`)
- Docker Desktop (`docker-desktop`)
- Git (`git`)
- GitHub Desktop (`github-desktop`)

### Browsers and Communication
- Google Chrome (`googlechrome`)
- Firefox (`firefox`)
- Discord (`discord`)
- Zoom (`zoom`)
- Chrome Remote Desktop Host (`chrome-remote-desktop-host`)

### Graphics and Gaming
- Steam (`steam`)
- NVIDIA GeForce Now (`nvidia-geforce-now`)
- *Conditional:* NVIDIA App (`nvidia-app`) - Installs if an NVIDIA GPU is detected.
- *Conditional:* GeForce Game Ready Driver (`geforce-game-ready-driver`) - Installs if an NVIDIA GPU is detected.

### Utilities
- PowerToys (`powertoys`)
- *Conditional:* Samsung Magician (`samsung-magician`) - Installs if a Samsung SSD is detected.
- *Conditional:* Lenovo Legion Toolkit - Installs if the machine is manufactured by Lenovo.

## System and Environment Configurations

This section details the system and environment configurations applied by `mydevpc/manifests/env.pp`.

### PowerToys Configuration
The following PowerToys features are enabled:
- FancyZones
- FileExplorerPreview
- ImageResizer
- PowerRename

### Power Settings (AC Adapter)
The system is configured to optimize power settings when plugged in:
- **Disable Sleep:** Prevents the system from entering sleep mode.
- **Disable Hibernate:** Prevents the system from hibernating.
- **Keep Display On:** Prevents the display from turning off.
- **Keep Hard Disk On:** Prevents the hard disk from spinning down.

### Startup Optimizations
To speed up system startup:
- `StartupDelayInMSec` is set to `0` (no delay).
- `WaitForIdleState` is set to `0` (does not wait for idle state).

### Forced Dark Mode
- **Apps:** Light theme for applications is disabled (`AppsUseLightTheme` set to `0`).
- **System:** Light theme for the system is disabled (`SystemUsesLightTheme` set to `0`).

### Application Behavior
- **Automatic Restart:** Applications that were open before shutdown/restart are automatically reopened on logon (`RestartApps` set to `1`).

### Accessibility
- **Text Scale Factor:** The system text scale factor is set to `110%` for improved readability.

### Directory Structure
```
<project_root>/
├── .gitattributes
├── .gitignore
├── README.md
├── mydevpc/
│   └── manifests/
│       ├── init.pp       # Main Puppet manifest for the 'mydevpc' module
│       ├── env.pp        # Manifest for environment configurations
│       └── programs.pp   # Manifest for program installations
├── run.pp            # Main entry point for Puppet to apply configuration
├── scripts/
│   ├── les_go.ps1    # Main installation and execution script
│   └── puppet_build/
│       ├── puppet-agent-7.34.0-x64.msi
│       └── puppet-agent-7.34.0-x86.msi
└── (Other files like .git may exist)
```


## Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure you're running as Administrator
2. **Chocolatey Package Failures**: Try running with `--ignore-checksums`
3. **Missing Puppet**: Verify Puppet installation in `C:\Program Files\Puppet Labs\Puppet`

### Logs
- Puppet logs: `C:\ProgramData\PuppetLabs\puppet\var\log`
- Installation log: `.\scripts\puppet_build\install.log` (created after running `les_go.ps1`)

## Development

### Adding New Packages
To add new Chocolatey packages, add them to `mydevpc/manifests/programs.pp`:

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