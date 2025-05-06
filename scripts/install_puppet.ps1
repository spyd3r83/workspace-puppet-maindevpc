# Self-elevate the script if not running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
  Write-Output "🔒 Elevating to administrator..."
  Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList ("-ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`"")
  exit
}

# 1. Install Puppet Agent from local MSI
Write-Output "📦 Installing Puppet Agent..."

# Resolve full path to the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# Define installer path relative to script location
$puppetInstaller = Join-Path $scriptDir "puppet_build\puppet-agent-7.34.0-x64.msi"

# Validate installer exists
if (-Not (Test-Path $puppetInstaller)) {
  Write-Error "❌ Puppet installer not found at $puppetInstaller"
  exit 1
}

# Run the installer silently with logging
Write-Output "🚀 Running installer from $puppetInstaller ..."
Start-Process "msiexec.exe" -ArgumentList "/i `"$puppetInstaller`" /qn /l*v `"$scriptDir\install.log`"" -Wait

Write-Output "✅ Puppet Agent installation complete."

# Ensure puppet is available before installing the module
if (Get-Command puppet -ErrorAction SilentlyContinue) {
  puppet module install puppetlabs-chocolatey
}
else {
  Write-Error "❌ Puppet command not found. Module installation skipped."
}
