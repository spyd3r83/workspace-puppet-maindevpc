# Self-elevate if not running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Elevating to administrator..." -ForegroundColor Yellow
    $script = $MyInvocation.MyCommand.Path
    $args = "-ExecutionPolicy Bypass -File `"$script`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $args
    exit
}

# Set working directory to the script's location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# Define Puppet path and installer
$puppetExe = "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat"
$puppetInstaller = Join-Path $scriptDir "puppet_build\puppet-agent-7.34.0-x64.msi"
$manifestPath = Join-Path $scriptDir "..\manifests\init.pp"

# Check for Puppet installation
if (Test-Path $puppetExe) {
    Write-Host "[+] Puppet is already installed." -ForegroundColor Green
    & $puppetExe --version | ForEach-Object { Write-Host "[+] Version: $_" }
}
else {
    # Install Puppet using winget
    Write-Host "[+] Fetching latest Puppet Agent version from winget..." -ForegroundColor Cyan
    $puppetPackage = winget search --id Puppet.PuppetAgent | Select-String "Puppet.PuppetAgent" | Select-Object -First 1

    if (-not $puppetPackage) {
        Write-Host "[-] Puppet Agent package not found in winget." -ForegroundColor Red
        pause
        exit 1
    }

    Write-Host "[+] Installing Puppet Agent via winget..." -ForegroundColor Cyan
    winget install --id Puppet.PuppetAgent --silent --accept-package-agreements --accept-source-agreements
    Write-Host "[+] Puppet Agent installation complete." -ForegroundColor Green
}

# Confirm Puppet command is available
if (Get-Command puppet -ErrorAction SilentlyContinue) {
    Write-Host "[+] Installing Puppet modules..." -ForegroundColor Cyan
    puppet module install puppetlabs-chocolatey
    puppet module install puppet/windows_env

    Write-Host "[*] Applying manifest..." -ForegroundColor Cyan
    puppet apply "$manifestPath" --verbose --debug
}
else {
    Write-Host "[-] Puppet command not found after installation. Aborting." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[OK] Script execution complete. Press any key to close." -ForegroundColor Green
pause
