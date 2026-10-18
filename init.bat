@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem --elevate also allows the RunAs path to be checked on an admin CI runner.
if /i "%~1"=="--elevate" goto request_admin

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -Command "$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }" >nul 2>&1
if not errorlevel 1 goto configure
if /i "%~1"=="--elevated" (
    echo ERROR: Administrator privileges were not granted.
    exit /b 1
)

:request_admin
echo Requesting administrator privileges. Please approve the Windows UAC prompt.
set "MSYS2_INIT_FILE=%~f0"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference = 'Stop'; try { $process = Start-Process -FilePath $env:MSYS2_INIT_FILE -ArgumentList '--elevated' -Verb RunAs -Wait -PassThru; exit $process.ExitCode } catch { [Console]::Error.WriteLine('Administrator approval was cancelled or elevation failed: ' + $_.Exception.Message); exit 1 }"
exit /b %errorlevel%

:configure
"%SystemRoot%\System32\setx.exe" MSYS2_PATH_TYPE "inherit" /M
if errorlevel 1 exit /b 1

"%SystemRoot%\System32\setx.exe" MSYS "winsymlinks:nativestrict" /M
if errorlevel 1 exit /b 1

echo System environment variables have been saved:
echo   MSYS2_PATH_TYPE=inherit
echo   MSYS=winsymlinks:nativestrict
echo Close and reopen terminal applications to use the new values.
exit /b 0
