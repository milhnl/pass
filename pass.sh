#!/usr/bin/env sh

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
GPG="${GPG-$( (which gpg2 || which gpg) 2>/dev/null)}"
verbosity="0"

trace() { [ "$verbosity" -ge "3" ] && printf '%s\n' "$*" >&2; true;}
debug() { [ "$verbosity" -ge "2" ] && printf '%s\n' "$*" >&2; true;}
info() { [ "$verbosity" -ge "1" ] && printf '%s\n' "$*" >&2; true;}
warn() { [ "$verbosity" -ge "0" ] && printf '%s\n' "$*" >&2; true;}
err() { [ "$verbosity" -ge "-1" ] && printf '%s\n' "$*" >&2; true;}
die() { [ "$verbosity" -ge "-2" ] && printf '%s\n' "$*" >&2; exit 1; }

# POLYFILLS -------------------------------------------------------------------
if ! which tree >/dev/null 2>&1; then
    tree() {(
        cd "$(dirname "$1")" || die
        find "$(basename "$1")" -print 2>/dev/null | awk '
            !/\.$/ {
                for (i=1; i<NF; i++) {
                    printf("%4s", "|")
                }
                print "-- "$NF
            }
        ' FS='/'
    )}
fi

echo() { printf %s\\n "$*" ; }

# FUNCTIONS -------------------------------------------------------------------
confirm() ( #1: prompt
    printf "%s [y/N] " "$1"
    read -r REPLY
    [ "$REPLY" = y ]
)

prompt() {( #1?: prompt
    printf "${1-Password: }" >/dev/stderr
    IFS= read -r REPLY || return 1
    echo "$REPLY"
)}

prompt_safe() {(
    tty="$(stty -g 2>/dev/null)" || die "Can't provide safe terminal. Use '-e'"
    trap 'stty "$tty"' EXIT INT TERM
    stty -echo || return 1

    REPLY="$(prompt 'Password: ')" || return 1; set -- "$REPLY"
    REPLY="$(prompt '\nConfirm: ')" || return 1

    printf '\n' >/dev/stderr
    [ "$1" = "$REPLY" ] && echo "$1" || die "Don't match"
)}

store_file() { #1: relname
    echo "$PASSWORD_STORE_DIR/$1.gpg"
}

to_qrcode() { die "Not implemented"; }

to_clip() {
    [ `uname -s` = Darwin ] && pbcopy && return
    grep -iq microsoft /proc/version 2>/dev/null && clip.exe && return
    which xclip >/dev/null 2>&1 && xclip && return
    which xsel >/dev/null 2>&1 && xsel && return
    die "No clipboard manager found. Install xclip or xsel."
}

decrypt() { #1: relname
    "$GPG" -qd "$(store_file "$1")"
}

encrypt() { #1: relname
    "$GPG" -qe --yes --batch --default-recipient-self -o "$(store_file "$1")"
}

# COMMANDS --------------------------------------------------------------------
pass_init() { die "Not implemented"; }

pass_ls() { pass_list "$@"; }
pass_list() { tree "$PASSWORD_STORE_DIR/$1"; }

pass_grep() { die "Not implemented"; }

pass_search() { pass_find "$@"; }
pass_find() { die "Not implemented"; }

pass_show() {
    case "$1" in
    --) decrypt "$2"; return ;;
    -*)
        set -- $(printf "%s" "$1" | sed '
                s/=\([0-9][0-9]*\)$/ \1/;
                s/^--/to_/;
                s/^-c\([0-9]*\)/to_clip \1/;
                s/^-q\([0-9]*\)/to_qrcode \1/;
                s/\([^0-9]\)$/\1 1/;
            ') "$([ "$2" = -- ] && echo "$3" || echo "$2")"
        ;;
    *) decrypt "$1"; return ;;
    esac
    decrypt "$3" | sed "${2}q;d" | "$1"
}

pass_add() { pass_insert "$@"; }
pass_insert() {
    handler="prompt_safe"
    while getopts 'e(echo)m(multiline)f(force)' OPT:IDX "$@"; do
        case "$OPT" in
        e) handler="prompt" ;;
        m) handler="cat" ;;
        f) force="-f" ;;
        *) die "Unknown option" ;;
        esac
    done
    shift $(( ${IDX%.*} - 1 ))
    test ! -f "$(store_file "$1")" || [ "$force" = -f ] \
        || confirm "Overwrite '$1'?" || return 1
    REPLY="$($handler)" || return 1
    echo "$REPLY" | encrypt "$1" || die
}

pass_edit() { die "Not implemented"; }

pass_generate() { die "Not implemented"; }

pass_rm() { pass_remove "$@"; }
pass_delete() { pass_remove "$@"; }
pass_remove() {( cd "$PASSWORD_STORE_DIR" || die; rm -i "$@"; )}

pass_mv() { pass_rename "$@"; }
pass_rename() { die "Not implemented"; }

pass_cp() { pass_copy "$@"; }
pass_copy() { die "Not implemented"; }

pass_git() { die "Not implemented"; }

pass_help() { die "Not implemented"; }

pass_version() { die "Not implemented"; }

[ $# -eq 1 ] && [ -f "$(store_file "$1")" ] && set -- show "$@"
[ $# -lt 2 ] && set -- list "$@"

pass_"$@"

