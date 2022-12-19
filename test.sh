#!/usr/bin/env sh
set -eu

die() { printf '%s\n' "$*" >&2; exit 1; }

TEST_ROOT="${TEST_ROOT-$(mktemp -d)}"
export GNUPGHOME="$TEST_ROOT/gpg"
export PASSWORD_STORE_DIR="$TEST_ROOT/store"
exit_trap() { rm -r "$TEST_ROOT"; }
trap exit_trap EXIT
mkdir -p "$GNUPGHOME" "$PASSWORD_STORE_DIR"
chmod og-rwx "$GNUPGHOME" "$PASSWORD_STORE_DIR"

gpg -q --batch --gen-key <<EOF
%no-protection
%transient-key
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Email: key1
Expire-Date: 0
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Email: key2
Expire-Date: 0
EOF

sh pass.sh init key1
test -e "$PASSWORD_STORE_DIR/.gpg-id" || die init failed

#Some basic operations
echo abc123 | sh pass.sh insert -m first || die insert failed
sh pass.sh mv first second || die mv failed
sh pass.sh show second | grep -qxF abc123 || die show failed

#Keys and init
gpg_list_keys() {
    gpg --batch --list-only --no-default-keyring -d "$1" 2>&1 \
        | sed -n '/^gpg:/d;s/^\s*"\(.*\)"$/\1/p' | sort | paste -sd' '
}
sh pass.sh init -- ''
[ ! -e "$PASSWORD_STORE_DIR/.gpg-id" ] || die removing .gpg-id failed
! echo reencrypted | sh pass.sh insert -m subdir/third 2>/dev/null\
    || die insert without init
sh pass.sh init key1
echo reencrypted | sh pass.sh insert -m subdir/third
[ "$(gpg_list_keys "$PASSWORD_STORE_DIR/subdir/third.gpg")" = key1 ] \
    || die init used wrong key
test -e "$PASSWORD_STORE_DIR/.gpg-id" || die init global .gpg-id failed
sh pass.sh init -p subdir key1 key2
[ "$(gpg_list_keys "$PASSWORD_STORE_DIR/subdir/third.gpg")" = "key1 key2" ] \
    || die init used wrong key
test -e "$PASSWORD_STORE_DIR/subdir/.gpg-id" || die init subdir .gpg-id failed
sh pass.sh show subdir/third | grep -qxF reencrypted || die reencrypting failed
