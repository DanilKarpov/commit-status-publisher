

$CurInstPath = (Get-Item $PSScriptRoot).parent.FullName
$BuildNumFile = Get-ChildItem -Path (Get-Item $PSScriptRoot).parent.FullName -Filter 'BUILD_*'
$BuildNum = $BuildNumFile.Name.Replace('BUILD_', '')

Write-Output "Setting TeamCity version in Windows registry to $BuildNum"

try {
  $ErrorActionPreference = 'stop'

  $RegistryPath = 'HKLM:\Software\JetBrains\TeamCity\Server','HKLM:\Software\WOW6432Node\JetBrains\TeamCity\Server' | Where-Object { Test-Path -Path $_ }

  IF ($RegistryPath) {
    $InstPath = (Get-ItemProperty -Path $RegistryPath -Name InstallPath).InstallPath
    Write-Output "TeamCity installation path as specified in the registry: $InstPath"
    IF (!($CurInstPath -eq $InstPath)) {
      Write-Output "The current TeamCity installation directory: $CurInstPath does not match the installation path in registry: $InstPath"
      Exit 1
    }
  }

  IF ($RegistryPath) {
    New-ItemProperty -Path $RegistryPath -Name 'Version' -Value "$BuildNum" -PropertyType String -Force
  }

  $UninstallRegistryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\JetBrains TeamCity','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\JetBrains TeamCity' | Where-Object { Test-Path -Path $_ }

  IF ($UninstallRegistryPath) {
    $InstPathFromUninstaller = (Get-ItemProperty -Path $UninstallRegistryPath -Name UninstallString).UninstallString.Replace('"', '')
    IF (!($CurInstPath -eq $InstPathFromUninstaller.Replace('\Uninstall.exe', ''))) {
      Write-Output "Uninstaller path in registry: $InstPathFromUninstaller does not correspond to current TeamCity installation directory: $CurInstPath, skip updating registry for uninstaller"
      Exit
    }

    New-ItemProperty -Path $UninstallRegistryPath -Name 'DisplayName' -Value "JetBrains TeamCity" -PropertyType String -Force
    New-ItemProperty -Path $UninstallRegistryPath -Name 'DisplayVersion' -Value "Build $BuildNum" -PropertyType String -Force
  }

} catch {
  $ErrorMessage = $_.Exception.Message
  Write-Output "Could not change the registry key, error: $ErrorMessage"
}

