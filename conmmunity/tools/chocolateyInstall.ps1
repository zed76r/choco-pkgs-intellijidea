﻿$ErrorActionPreference = 'Stop';

$softwareName = 'IntelliJ IDEA Community Edition*'
[array]$key = Get-UninstallRegistryKey -SoftwareName $softwareName

if ($key.Count -gt 0) {
    Invoke-Expression -Command $PSScriptRoot\chocolateyUninstall.ps1
}

$url = 'https://download.jetbrains.com/idea/ideaIC-2024.3.2.1.exe'
$sha256sum = '93560ed30c1e398d171b9befbfa83907a3cde8cddccdb6a13160226795f76213'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
if ([System.Environment]::Is64BitOperatingSystem) {
    $programFiles = $env:ProgramFiles
}
else {
    $programFiles = ${env:ProgramFiles(x86)}
}
$installDir = "$programFiles\JetBrains\IntelliJ IDEA Community Edition $env:ChocolateyPackageVersion"

$pp = Get-PackageParameters
if ($pp.InstallDir) {
    $installDir = $pp.InstallDir
}

$silentArgs = "/S /CONFIG=$toolsDir\silent.config "
$silentArgs += "/D=$installDir"

New-Item -ItemType Directory -Force -Path $installDir

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $toolsDir
    fileType       = 'exe'
    url            = $url
    url64bit       = $url

    softwareName   = $softwareName

    checksum       = $sha256sum
    checksumType   = 'sha256'
    checksum64     = $sha256sum
    checksumType64 = 'sha256'

    silentArgs     = $silentArgs
    validExitCodes = @(0, 1641, 3010)
}

Install-ChocolateyPackage @packageArgs
