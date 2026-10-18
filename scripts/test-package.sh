#!/usr/bin/env bash
# Executed by the extracted package's bash.exe --login.
set -euo pipefail

[[ "$MSYSTEM" == MSYS ]]
[[ "$HOME" == "$(/usr/bin/cygpath -u "$USERPROFILE")" ]]
[[ "$PWD" == "$(/usr/bin/cygpath -u "$MSYS2_TEST_CWD")" ]]
[[ "$(alias vi)" == "alias vi='vim'" ]]
grep -Fxq 'db_home: windows' /etc/nsswitch.conf
test -s /init.bat

for tool in curl wget git make ssh vim; do
    [[ "$(command -v "$tool")" == "/usr/bin/$tool" ]]
done
curl --version >/dev/null
wget --version >/dev/null
git --version
make --version >/dev/null
ssh -V
vim --version >/dev/null
pacman -Q curl wget git make openssh vim
pacman -Dk
packages=$(pacman -Qq)
if grep -q '^mingw-w64-' <<< "$packages"; then
    printf 'Unexpected non-MSYS package.\n' >&2
    exit 1
fi

for environment in mingw32 mingw64 ucrt64 clang32 clang64 clangarm64; do
    test ! -e "/$environment"
done
for file in msys2.exe msys2.ini msys2.ico msys2_shell.cmd; do
    test -s "/$file"
done
printf 'Extracted MSYS package passed startup and tool checks.\n'
