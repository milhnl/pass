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

gpg --batch --gen-key <<EOF
%no-protection
%transient-key
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Real: Pass One
Name-Email: pass1@example.com
Expire-Date: 0
EOF

echo abc123 | sh pass.sh insert -m first || die insert failed
sh pass.sh mv first second || die mv failed
sh pass.sh show second | grep -xF abc123 || die show failed
