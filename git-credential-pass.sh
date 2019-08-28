#!/usr/bin/env sh
#git-credential-pass - very minimal pass git helper
#1?: pass_name
export PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

fpass() { #1: name
    find "$PASSWORD_STORE_DIR" -name "*$1*" -exec sh -c \
        'echo "${1##$PASSWORD_STORE_DIR/}"|sed "s/.gpg\$//"' -- {} +
}

if [ "$1" = get ]; then
    while IFS== read -r VAR VAL; do
        eval "$(echo "$VAR" | tr -dc a-z)='$VAL'"
    done
    set -- "$(fpass "${username:+$username@}$host")" get
    [ -n "$1" ] || set -- "$(fpass "$host")" get
    [ -n "$1" ] || set -- "$(fpass "$username")" get
fi

[ "$2" = get ] && pass show "$1" | sed '1s/^/password=/;2,$s/: /=/'

