﻿$ErrorActionPreference = 'Stop';

$softwareName = 'IntelliJ IDEA*'
[array]$key = Get-UninstallRegistryKey -SoftwareName $softwareName

if ($key.Count -gt 0) {
    Invoke-Expression -Command $PSScriptRoot\chocolateyUninstall.ps1
}

$url = 'https://download.jetbrains.com/idea/ideaIU-2024.2.3.exe'
$sha256sum = '0d9257dc9021da8d17dacdf04b227295861cfa201fc102b0b8b0b7968c5a2c2e'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
if ([System.Environment]::Is64BitOperatingSystem) {
    $programFiles = $env:ProgramFiles
} else {
    $programFiles = ${env:ProgramFiles(x86)}
}

$installDir = "$programFiles\JetBrains\IntelliJ IDEA $env:ChocolateyPackageVersion"

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
