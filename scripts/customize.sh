#!/usr/bin/env bash
# Run only in the fresh installation created by the build workflow.
set -euo pipefail

if [[ "${MSYSTEM:-}" != MSYS || ! -f /usr/bin/msys-2.0.dll ]]; then
    printf 'This script must run inside the fresh MSYS build installation.\n' >&2
    exit 1
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
packages=$(pacman -Qq)
if grep -q '^mingw-w64-' <<< "$packages"; then
    printf 'Expected an MSYS-only installation; found MinGW packages.\n' >&2
    exit 1
fi

install -Dm644 "$repo_dir/etc/profile.d/env.sh" /etc/profile.d/env.sh
install -m644 "$repo_dir/init.bat" /init.bat
for mirrorlist in msys mingw; do
    install -Dm644 "$repo_dir/etc/pacman.d/mirrorlist.$mirrorlist" "/etc/pacman.d/mirrorlist.$mirrorlist"
done

# Bash reads this file for interactive non-login shells. Keep the upstream
# prompt and other setup after our bootstrap instead of replacing them.
if ! grep -Fq '# MSYS2 Portable: initialize a directly launched interactive bash.exe.' /etc/bash.bashrc; then
    bashrc_tmp=$(mktemp)
    cat "$repo_dir/etc/bash.bashrc.prepend" /etc/bash.bashrc > "$bashrc_tmp"
    install -m644 "$bashrc_tmp" /etc/bash.bashrc
    rm -f -- "$bashrc_tmp"
fi

if grep -qE '^[[:space:]]*db_home[[:space:]]*:' /etc/nsswitch.conf; then
    sed -i -E 's/^[[:space:]]*db_home[[:space:]]*:.*$/db_home: windows/' /etc/nsswitch.conf
else
    printf '\ndb_home: windows\n' >> /etc/nsswitch.conf
fi

# Keep only the MSYS environment and its launcher assets. These files also
# ship in the base packages even when no MinGW toolchain is installed.
for environment in mingw32 mingw64 ucrt64 clang32 clang64 clangarm64; do
    rm -rf -- "/$environment"
    rm -f -- "/$environment.exe" "/$environment.ini" "/$environment.ico" \
        "/etc/msystem.d/${environment^^}"
done

find /var/cache/pacman/pkg -mindepth 1 -maxdepth 1 -type f -delete
bash -n /etc/profile.d/env.sh /etc/bash.bashrc
pacman -Dk
