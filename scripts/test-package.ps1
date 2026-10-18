param([Parameter(Mandatory = $true)][string]$Root)
$ErrorActionPreference = 'Stop'

# Start from a path with spaces and without the setup action's HOME overrides.
$launchDirectory = Join-Path $env:RUNNER_TEMP 'msys2 launch directory'
New-Item -ItemType Directory -Path $launchDirectory -Force | Out-Null
$savedEnvironment = @{}
$names = @('HOME', 'MSYSTEM', 'MSYS2_PATH_TYPE', 'CHERE_INVOKING', 'OLDPWD', 'SHLVL', 'MSYS2_TEST_CWD')
foreach ($name in $names) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
}
$env:MSYSTEM = 'MSYS'
$env:MSYS2_PATH_TYPE = 'minimal'
$env:MSYS2_TEST_CWD = $launchDirectory
$testScript = (Join-Path $PSScriptRoot 'test-package.sh').Replace('\', '/')
Push-Location $launchDirectory
try {
    & (Join-Path $Root 'usr/bin/bash.exe') --login $testScript
    if ($LASTEXITCODE -ne 0) { throw 'Extracted package startup test failed.' }
} finally {
    Pop-Location
    foreach ($name in $names) {
        if ($null -eq $savedEnvironment[$name]) {
            Remove-Item "Env:$name" -ErrorAction SilentlyContinue
        } else {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
        }
    }
}

# The hosted Windows runner is administrative. Restore its machine settings
# after checking that the delivered batch file writes the requested values.
$settings = @{ MSYS2_PATH_TYPE = 'inherit'; MSYS = 'winsymlinks:nativestrict' }
$previousSettings = @{}
foreach ($name in $settings.Keys) {
    $previousSettings[$name] = [Environment]::GetEnvironmentVariable($name, 'Machine')
}
try {
    & (Join-Path $Root 'init.bat')
    if ($LASTEXITCODE -ne 0) { throw 'init.bat failed.' }
    foreach ($name in $settings.Keys) {
        if ([Environment]::GetEnvironmentVariable($name, 'Machine') -ne $settings[$name]) {
            throw "init.bat did not set machine variable $name correctly."
        }
    }

    # Exercise the actual RunAs restart with a path containing spaces and
    # parentheses. Hosted runners are already elevated, so no UAC click is needed.
    $initTestDirectory = Join-Path $env:RUNNER_TEMP 'msys2 init test (space)'
    New-Item -ItemType Directory -Path $initTestDirectory -Force | Out-Null
    $initTestFile = Join-Path $initTestDirectory 'init.bat'
    Copy-Item -LiteralPath (Join-Path $Root 'init.bat') -Destination $initTestFile -Force
    foreach ($name in $settings.Keys) {
        [Environment]::SetEnvironmentVariable($name, 'msys2-init-test', 'Machine')
    }
    & $initTestFile --elevate
    if ($LASTEXITCODE -ne 0) { throw 'init.bat RunAs restart failed.' }
    foreach ($name in $settings.Keys) {
        if ([Environment]::GetEnvironmentVariable($name, 'Machine') -ne $settings[$name]) {
            throw "Elevated init.bat did not set machine variable $name correctly."
        }
    }
    Write-Host 'init.bat RunAs restart and exit-code propagation passed.'
} finally {
    foreach ($name in $settings.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previousSettings[$name], 'Machine')
    }
}
Write-Host 'init.bat passed machine environment checks.'
