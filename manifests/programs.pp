class programs {

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
    require         => Exec['install_chocolatey_module'], # This assumes install_chocolatey_module is globally available or in init.pp
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

  # Install Chrome Remote Desktop Host
  package { 'chrome-remote-desktop-host':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['/qn', '/norestart'], # Standard MSI silent flags
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

  # Check if the machine is manufactured by Lenovo and apply Lenovo-specific configurations
  if $facts['dmi']['manufacturer'] =~ /(?i)lenovo/ {
    exec { 'install_legion_toolkit_winget':
      provider  => powershell,
      command   => 'winget install --id BartoszCichecki.LenovoLegionToolkit --accept-package-agreements --accept-source-agreements --silent',
      unless    => 'if (winget list --id BartoszCichecki.LenovoLegionToolkit | Select-String "Lenovo Legion Toolkit") { exit 0 } else { exit 1 }',
      logoutput => true,
    }
  }
}
