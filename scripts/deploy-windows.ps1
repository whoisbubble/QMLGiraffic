param(
    [string]$BuildDir = "build/Desktop_Qt_6_10_2_MinGW_64_bit-u041eu0442u043bu0430u0434u043au0430",
    [string]$DeployDir = "dist/windows",
    [string]$QtDir = "C:/Qt/6.10.2/mingw_64",
    [string]$PostgresBin = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$appName = "Giraffic"
$exePath = Join-Path $root "$BuildDir/$appName.exe"
$deployPath = Join-Path $root $DeployDir
$deployExe = Join-Path $deployPath "$appName.exe"
$windeployqt = Join-Path $QtDir "bin/windeployqt.exe"
$qtPsqlDriver = Join-Path $QtDir "plugins/sqldrivers/qsqlpsql.dll"

function Find-PostgresBin {
    param([string]$ExplicitPath)

    if ($ExplicitPath -and (Test-Path (Join-Path $ExplicitPath "libpq.dll"))) {
        return (Resolve-Path $ExplicitPath).Path
    }

    if ($env:POSTGRESQL_BIN -and (Test-Path (Join-Path $env:POSTGRESQL_BIN "libpq.dll"))) {
        return (Resolve-Path $env:POSTGRESQL_BIN).Path
    }

    $pathCandidate = ($env:PATH -split ';' |
        Where-Object { $_ -and (Test-Path (Join-Path $_ "libpq.dll")) } |
        Select-Object -First 1)

    if ($pathCandidate) {
        return (Resolve-Path $pathCandidate).Path
    }

    $programFilesCandidate = Get-ChildItem -Directory "C:/Program Files/PostgreSQL" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "bin" } |
        Where-Object { Test-Path (Join-Path $_ "libpq.dll") } |
        Select-Object -First 1

    if ($programFilesCandidate) {
        return (Resolve-Path $programFilesCandidate).Path
    }

    return ""
}

function Copy-PostgresClientDlls {
    param(
        [string]$SourceDir,
        [string]$TargetDir
    )

    $patterns = @(
        "libpq.dll",
        "libintl-*.dll",
        "libiconv-*.dll",
        "libssl-*.dll",
        "libcrypto-*.dll"
    )

    foreach ($pattern in $patterns) {
        Get-ChildItem -Path $SourceDir -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object {
                Copy-Item -Force $_.FullName (Join-Path $TargetDir $_.Name)
                Write-Host "Copied PostgreSQL client dependency: $($_.Name)"
            }
    }
}

if (!(Test-Path $exePath)) {
    throw "Executable not found: $exePath. Build the Release target first."
}

if (!(Test-Path $windeployqt)) {
    throw "windeployqt not found: $windeployqt"
}

if (!(Test-Path $qtPsqlDriver)) {
    throw "PostgreSQL Qt driver not found: $qtPsqlDriver"
}

New-Item -ItemType Directory -Force -Path $deployPath | Out-Null
Copy-Item -Force $exePath $deployExe
Copy-Item -Force (Join-Path $root "config/giraffic.ini.example") (Join-Path $deployPath "giraffic.ini.example")

& $windeployqt --release --qmldir $root $deployExe

$sqlDriversPath = Join-Path $deployPath "sqldrivers"
New-Item -ItemType Directory -Force -Path $sqlDriversPath | Out-Null
Copy-Item -Force $qtPsqlDriver (Join-Path $sqlDriversPath "qsqlpsql.dll")

$resolvedPostgresBin = Find-PostgresBin $PostgresBin
if ($resolvedPostgresBin) {
    Write-Host "Using PostgreSQL client DLLs from: $resolvedPostgresBin"
    Copy-PostgresClientDlls $resolvedPostgresBin $deployPath
} else {
    Write-Warning "PostgreSQL libpq.dll was not found. QPSQL may fail with 'Driver not loaded'."
    Write-Warning "Install PostgreSQL or rerun with: .\scripts\deploy-windows.ps1 -PostgresBin 'C:\Program Files\PostgreSQL\18\bin'"
}

Write-Host "Windows deploy is ready: $deployPath"
