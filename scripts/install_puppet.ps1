# Self-elevate the script if not running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "[!] Elevating to administrator..."
    
    $script = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -File `"$script`""

    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# Check if Puppet is already installed
$puppetPath = "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat"
if (Test-Path $puppetPath) {
    Write-Output "[+] Puppet is already installed"
    $puppetVersion = & $puppetPath --version
    Write-Output "[+] Current version: $puppetVersion"
    
    # Skip to module installation
    puppet module install puppetlabs-chocolatey
    puppet module install puppet/windows_env
    puppet apply ..\manifests\init.pp --verbose
    exit 0
}

# Continue with installation if Puppet is not found
Write-Output "[+] Installing Puppet Agent..."

# Resolve full path to the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# Define installer path relative to script location
$puppetInstaller = Join-Path $scriptDir "puppet_build\puppet-agent-7.34.0-x64.msi"

# Validate installer exists
if (-Not (Test-Path $puppetInstaller)) {
    Write-Error "[-] Puppet installer not found at $puppetInstaller"
    exit 1
}

# Run the installer silently with logging
Write-Output "[+] Running installer from $puppetInstaller ..."
Start-Process "msiexec.exe" -ArgumentList "/i `"$puppetInstaller`" /qn /l*v `"$scriptDir\install.log`"" -Wait

Write-Output "[+] Puppet Agent installation complete."

# Ensure puppet is available before installing the module
if (Get-Command puppet -ErrorAction SilentlyContinue) {
    puppet module install puppetlabs-chocolatey
    puppet module install puppet/windows_env
    
    # Apply Puppet manifest with correct path
    puppet apply ..\manifests\init.pp --verbose
}
else {
    Write-Error "[-] Puppet command not found. Module installation skipped."
}