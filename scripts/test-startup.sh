#!/usr/bin/env bash
# Sourced inside the extracted package's login or interactive shell.
set -euo pipefail
trap 'printf "Startup check failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

[[ "${MSYSTEM:-}" == MSYS ]]
expected_home=$(/usr/bin/cygpath -u "$USERPROFILE")
if [[ "$HOME" != "$expected_home" ]]; then
    printf 'Expected Windows HOME <%s>, got <%s>\n' "$expected_home" "$HOME" >&2
    /usr/bin/getent passwd "$(id -u)"
    exit 1
fi
[[ "$PWD" == "$(/usr/bin/cygpath -u "$MSYS2_TEST_CWD")" ]]
[[ "$(alias vi)" == "alias vi='vim'" ]]
for tool in curl wget git make ssh vim; do
    [[ "$(command -v "$tool")" == "/usr/bin/$tool" ]]
done

if [[ "${MSYS2_TEST_INTERACTIVE:-0}" == 1 ]]; then
    [[ $- == *i* && -n ${PS1:-} ]]
fi
if [[ "${MSYS2_TEST_LOGIN:-1}" == 1 ]]; then
    shopt -q login_shell
else
    ! shopt -q login_shell
fi
printf 'MSYS startup passed: interactive=%s login=%s\n' \
    "${MSYS2_TEST_INTERACTIVE:-0}" "${MSYS2_TEST_LOGIN:-1}"
