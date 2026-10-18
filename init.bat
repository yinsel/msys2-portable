@echo off
setlocal EnableExtensions

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -Command "$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Run init.bat from a terminal opened as Administrator.
    exit /b 1
)

"%SystemRoot%\System32\setx.exe" MSYS2_PATH_TYPE "inherit" /M
if errorlevel 1 exit /b 1

"%SystemRoot%\System32\setx.exe" MSYS "winsymlinks:nativestrict" /M
if errorlevel 1 exit /b 1

echo System environment variables have been saved:
echo   MSYS2_PATH_TYPE=inherit
echo   MSYS=winsymlinks:nativestrict
echo Close and reopen terminal applications to use the new values.
exit /b 0
