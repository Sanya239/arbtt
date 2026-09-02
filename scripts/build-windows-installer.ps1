param(
    [string] $PcreDll = $env:PCRE_DLL,
    [string] $TimeZoneDir = $env:TZDIR,
    [string] $Iscc = $env:ISCC,
    [string] $CabalExtraIncludeDir = $env:CABAL_EXTRA_INCLUDE_DIR,
    [string] $CabalExtraLibDir = $env:CABAL_EXTRA_LIB_DIR,
    [string] $CabalConstraint = $env:CABAL_CONSTRAINT
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$cabalFile = Join-Path $repoRoot 'arbtt.cabal'
$versionMatch = Select-String -Path $cabalFile -Pattern '^version:\s*([0-9]+(?:\.[0-9]+)+)\s*$'
if (-not $versionMatch) {
    throw 'Could not read the package version from arbtt.cabal.'
}
$version = $versionMatch.Matches[0].Groups[1].Value

$stageDir = Join-Path $repoRoot 'dist\windows'
$binDir = Join-Path $stageDir 'bin'
$outputDir = Join-Path $repoRoot 'dist\installer'
New-Item -ItemType Directory -Force -Path $binDir, $outputDir | Out-Null

$executables = @(
    'arbtt-capture',
    'arbtt-stats',
    'arbtt-dump',
    'arbtt-import',
    'arbtt-recover'
)

foreach ($executable in $executables) {
    $listBinArguments = @('list-bin', "exe:$executable", '-v0', '--enable-tests')
    if ($CabalExtraIncludeDir) {
        $listBinArguments += "--extra-include-dirs=$($CabalExtraIncludeDir.Replace('\', '/'))"
    }
    if ($CabalExtraLibDir) {
        $listBinArguments += "--extra-lib-dirs=$($CabalExtraLibDir.Replace('\', '/'))"
    }
    if ($CabalConstraint) {
        $listBinArguments += "--constraint=$CabalConstraint"
    }
    $sourceOutput = & cabal @listBinArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Could not locate the built $executable executable. Run 'cabal build all' first."
    }
    $source = ($sourceOutput | Select-Object -Last 1).Trim()
    if (-not (Test-Path $source)) {
        throw "Cabal reported $source for $executable, but that file does not exist."
    }
    Copy-Item -Force $source (Join-Path $binDir "$executable.exe")
}

if (-not $PcreDll) {
    $PcreDll = $env:PATH.Split(';') |
        ForEach-Object { Join-Path $_ 'libpcre-1.dll' } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
}
if (-not $PcreDll -or -not (Test-Path $PcreDll)) {
    throw 'libpcre-1.dll was not found. Pass its path using -PcreDll or PCRE_DLL.'
}
Copy-Item -Force $PcreDll (Join-Path $binDir 'libpcre-1.dll')

if (-not $TimeZoneDir -or -not (Test-Path (Join-Path $TimeZoneDir 'UTC'))) {
    throw 'The zoneinfo database was not found. Pass its directory using -TimeZoneDir or TZDIR.'
}
$stagedTimeZoneDir = Join-Path $stageDir 'share\zoneinfo'
if (Test-Path $stagedTimeZoneDir) {
    Remove-Item -Recurse -Force $stagedTimeZoneDir
}
New-Item -ItemType Directory -Force -Path $stagedTimeZoneDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $TimeZoneDir '*') $stagedTimeZoneDir

$pcreRoot = Split-Path -Parent (Split-Path -Parent $PcreDll)
$pcreLicense = Join-Path $pcreRoot 'share\licenses\pcre\LICENCE'
if (-not (Test-Path $pcreLicense)) {
    throw "The PCRE license was not found at $pcreLicense."
}
$thirdPartyLicenseDir = Join-Path $stageDir 'THIRD-PARTY-LICENSES'
New-Item -ItemType Directory -Force -Path $thirdPartyLicenseDir | Out-Null
Copy-Item -Force $pcreLicense (Join-Path $thirdPartyLicenseDir 'PCRE.txt')
Copy-Item -Force (Join-Path $repoRoot 'licenses\UNICODE.txt') (Join-Path $thirdPartyLicenseDir 'UNICODE.txt')

Copy-Item -Force (Join-Path $repoRoot 'categorize.cfg') (Join-Path $stageDir 'categorize.cfg')
Copy-Item -Force (Join-Path $repoRoot 'README.Win32') (Join-Path $stageDir 'README.Win32.txt')
Copy-Item -Force (Join-Path $repoRoot 'LICENSE') (Join-Path $stageDir 'LICENSE.txt')

if (-not $Iscc) {
    $isccCommand = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($isccCommand) {
        $Iscc = $isccCommand.Source
    }
}
if (-not $Iscc) {
    $isccCandidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 7\ISCC.exe')
    )
    $Iscc = $isccCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
if (-not $Iscc -or -not (Test-Path $Iscc)) {
    throw 'ISCC.exe was not found. Pass its path using -Iscc or ISCC.'
}

Push-Location $repoRoot
try {
    & $Iscc "/DMyAppVersion=$version" "/DSourceDir=$stageDir" "/DOutputDir=$outputDir" 'setup.iss'
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

$installer = Join-Path $outputDir "arbtt-setup-$version-windows-x86_64.exe"
if (-not (Test-Path $installer)) {
    throw "The expected installer was not created at $installer."
}
Write-Host "Created $installer"
