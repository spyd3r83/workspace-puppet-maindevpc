class mydevpc {
  # Ensure we're running on Windows
  if $facts['os']['family'] != 'windows' {
    fail('This module is only supported on Windows operating systems.')
  }

  # Ensure you are an Administrator
  if $facts['identity']['user'] != 'Administrator' and $facts['identity']['privileged'] != true {
    fail('This module requires administrator privileges to run.')
  }

  # Declare ordering: programs runs before env
  Class['mydevpc::programs'] -> Class['mydevpc::env']

  # Include dependent classes
  include mydevpc::programs
  include mydevpc::env
}
