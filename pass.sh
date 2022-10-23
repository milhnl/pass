#!/usr/bin/env sh
#pass - password manager
set -eu

. getopts/getopts.sh

#Written in 2018-2022 by Michiel van den Heuvel (michielvdnheuvel@gmail.com)

#To the extent possible under law, the author(s) have dedicated all copyright
#and related and neighboring rights to this software to the public domain
#worldwide. This software is distributed without any warranty.
#You should have received a copy of the CC0 Public Domain Dedication along with
#this software. If not, see http://creativecommons.org/publicdomain/zero/1.0/

trace() { [ "$verbosity" -ge "3" ] && printf '%s\n' "$*" >&2; true;}
debug() { [ "$verbosity" -ge "2" ] && printf '%s\n' "$*" >&2; true;}
info() { [ "$verbosity" -ge "1" ] && printf '%s\n' "$*" >&2; true;}
warn() { [ "$verbosity" -ge "0" ] && printf '%s\n' "$*" >&2; true;}
err() { [ "$verbosity" -ge "-1" ] && printf '%s\n' "$*" >&2; true;}
die() { [ "$verbosity" -ge "-2" ] && printf '%s\n' "$*" >&2; exit 1; }

# POLYFILLS -------------------------------------------------------------------
get_command_path() { #1: commandname
    #Maybe provide an option for systems without `command -v`
    command -v "$1" 2>/dev/null
}

if ! get_command_path tree >/dev/null; then
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
    set -- "$PASSWORD_STORE_DIR/${1-}"
    [ -d "$1" ] || expr "$1" : '.*/$' >/dev/null && echo "$1" || echo "$1.gpg"
}

to_qrcode() { die "Not implemented"; }

to_clip() {
    if [ `uname -s` = Darwin ]; then
        pbcopy
    elif grep -iq microsoft /proc/version 2>/dev/null; then
        clip.exe
    elif [ -n "$WAYLAND_DISPLAY" ] && get_command_path wl-copy >/dev/null; then
        wl-copy
    elif [ -n "$DISPLAY"] && get_command_path xclip >/dev/null; then
        xclip
    elif [ -n "$DISPLAY"] && get_command_path xsel >/dev/null; then
        xsel
    else
        die "No clipboard manager found. Install xclip or xsel."
    fi
}

decrypt() { #1: relname
    "$GPG" -qd "$(store_file "$1")"
}

encrypt() { #1: relname
    mkdir -p "$(dirname "$(store_file "$1")")"
    "$GPG" -qe --yes --batch --default-recipient-self -o "$(store_file "$1")"
}

mv_or_cp_with_force() {
    ! [ $# -eq 3 ] || set -- "$1" -i "$2" "$3"
    ! [ "$2" = --force ] || set -- "$1" -f "$3" "$4"
    [ $# -eq 4 ] && expr "$2" : '-[if]$' >/dev/null \
        || die "Usage: pass $1 [-f] source target"
    "$1" "$2" "$(store_file "$3")" "$(store_file "$4")"
}

# COMMANDS --------------------------------------------------------------------
pass_init() { die "Not implemented"; }

pass_ls() { pass_list "$@"; }
pass_list() { tree "$PASSWORD_STORE_DIR/${1-}"; }

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
    test ! -f "$(store_file "$1")" || [ "${force-}" = -f ] \
        || confirm "Overwrite '$1'?" || return 1
    REPLY="$($handler)" || return 1
    echo "$REPLY" | encrypt "$1" || die
}

pass_edit() {
    set -- "$1" "$([ -d /dev/shm ] && export TMPDIR=/dev/shm || true; mktemp)"
    eval "pass_edit_EXIT() { rm -f '$2'; }"
    trap pass_edit_EXIT EXIT
    decrypt "$1" >"$2"
    "$EDITOR" "$2"
    if ! decrypt "$1" | diff - "$2" >/dev/null 2>&1; then
        <"$2" encrypt "$1"
    fi
    pass_edit_EXIT
}

pass_generate() {
    default='A-Za-z0-9~`!@#$%^&*()_+=[]{}\|:;"<,>./?'"\'"
    nsym_default='A-Za-z0-9'
    cset="${PASSWORD_STORE_CHARACTER_SET:-$default}"
    while getopts 'n(no-symbols)c(clip)i(in-place)f(force)' OPT:IDX "$@"; do
        case "$OPT" in
        n) cset="${PASSWORD_STORE_CHARACTER_SET_NO_SYMBOLS:-$nsym_default}" ;;
        f) force='-f' ;;
        *) die "Not implemented" ;;
        esac
    done
    shift $(( ${IDX%.*} - 1 ))
    test ! -f "$(store_file "$1")" || [ "${force-}" = -f ] \
        || confirm "Overwrite '$1'?" || return 1
    LC_ALL=C </dev/urandom tr -dc "$cset" | head -c "${2:-25}" | encrypt "$1"
}

pass_rm() { pass_remove "$@"; }
pass_delete() { pass_remove "$@"; }
pass_remove() {(
    options="-i"
    while getopts 'r(recursive)f(force)' OPT:IDX "$@"; do
        case "$OPT" in
        r) options="${options}r" ;;
        f) options="${options}f" ;;
        *) die "Unknown option" ;;
        esac
    done
    shift $(( ${IDX%.*} - 1 ))
    rm "$options" -- "$(store_file "$1")";
)}

pass_mv() { pass_rename "$@"; }
pass_rename() {
    mv_or_cp_with_force mv "$@"
}

pass_cp() { pass_copy "$@"; }
pass_copy() {
    mv_or_cp_with_force cp "$@"
}

pass_git() { die "Not implemented"; }

pass_help() { die "Not implemented"; }

pass_version() { die "Not implemented"; }

# MAIN ------------------------------------------------------------------------
verbosity="0"
PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
GPG="${GPG:-$(get_command_path gpg2 || get_command_path gpg)}" || die "No gpg"

[ $# -eq 1 ] && [ -f "$(store_file "$@")" ] && set -- show "$@"
[ $# -lt 2 ] && [ -d "$(store_file "$@")" ] && set -- list "$@"

pass_"$@"
