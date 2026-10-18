alias vi='vim'

# Restore the invoking directory after the login profile changes to HOME.
# An if statement also succeeds when no change is needed; OLDPWD may be unset.
if [[ "$PWD" == "$HOME" && -d "${OLDPWD:-}" ]]; then
    cd -- "$OLDPWD"
fi
