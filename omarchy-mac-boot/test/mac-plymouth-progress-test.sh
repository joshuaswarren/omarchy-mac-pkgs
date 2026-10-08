#!/bin/bash

# The encrypt install hook appends the Mac's first-boot addendum to the
# initramfs copy of the Omarchy Plymouth theme, so `plymouth system-update`
# moves the bar and display-message sits under it. The installed theme is never
# written. test/integration checks the addendum against the runtime's theme.

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
INSTALL=$ROOT/files/usr/lib/initcpio/install/omarchy-mac-encrypt
ADDENDUM=$ROOT/files/usr/lib/omarchy/initcpio/omarchy-mac-plymouth.script

fail() {
  echo "not ok - $1" >&2
  [[ $# -lt 2 ]] || printf '%s\n' "$2" >&2
  exit 1
}

[[ -f $ADDENDUM ]] || fail "the Plymouth addendum is in the package files tree"
grep -Fq 'Plymouth.SetSystemUpdateFunction(mac_system_update_callback);' "$ADDENDUM" &&
  grep -Fq 'update_progress_bar(progress / 100);' "$ADDENDUM" ||
  fail "the addendum turns system-update's 0-100 into the bar's fraction"
grep -Fq 'Plymouth.SetBootProgressFunction(mac_boot_progress_callback);' "$ADDENDUM" &&
  grep -Fq 'Plymouth.SetDisplayMessageFunction(mac_display_message_callback);' "$ADDENDUM" ||
  fail "the addendum takes over boot progress and messages"
! grep -Fq 'SetPosition(10, 10' "$ADDENDUM" || fail "messages are not drawn in the top-left corner"
echo 'ok - the addendum drives the bar from system-update and centres messages'

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# A copy of the hook that reads the addendum from this tree, with mkinitcpio's
# add_* helpers stubbed out.
sed "s|/usr/lib/omarchy/initcpio/omarchy-mac-plymouth.script|$ADDENDUM|" "$INSTALL" >"$tmp/hook"

run_build() {
  BUILDROOT=$1 bash -c '
    add_module() { :; }
    add_all_modules() { :; }
    add_binary() { :; }
    add_file() { :; }
    add_symlink() { :; }
    source "$1"
    build
  ' bash "$tmp/hook"
}

theme_dir=usr/share/plymouth/themes/omarchy
mkdir -p "$tmp/installed" "$tmp/root/$theme_dir"
printf '# Omarchy theme\nfun progress_callback(duration, progress) {}\n' >"$tmp/installed/omarchy.script"
cp "$tmp/installed/omarchy.script" "$tmp/original"
# mkinitcpio may hardlink or reflink what it copies: the installed file must survive.
ln "$tmp/installed/omarchy.script" "$tmp/root/$theme_dir/omarchy.script"
run_build "$tmp/root" || fail "the install hook builds with the theme in the image"
cmp -s "$tmp/installed/omarchy.script" "$tmp/original" || fail "the installed theme is left as it was"
cat "$tmp/original" "$ADDENDUM" >"$tmp/expected"
cmp -s "$tmp/root/$theme_dir/omarchy.script" "$tmp/expected" ||
  fail "the image's theme is the installed theme followed by the addendum" "$(diff "$tmp/expected" "$tmp/root/$theme_dir/omarchy.script" || true)"
[[ ! -e $tmp/root/$theme_dir/omarchy.script.mac ]] || fail "no temporary file is left in the image"
echo 'ok - the image gets the theme plus the addendum, and the installed theme is untouched'

mkdir -p "$tmp/bare"
run_build "$tmp/bare" || fail "the install hook builds without a Plymouth theme"
[[ -z $(find "$tmp/bare" -mindepth 1 -print -quit) ]] || fail "without the Omarchy theme nothing is added"
echo 'ok - an image without the Omarchy theme gets no addendum'
