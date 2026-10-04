#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/base-test.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stage="$work/root"
"$ROOT/install" "$stage"

! grep -rqs hid_apple "$stage/usr/lib/modprobe.d" || fail 'the package ships no hid_apple option'
pass 'the package leaves hid_apple at the kernel default, so any owner option wins'
