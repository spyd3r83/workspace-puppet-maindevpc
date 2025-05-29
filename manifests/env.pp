class env {

  # Get Windows environment paths
  # This fact is used by PowerToys configuration, so it's needed in this scope.
  # Ensure that $facts are available in this class, or pass parameters if necessary.
  $appdata_local = $facts['windows_env']['LOCALAPPDATA']
  $powertoys_path = "${appdata_local}/Microsoft/PowerToys" # Define $powertoys_path here as it's used by file resources below

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
  # This requires Package['powertoys'] which is in programs.pp.
  # This dependency will need to be handled by ordering the inclusion of classes in init.pp
  # or by explicitly requiring the package resource if classes are not used in such a way.
  file { 'powertoys_config_dir':
    ensure  => directory,
    path    => $powertoys_path,
    # require => Package['powertoys'], # This will be handled by class ordering in init.pp
  }

  # Configure PowerToys settings
  file { 'powertoys_settings':
    ensure  => file,
    path    => "${powertoys_path}/settings.json",
    content => stdlib::to_json_pretty($powertoys_config),
    require => File['powertoys_config_dir'],
  }

  # Get system path for powercfg.exe
  # Ensure $facts are available or pass as params.
  $system_root = $facts['windows_env']['WINDIR']
  $powercfg = "${system_root}\System32\powercfg.exe"

  # Set sleep to 'Never' when plugged in (AC power)
  exec { 'disable_sleep_on_ac':
    command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0",
    unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String -Pattern '0x0'",
    provider => 'powershell', # Added provider for consistency, though exec might pick it up
    notify   => Exec['apply_power_settings'],
  }

  # Set hibernate to 'Never' when plugged in (AC power)
  exec { 'disable_hibernate_on_ac':
    command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0",
    unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE | Select-String -Pattern '0x0'",
    provider => 'powershell',
    notify   => Exec['apply_power_settings'],
  }

  # Set display to 'Never turn off' when plugged in (AC power)
  exec { 'keep_display_on_ac':
    command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0",
    unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_VIDEO VIDEOIDLE | Select-String -Pattern '0x0'",
    provider => 'powershell',
    notify   => Exec['apply_power_settings'],
  }

  # Set hard disk to 'Never turn off' when plugged in (AC power)
  exec { 'keep_hard_disk_on_ac':
    command => "${powercfg} /SETACVALUEINDEX SCHEME_CURRENT SUB_DISK DISKIDLE 0",
    unless  => "${powercfg} /QUERY SCHEME_CURRENT SUB_DISK DISKIDLE | Select-String -Pattern '0x0'",
    provider => 'powershell',
    notify   => Exec['apply_power_settings'],
  }

  # Apply changes to the current scheme
  exec { 'apply_power_settings':
    command => "${powercfg} /SETACTIVE SCHEME_CURRENT",
    require => [ Exec['disable_sleep_on_ac'], Exec['disable_hibernate_on_ac'], Exec['keep_display_on_ac'], Exec['keep_hard_disk_on_ac'] ],
    provider => 'powershell',
    refreshonly => true, # This makes sense if the settings trigger a refresh
  }

  #Startup optimization
  exec { 'optimize_startup_StartupDelayInMSec':
    command => "${system_root}\System32\reg.exe add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize /v StartupDelayInMSec /t REG_DWORD /d 0 /f",
    unless  => "${system_root}\System32\reg.exe query HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize /v StartupDelayInMSec | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'optimize_startup_WaitForIdleState':
    command => "${system_root}\System32\reg.exe add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize /v WaitForIdleState /t REG_DWORD /d 0 /f",
    unless  => "${system_root}\System32\reg.exe query HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize /v WaitForIdleState | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  # Set Windows theme to Dark Mode for the current user
  exec { 'force_dark_mode':
    command   => "${system_root}\System32\reg.exe add HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 0 /f",
    unless    => "${system_root}\System32\reg.exe query HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  exec { 'force_dark_mode_1':
    command   => "${system_root}\System32\reg.exe add HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v SystemUsesLightTheme /t REG_DWORD /d 0 /f",
    unless    => "${system_root}\System32\reg.exe query HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v SystemUsesLightTheme | findstr 0x0",
    provider  => 'powershell',
    logoutput => true,
  }

  # Enable 'RestartApps' in Winlogon (Automatically save restartable apps and restart them when I sign back in)
  exec { 'enable_restartapps_winlogon':
    command   => "${system_root}\System32\reg.exe add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v RestartApps /t REG_DWORD /d 1 /f",
    unless    => "${system_root}\System32\reg.exe query "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v RestartApps | findstr 0x1",
    provider  => 'powershell',
    logoutput => true,
  }

  #Set TextScaleFactor
  exec { 'set_textscale_factor':
    command   => "${system_root}\System32\reg.exe add "HKCU\SOFTWARE\Microsoft\Accessibility" /v TextScaleFactor /t REG_DWORD /d 110 /f",
    unless    => "${system_root}\System32\reg.exe query "HKCU\SOFTWARE\Microsoft\Accessibility" /v TextScaleFactor | findstr 0x6e", # 0x6e is 110 in hexadecimal
    provider  => 'powershell',
    logoutput => true,
  }
}
