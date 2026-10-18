param([Parameter(Mandatory = $true)][string]$Root)
$ErrorActionPreference = 'Stop'

# Start from a path with spaces and a native Windows environment, without
# pre-setting MSYSTEM or allowing another MSYS installation to supply tools.
$launchDirectory = Join-Path $env:RUNNER_TEMP 'msys2 launch directory'
New-Item -ItemType Directory -Path $launchDirectory -Force | Out-Null
$savedEnvironment = @{}
$names = @(
    'HOME', 'MSYSTEM', 'MSYS2_PATH_TYPE', 'CHERE_INVOKING', 'OLDPWD', 'SHLVL',
    'MSYS2_TEST_CWD', 'MSYS2_TEST_SCRIPT', 'MSYS2_TEST_INTERACTIVE', 'MSYS2_TEST_LOGIN',
    'PATH', 'ORIGINAL_PATH', 'MSYS2_PATH', 'CYG_SYS_BASHRC',
    '_MSYS2_PORTABLE_PROFILE_LOADED', 'BASH_ENV', 'ENV'
)
foreach ($name in $names) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
}
$env:PATH = "$env:SystemRoot\System32;$env:SystemRoot;$env:SystemRoot\System32\Wbem"
$env:MSYS2_PATH_TYPE = 'minimal'
$env:MSYS2_TEST_CWD = $launchDirectory
$env:MSYS2_TEST_SCRIPT = (Join-Path $PSScriptRoot 'test-startup.sh').Replace('\', '/')
$env:MSYS2_TEST_INTERACTIVE = '0'
$env:MSYS2_TEST_LOGIN = '1'
$testScript = (Join-Path $PSScriptRoot 'test-package.sh').Replace('\', '/')
$bash = Join-Path $Root 'usr/bin/bash.exe'
Push-Location $launchDirectory
try {
    & $bash --login $testScript
    if ($LASTEXITCODE -ne 0) { throw 'Extracted package startup test failed.' }

    # CI has redirected input; -i selects the same startup files that a bare
    # bash.exe reads when opened interactively in a terminal.
    $env:MSYS2_TEST_INTERACTIVE = '1'
    foreach ($mode in @('-ic', '-lic')) {
        $env:MSYS2_TEST_LOGIN = if ($mode -eq '-lic') { '1' } else { '0' }
        & $bash $mode '. "$MSYS2_TEST_SCRIPT"'
        if ($LASTEXITCODE -ne 0) { throw "Interactive startup failed for bash.exe $mode." }
    }

    $env:MSYS2_PATH_TYPE = 'inherit'
    $env:MSYS2_TEST_LOGIN = '0'
    & $bash -ic '. "$MSYS2_TEST_SCRIPT"; /usr/bin/bash -ic ''. "$MSYS2_TEST_SCRIPT"'''
    if ($LASTEXITCODE -ne 0) { throw 'Nested interactive startup with inherited PATH failed.' }

    $output = & $bash -c '[[ $- != *i* ]] && ! alias vi >/dev/null 2>&1 && printf noninteractive-ok'
    if ($LASTEXITCODE -ne 0 -or $output -ne 'noninteractive-ok') {
        throw 'Non-interactive bash -c startup behavior changed.'
    }
    Write-Host 'Login, direct interactive, nested and non-interactive Bash checks passed.'
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
