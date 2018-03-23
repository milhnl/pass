#!/usr/bin/env sh

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
verbosity="0"

trace() { [ "$verbosity" -ge "3" ] && printf '%s\n' "$*" >&2; true;}
debug() { [ "$verbosity" -ge "2" ] && printf '%s\n' "$*" >&2; true;}
info() { [ "$verbosity" -ge "1" ] && printf '%s\n' "$*" >&2; true;}
warn() { [ "$verbosity" -ge "0" ] && printf '%s\n' "$*" >&2; true;}
err() { [ "$verbosity" -ge "-1" ] && printf '%s\n' "$*" >&2; true;}
die() { [ "$verbosity" -ge "-2" ] && printf '%s\n' "$*" >&2; exit 1; }

# POLYFILLS -------------------------------------------------------------------
if ! command tree >/dev/null 2>&1; then
    tree() {(
            cd "$(dirname "$1")"
            find "$(basename "$1")" -print 2>/dev/null | awk '
                !/\.$/ { \
                    for (i=1; i<NF; i++) { \
                        printf("%4s", "|") \
                    } \
                    print "-- "$NF \
                }
            ' FS='/'
    )}
fi

# COMMANDS --------------------------------------------------------------------
pass_init() { die "Not implemented"; }

pass_ls() { pass_list "$@"; }
pass_list() { tree "$PASSWORD_STORE_DIR/$1"; }

pass_grep() { die "Not implemented"; }

pass_search() { pass_find "$@"; }
pass_find() { die "Not implemented"; }

pass_show() { die "Not implemented"; }

pass_add() { pass_insert "$@"; }
pass_insert() { die "Not implemented"; }

pass_edit() { die "Not implemented"; }

pass_generate() { die "Not implemented"; }

pass_rm() { pass_remove "$@"; }
pass_delete() { pass_remove "$@"; }
pass_remove() {( cd "$PASSWORD_STORE_DIR"; rm -i "$@"; )}

pass_mv() { pass_rename "$@"; }
pass_rename() { die "Not implemented"; }

pass_cp() { pass_copy "$@"; }
pass_copy() { die "Not implemented"; }

pass_git() { die "Not implemented"; }

pass_help() { die "Not implemented"; }

pass_version() { die "Not implemented"; }

[ $# -eq 1 ] && [ -f "$PASSWORD_STORE_DIR/$1" ] && set -- show "$@"
[ $# -lt 2 ] && set -- list "$@"

pass_"$@"

