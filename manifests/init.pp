# Ensure we're running on Windows
if $facts['os']['family'] != 'windows' {
  fail('This module is only supported on Windows operating systems.')
}

# Ensure the user is an Administrator
if $facts['identity']['user'] != 'Administrator' and $facts['identity']['privileged'] != true {
  fail('This module requires administrator privileges to run.')
}

# Install puppetlabs-chocolatey module
exec { 'install_chocolatey_module':
  command  => 'puppet module install puppetlabs-chocolatey',
  path     => ['C:/Program Files/Puppet Labs/Puppet/bin'],
  unless   => 'puppet module list | findstr puppetlabs-chocolatey',
  provider => 'powershell',
}

# Include the chocolatey class after module is latest
class { chocolatey:
  require => Exec['install_chocolatey_module'],
}

# Include chocolatey module
include chocolatey

# Define username if needed
$local_user = $facts['identity']['user'] ? {
  undef   => 'Administrator',
  default => $facts['identity']['user'],
}

# Install Google Chrome
package { 'googlechrome':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--ignore-checksums'],
}

# Install PowerToys
package { 'powertoys':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}

# Install Samsung Magician only if a Samsung SSD is detected
if Deferred('powershell::exec', [
    'if (Get-WmiObject Win32_DiskDrive | Where-Object { $_.Model -like "*Samsung SSD*" }) { exit 0 } else { exit 1 }'
  ]) {
  package { 'samsung-magician':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['--install-arguments="--silent"'],
    require         => Exec['install_chocolatey_module'],
  }
}

# Get Windows environment paths
$appdata_local = $facts['windows_env']['LOCALAPPDATA']
$powertoys_path = "${appdata_local}/Microsoft/PowerToys"

# PowerToys configuration
$powertoys_config = {
  'enabled' => {
    'FancyZones'         => true,
    'FileExplorerPreview'=> true,
    'ImageResizer'       => true,
    'PowerRename'        => true
  }
}

# Ensure PowerToys config directory exists
file { 'powertoys_config_dir':
  ensure  => directory,
  path    => $powertoys_path,
  require => Package['powertoys'],
}

# Configure PowerToys settings
file { 'powertoys_settings':
  ensure  => file,
  path    => "${powertoys_path}/settings.json",
  content => stdlib::to_json_pretty($powertoys_config),
  require => File['powertoys_config_dir'],
}

# Install Discord
package { 'discord':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}

# Install Firefox
package { 'firefox':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}

# Install VsCode
package { 'vscode':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}

# Install Docker Desktop
package { 'docker-desktop':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}

# Launch Chrome
#exec { 'launch_chrome':
#  command  => 'Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"',
#  provider => 'powershell',
#  require  => Package['googlechrome'],
#}

# Install Chrome Remote Desktop Host
package { 'chrome-remote-desktop-host':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}

# Install or upgrade Zoom using Chocolatey's built-in silent handling
package { 'zoom':
  ensure   => latest,
  provider => chocolatey,
  require  => Exec['install_chocolatey_module'],
}


# install nvidia-geforce-now
package { 'nvidia-geforce-now':
  ensure          => latest,
  provider        => chocolatey,
  install_options => ['--install-arguments="--silent"'],
  require         => Exec['install_chocolatey_module'],
}

# Install Git CLI
package { 'git':
  ensure   => latest,
  provider => chocolatey,
  require  => Exec['install_chocolatey_module'],
}

# Install GitHub Desktop
package { 'github-desktop':
  ensure   => latest,
  provider => chocolatey,
  require  => Exec['install_chocolatey_module'],
}

# Install Steam
package { 'steam':
  ensure   => latest,
  provider => chocolatey,
  require  => Exec['install_chocolatey_module'],
}

# Install NVIDIA Display Driver if GPU is present
if Deferred('powershell::exec', [
    'if (Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }) { return $true } else { return $false }'
  ]) {
    # Install NVIDIA App using Chocolatey
    package { 'nvidia-app':
      ensure          => latest,
      provider        => chocolatey,
      require         => Exec['install_chocolatey_module'],
    }
    # Install GeForce Game Ready Driver using Chocolatey
    package { 'geforce-game-ready-driver':
      ensure          => latest,
      provider        => chocolatey,
      require         => Exec['install_chocolatey_module'],
    }
  }


# Get system path for powercfg.exe
$system_root = $facts['windows_env']['WINDIR']
$powercfg = "${system_root}\\System32\\powercfg.exe"

# Set sleep to 'Never' when plugged in (AC power)
exec { 'disable_sleep_on_ac':
  command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0",
  unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String -Pattern '0x0'",
}

# Set hibernate to 'Never' when plugged in (AC power)
exec { 'disable_hibernate_on_ac':
  command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0",
  unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE | Select-String -Pattern '0x0'",
}

# Set display to 'Never turn off' when plugged in (AC power)
exec { 'keep_display_on_ac':
  command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0",
  unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | Select-String -Pattern '0x0'",
}

# Set hard disk to 'Never turn off' when plugged in (AC power)
exec { 'keep_hard_disk_on_ac':
  command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_DISK DISKIDLE 0",
  unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_DISK DISKIDLE | Select-String -Pattern '0x0'",
}

# Apply changes to the current scheme
exec { 'apply_power_settings':
  command => "${powercfg} /SETACTIVE SCHEME_CURRENT",
  require => [ Exec['disable_sleep_on_ac'], Exec['disable_hibernate_on_ac'], Exec['keep_display_on_ac'], Exec['keep_hard_disk_on_ac'] ],
}

# Set Windows theme to Dark Mode for the current user
exec { 'set_dark_theme':
  command   => @(END_COMMAND),
    \$ErrorActionPreference = 'Stop'
    try {
        \$CurrentUser = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop).UserName
        if (\$CurrentUser) {
            \$UserProfile = Get-WmiObject -Class Win32_UserProfile -Filter "LocalPath LIKE '%\\\$(\$CurrentUser.Split('\\')[-1])'" -ErrorAction Stop
            if (\$UserProfile) {
                \$UserSID = \$UserProfile.SID
                \$RegPathBase = "Registry::HKEY_USERS\\\${\$UserSID}\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"
                
                if (-not (Test-Path \$RegPathBase)) {
                    New-Item -Path \$RegPathBase -Force | Out-Null
                }
                
                Set-ItemProperty -Path \$RegPathBase -Name AppsUseLightTheme -Value 0 -Type DWord -Force
                Set-ItemProperty -Path \$RegPathBase -Name SystemUsesLightTheme -Value 0 -Type DWord -Force
                Write-Host "Successfully set dark theme for user \$CurrentUser (SID: \$UserSID)"
                exit 0
            } else {
                Write-Warning "Could not find profile for user \$CurrentUser."
                exit 1
            }
        } else {
            Write-Warning "Could not determine current logged in user."
            exit 1
        }
    } catch {
        Write-Error "Error setting dark theme: \$(\$_.Exception.Message)"
        exit 1
    }
    END_COMMAND
  unless    => @(END_UNLESS),
    \$CurrentUser = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName
    if (\$CurrentUser) {
        \$UserProfile = Get-WmiObject -Class Win32_UserProfile -Filter "LocalPath LIKE '%\\\$(\$CurrentUser.Split('\\')[-1])'" -ErrorAction SilentlyContinue
        if (\$UserProfile) {
            \$UserSID = \$UserProfile.SID
            \$RegPath = "Registry::HKEY_USERS\\\${\$UserSID}\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"
            if (Test-Path \$RegPath) {
                \$AppsTheme = Get-ItemProperty -Path \$RegPath -Name AppsUseLightTheme -ErrorAction SilentlyContinue
                \$SystemTheme = Get-ItemProperty -Path \$RegPath -Name SystemUsesLightTheme -ErrorAction SilentlyContinue
                if (\$AppsTheme.AppsUseLightTheme -eq 0 -and \$SystemTheme.SystemUsesLightTheme -eq 0) {
                    exit 0 # Dark mode is set
                }
            }
        }
    }
    exit 1 # Dark mode is not set or cannot be determined
    END_UNLESS
  provider  => 'powershell',
  logoutput => true,
}

# Set Windows text size to 110% (LogPixels = 106) for the current user
# Note: Requires user logoff/login to take full effect.
exec { 'set_text_size_110':
  command   => @(END_COMMAND_TEXT_SIZE),
    \$ErrorActionPreference = 'Stop'
    try {
        \$CurrentUser = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop).UserName
        if (\$CurrentUser) {
            \$UserProfile = Get-WmiObject -Class Win32_UserProfile -Filter "LocalPath LIKE '%\\\$(\$CurrentUser.Split('\\')[-1])'" -ErrorAction Stop
            if (\$UserProfile) {
                \$UserSID = \$UserProfile.SID
                \$RegPath = "Registry::HKEY_USERS\\\${\$UserSID}\\Control Panel\\Desktop"
                
                if (-not (Test-Path \$RegPath)) {
                    New-Item -Path \$RegPath -Force | Out-Null
                }
                
                Set-ItemProperty -Path \$RegPath -Name LogPixels -Value 106 -Type DWord -Force
                Write-Host "Successfully set LogPixels to 106 for user \$CurrentUser (SID: \$UserSID)"
                exit 0
            } else {
                Write-Warning "Could not find profile for user \$CurrentUser."
                exit 1
            }
        } else {
            Write-Warning "Could not determine current logged in user."
            exit 1
        }
    } catch {
        Write-Error "Error setting LogPixels: \$(\$_.Exception.Message)"
        exit 1
    }
    END_COMMAND_TEXT_SIZE
  unless    => @(END_UNLESS_TEXT_SIZE),
    \$CurrentUser = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName
    if (\$CurrentUser) {
        \$UserProfile = Get-WmiObject -Class Win32_UserProfile -Filter "LocalPath LIKE '%\\\$(\$CurrentUser.Split('\\')[-1])'" -ErrorAction SilentlyContinue
        if (\$UserProfile) {
            \$UserSID = \$UserProfile.SID
            \$RegPath = "Registry::HKEY_USERS\\\${\$UserSID}\\Control Panel\\Desktop"
            if (Test-Path \$RegPath) {
                \$LogPixels = Get-ItemProperty -Path \$RegPath -Name LogPixels -ErrorAction SilentlyContinue
                if (\$LogPixels -ne \$null -and \$LogPixels.LogPixels -eq 106) {
                    exit 0 # LogPixels is already 106
                }
            }
        }
    }
    exit 1 # LogPixels is not 106 or cannot be determined
    END_UNLESS_TEXT_SIZE
  provider  => 'powershell',
  logoutput => true,
}

#Startup optimization
exec { 'optimize_startup_StartupDelayInMSec':
  command => "${system_root}\\System32\\reg.exe add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize /v StartupDelayInMSec /t REG_DWORD /d 0 /f",
  unless  => "${system_root}\\System32\\reg.exe query HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize /v StartupDelayInMSec | findstr 0x0",
}

exec { 'optimize_startup_WaitForIdleState':
  command => "${system_root}\\System32\\reg.exe add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize /v WaitForIdleState /t REG_DWORD /d 0 /f",
  unless  => "${system_root}\\System32\\reg.exe query HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize /v WaitForIdleState | findstr 0x0",
}

