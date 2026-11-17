# One-time setup for Open a Portal on Windows.
# Run in PowerShell from the repo folder:  powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1
$ErrorActionPreference = "Stop"

if (-not (Get-Command rokit -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Rokit (toolchain manager)..."
    Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
    $env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"
}

Write-Host "Installing tools from rokit.toml (Rojo)..."
rokit install --no-trust-check

Write-Host "Installing the Rojo plugin into Roblox Studio..."
rojo plugin install

Write-Host ""
Write-Host "Done. Restart Studio, then run:  rojo serve"
Write-Host "In Studio: Plugins tab > Rojo > Connect."
