class mydevpc::programs {
  # Ensure we're running on Windows
  if $facts['os']['family'] != 'windows' {
    fail('This module is only supported on Windows operating systems.')
  }

  # Ensure you are an Administrator
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

  # Install puppetlabs-stdlib module
  exec { 'install_stdlib_module':
    command  => 'puppet module install puppetlabs-stdlib',
    path     => ['C:/Program Files/Puppet Labs/Puppet/bin'], # Or use $facts['puppet_command_path'] if available/safer
    unless   => 'puppet module list | findstr puppetlabs-stdlib',
    provider => 'powershell',
  }

  # Include the chocolatey class after module is latest
  class { 'chocolatey':
    require => Exec['install_chocolatey_module'],
  }

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
    require         => Class['chocolatey'],
  }

  # Install PowerToys
  package { 'powertoys':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['--install-arguments="--silent"'],
    require         => Class['chocolatey'],
  }

  # Install Samsung Magician only if a Samsung SSD is detected
  if Deferred('powershell::exec', [
      'if (Get-WmiObject Win32_DiskDrive | Where-Object { $_.Model -like "*Samsung SSD*" }) { exit 0 } else { exit 1 }'
    ]) {
    package { 'samsung-magician':
      ensure          => latest,
      provider        => chocolatey,
      install_options => ['--install-arguments="--silent"'],
      require         => Class['chocolatey'],
    }
  }

  # Install Discord
  package { 'discord':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['--install-arguments="--silent"'],
    require         => Class['chocolatey'],
  }

  # Install Firefox
  package { 'firefox':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['--install-arguments="--silent"'],
    require         => Class['chocolatey'],
  }

  # Install VsCode
  package { 'vscode':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['--install-arguments="--silent"'],
    require         => Class['chocolatey'],
  }

  # Install Docker Desktop
  package { 'docker-desktop':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['--install-arguments="--silent"'],
    require         => Class['chocolatey'],
  }

  # Install Chrome Remote Desktop Host
  package { 'chrome-remote-desktop-host':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['/qn', '/norestart'], # Standard MSI silent flags
    require         => Class['chocolatey'],
  }

  # Install or upgrade Zoom using Chocolatey's built-in silent handling
  package { 'zoom':
    ensure   => latest,
    provider => chocolatey,
    require  => Class['chocolatey'],
  }

  # install nvidia-geforce-now
  package { 'nvidia-geforce-now':
    ensure          => latest,
    provider        => chocolatey,
    install_options => ['--install-arguments="--silent"'],
    require         => Class['chocolatey'],
  }

  # Install Git CLI
  package { 'git':
    ensure   => latest,
    provider => chocolatey,
    require  => Class['chocolatey'],
  }

  # Install GitHub Desktop
  package { 'github-desktop':
    ensure   => latest,
    provider => chocolatey,
    require  => Class['chocolatey'],
  }

  # Install Steam
  package { 'steam':
    ensure   => latest,
    provider => chocolatey,
    require  => Class['chocolatey'],
  }

  # Install NVIDIA Display Driver if GPU is present
  if Deferred('powershell::exec', [
      'if (Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }) { return $true } else { return $false }'
    ]) {
    # Install NVIDIA App using Chocolatey
    package { 'nvidia-app':
      ensure          => latest,
      provider        => chocolatey,
      require         => Class['chocolatey'],
    }
    # Install GeForce Game Ready Driver using Chocolatey
    package { 'geforce-game-ready-driver':
      ensure          => latest,
      provider        => chocolatey,
      require         => Class['chocolatey'],
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