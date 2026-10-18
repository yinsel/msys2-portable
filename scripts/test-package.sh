#!/usr/bin/env bash
# Executed by the extracted package's bash.exe --login.
set -euo pipefail
trap 'printf "Package check failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

source "$(dirname -- "${BASH_SOURCE[0]}")/test-startup.sh"
grep -Fxq 'db_home: windows' /etc/nsswitch.conf
test -s /init.bat

curl --version >/dev/null
wget --version >/dev/null
git --version
make --version >/dev/null
ssh -V
vim --version >/dev/null
pacman -Q curl wget git make openssh vim
pacman -Q msys2-runtime bash pacman
pacman -Dk

# Resolve the delivered pacman configuration, then fetch the MSYS database
# through that configured mirror into a temporary file without upgrading.
msys_server=$(pacman-conf --repo msys Server)
[[ "${msys_server%/}" == 'https://mirror.nju.edu.cn/msys2/msys/x86_64' ]]
while IFS= read -r repository; do
    server=$(pacman-conf --repo "$repository" Server)
    [[ "$server" == https://mirror.nju.edu.cn/msys2/* ]]
    [[ "$server" != *$'\n'* ]]
done < <(pacman-conf --repo-list)
mirror_db=$(mktemp)
trap 'rm -f -- "$mirror_db"' EXIT
curl --fail --location --retry 2 --connect-timeout 20 --max-time 120 \
    --output "$mirror_db" "${msys_server%/}/msys.db"
tar -tf "$mirror_db" >/dev/null
rm -f -- "$mirror_db"
trap - EXIT
printf 'NJU mirror configuration and MSYS database download passed.\n'

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
