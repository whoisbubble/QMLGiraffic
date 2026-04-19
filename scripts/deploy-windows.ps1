param(
    [string]$BuildDir = "build/Desktop_Qt_6_10_2_MinGW_64_bit-u041eu0442u043bu0430u0434u043au0430",
    [string]$DeployDir = "dist/windows",
    [string]$QtDir = "C:/Qt/6.10.2/mingw_64"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exePath = Join-Path $root "$BuildDir/appQMLGiraffic.exe"
$deployPath = Join-Path $root $DeployDir
$deployExe = Join-Path $deployPath "appQMLGiraffic.exe"
$windeployqt = Join-Path $QtDir "bin/windeployqt.exe"

if (!(Test-Path $exePath)) {
    throw "Executable not found: $exePath. Build the Release target first."
}

if (!(Test-Path $windeployqt)) {
    throw "windeployqt not found: $windeployqt"
}

New-Item -ItemType Directory -Force -Path $deployPath | Out-Null
Copy-Item -Force $exePath $deployExe
Copy-Item -Force (Join-Path $root "config/giraffic.ini.example") (Join-Path $deployPath "giraffic.ini.example")

& $windeployqt --release --qmldir $root $deployExe

Write-Host "Windows deploy is ready: $deployPath"
