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

# Define username if needed - this might be used by resources in other classes indirectly
# or could be passed as a parameter if strict scoping is desired. For now, keep it here.
$local_user = $facts['identity']['user'] ? {
  undef   => 'Administrator',
  default => $facts['identity']['user'],
}

# Include the programs and environment classes
# The order matters if env.pp has dependencies on packages in programs.pp (e.g., PowerToys config)
class { 'programs':
  require => Class['chocolatey'], # Ensure chocolatey is configured before programs
}

class { 'env':
  # Add explicit dependency if resources in env class depend on completion of programs class resources.
  # For example, PowerToys configuration needs PowerToys to be installed.
  # Puppet class ordering (require/before/notify/subscribe) can manage this.
  # If 'programs' class installs packages that 'env' class configures, 'env' should depend on 'programs'.
  require => Class['programs'],
}

# Ensure the main init class includes these two new classes.
include programs
include env