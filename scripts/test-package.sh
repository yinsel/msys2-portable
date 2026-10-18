#!/usr/bin/env bash
# Executed by the extracted package's bash.exe --login.
set -euo pipefail
trap 'printf "Package check failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

[[ "$MSYSTEM" == MSYS ]]
expected_home=$(/usr/bin/cygpath -u "$USERPROFILE")
if [[ "$HOME" != "$expected_home" ]]; then
    printf 'Expected Windows HOME <%s>, got <%s>\n' "$expected_home" "$HOME" >&2
    /usr/bin/getent passwd "$(id -u)"
    exit 1
fi
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
    for path in "/$environment" "/$environment.exe" "/$environment.ini" "/$environment.ico" \
        "/etc/msystem.d/${environment^^}"; do
        if [[ -e "$path" || -L "$path" ]]; then
            printf 'Unexpected non-MSYS path: %s (%s)\n' "$path" "$(cygpath -w "$path")" >&2
            exit 1
        fi
    done
done
for file in msys2.exe msys2.ini msys2.ico msys2_shell.cmd; do
    test -s "/$file"
done
test -s /etc/msystem.d/MSYS
printf 'Only MSYS environment files and launcher assets remain.\n'
printf 'Extracted MSYS package passed startup and tool checks.\n'
