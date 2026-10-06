#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

hook="$ROOT/bin/omarchy-mac-limine-timeout"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

esp="$test_tmp/esp"
limine_default="$test_tmp/limine"
stub_bin="$test_tmp/bin"
mkdir -p "$esp" "$stub_bin"
printf 'TARGET_OS_NAME="Omarchy"\nESP_PATH="%s"\n' "$esp" >"$limine_default"
printf '#!/bin/bash\n[[ -z ${TEST_INACTIVE:-} ]]\n' >"$stub_bin/omarchy-mac-limine-active"
chmod +x "$stub_bin/omarchy-mac-limine-active"

run() {
  PATH="$stub_bin:$PATH" OMARCHY_LIMINE_DEFAULT="$limine_default" bash "$hook"
}

# Omarchy's template, as owner provisioning, the factory reset and
# omarchy-refresh-limine copy it over the menu before limine-update.
printf '### Read more at config document\n#timeout: 3\ndefault_entry: Omarchy/linux-aurora\n/+Omarchy\n  //linux-aurora\n' \
  >"$esp/limine.conf"
run || fail "the hook succeeds on the template's menu"
[[ $(sed -n 2p "$esp/limine.conf") == 'timeout: 3' && $(grep -c 'timeout' "$esp/limine.conf") == 1 ]] ||
  fail "the template's commented timeout becomes timeout: 3 in place" "$(cat "$esp/limine.conf")"
cp "$esp/limine.conf" "$test_tmp/once"
run || fail "a second run succeeds"
cmp -s "$esp/limine.conf" "$test_tmp/once" || fail "a second run changes nothing"
pass "a menu reset from Omarchy's template gets the 3 s timeout back before limine-update"

printf 'default_entry: 1\n/+Omarchy\n  //linux-aurora\n' >"$esp/limine.conf"
run || fail "the hook succeeds on a menu without a timeout line"
[[ $(sed -n 1p "$esp/limine.conf") == 'timeout: 3' && $(grep -c 'timeout' "$esp/limine.conf") == 1 ]] ||
  fail "a menu without a timeout line gets one" "$(cat "$esp/limine.conf")"
pass "a menu without a timeout line gets the 3 s timeout"

for owner in 'timeout: 10' 'timeout: no'; do
  printf '%s\n#timeout: 3\n/+Omarchy\n' "$owner" >"$esp/limine.conf"
  cp "$esp/limine.conf" "$test_tmp/owner"
  run || fail "the hook succeeds with '$owner'"
  cmp -s "$esp/limine.conf" "$test_tmp/owner" || fail "the owner's '$owner' stays" "$(cat "$esp/limine.conf")"
done
pass "a timeout the owner set stays"

printf '#timeout: 3\n/+Omarchy\n' >"$esp/limine.conf"
cp "$esp/limine.conf" "$test_tmp/inactive"
TEST_INACTIVE=1 run || fail "the hook succeeds where Limine is not active"
cmp -s "$esp/limine.conf" "$test_tmp/inactive" || fail "a Mac that does not boot Limine keeps its menu"
pass "a Mac that does not boot Limine is left alone"
