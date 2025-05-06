# Install puppetlabs-chocolatey module
exec { 'install_chocolatey_module':
  command  => 'puppet module install puppetlabs-chocolatey',
  path     => ['C:/Program Files/Puppet Labs/Puppet/bin'],
  unless   => 'puppet module list | findstr puppetlabs-chocolatey',
  provider => 'powershell',
}

# Include the chocolatey class after module is installed
class { 'chocolatey':
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
  ensure          => installed,
  provider        => 'chocolatey',
  install_options => ['--ignore-checksums'],
}

# Install PowerToys
package { 'powertoys':
  ensure          => installed,
  provider        => 'chocolatey',
  install_options => ['--install-arguments="--silent"', '--ignore-checksums'],
  require         => Exec['install_chocolatey_module'],
}

# Launch Chrome
exec { 'launch_chrome':
  command => 'Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"',
  provider => 'powershell',
  require  => Package['googlechrome'],
}


# Configure PowerToys settings (ensure PowerToys is run at least once first)
file { "C:/Users/${local_user}/AppData/Local/Microsoft/PowerToys/settings.json":
  ensure  => file,
  content => '{
    "enabled": {
      "FancyZones": true,
      "FileExplorerPreview": true,
      "ImageResizer": true,
      "PowerRename": true
    }
  }',
  require => Package['powertoys'],
}
