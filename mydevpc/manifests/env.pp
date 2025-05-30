class mydevpc::env {

  if $facts['os']['family'] != 'windows' {
    fail('This class is only supported on Windows operating systems.')
  }

  if $facts['identity']['user'] != 'Administrator' and $facts['identity']['privileged'] != true {
    fail('This class requires administrator privileges to run.')
  }

  $appdata_local = $facts['windows_env']['LOCALAPPDATA']
  $powertoys_path = "${appdata_local}/Microsoft/PowerToys"

  $powertoys_config = {
    'enabled' => {
      'FancyZones'          => true,
      'FileExplorerPreview' => true,
      'ImageResizer'        => true,
      'PowerRename'         => true,
    }
  }

  file { 'powertoys_config_dir':
    ensure  => directory,
    path    => $powertoys_path,
    require => Package['powertoys'],
  }

  file { 'powertoys_settings':
    ensure  => file,
    path    => "${powertoys_path}/settings.json",
    content => stdlib::to_json_pretty($powertoys_config),
    require => File['powertoys_config_dir'],
  }

  $system_root = $facts['windows_env']['WINDIR']
  $powercfg = "${system_root}\\System32\\powercfg.exe"

  exec { 'disable_sleep_on_ac':
    command   => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0",
    unless    => "${powercfg} /QUERY SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String -Pattern '0x0'",
    provider  => 'powershell',
  }

  exec { 'disable_hibernate_on_ac':
    command   => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0",
    unless    => "${powercfg} /QUERY SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE | Select-String -Pattern '0x0'",
    provider  => 'powershell',
  }

  exec { 'keep_display_on_ac':
    command   => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0",
    unless    => "${powercfg} /QUERY SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | Select-String -Pattern '0x0'",
    provider  => 'powershell',
  }

  exec { 'keep_hard_disk_on_ac':
    command   => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_DISK DISKIDLE 0",
    unless    => "${powercfg} /QUERY SCHEME_CURRENT SUB_DISK DISKIDLE | Select-String -Pattern '0x0'",
    provider  => 'powershell',
  }

  exec { 'apply_power_settings':
    command     => "${powercfg} /SETACTIVE SCHEME_CURRENT",
    provider    => 'powershell',
    require     => [
      Exec['disable_sleep_on_ac'],
      Exec['disable_hibernate_on_ac'],
      Exec['keep_display_on_ac'],
      Exec['keep_hard_disk_on_ac'],
    ],
    refreshonly => true,
  }

  exec { 'optimize_startup_StartupDelayInMSec':
    command   => "${system_root}\\System32\\reg.exe add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize\" /v StartupDelayInMSec /t REG_DWORD /d 0 /f",
    unless    => "${system_root}\\System32\\reg.exe query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize\" /v StartupDelayInMSec | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'optimize_startup_WaitForIdleState':
    command   => "${system_root}\\System32\\reg.exe add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize\" /v WaitForIdleState /t REG_DWORD /d 0 /f",
    unless    => "${system_root}\\System32\\reg.exe query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize\" /v WaitForIdleState | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'force_dark_mode_apps':
    command   => "${system_root}\\System32\\reg.exe add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize\" /v AppsUseLightTheme /t REG_DWORD /d 0 /f",
    unless    => "${system_root}\\System32\\reg.exe query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize\" /v AppsUseLightTheme | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'force_dark_mode_system':
    command   => "${system_root}\\System32\\reg.exe add \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize\" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f",
    unless    => "${system_root}\\System32\\reg.exe query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize\" /v SystemUsesLightTheme | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'enable_restartapps_winlogon':
    command   => "${system_root}\\System32\\reg.exe add \"HKCU\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\" /v RestartApps /t REG_DWORD /d 1 /f",
    unless    => "${system_root}\\System32\\reg.exe query \"HKCU\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\" /v RestartApps | findstr 0x1",
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'set_textscale_factor':
    command   => "${system_root}\\System32\\reg.exe add \"HKCU\\SOFTWARE\\Microsoft\\Accessibility\" /v TextScaleFactor /t REG_DWORD /d 110 /f",
    unless    => "${system_root}\\System32\\reg.exe query \"HKCU\\SOFTWARE\\Microsoft\\Accessibility\" /v TextScaleFactor | findstr 0x6e",
    provider  => 'powershell',
    logoutput => true,
  }

}
