#!/bin/sh
# Runs the real prestium-admin-password against a temporary root with mocked chpasswd/visudo.
set -u
H=$(cd "$(dirname "$0")/.." && pwd)/config/includes.chroot
S=$H/usr/local/sbin/prestium-admin-password
fail=0; ok() { echo "OK   $1"; }; bad() { echo "FAIL $1"; fail=1; }
setup() {
  R=$(mktemp -d); mkdir -p "$R/run/prestium" "$R/etc/sudoers.d" "$R/usr/share/prestium/sudoers" "$R/bin"
  cp "$H/etc/sudoers.d/prestium-sensitive" "$R/etc/sudoers.d/"
  cp "$H/usr/share/prestium/sudoers/sensitive-password" "$R/usr/share/prestium/sudoers/"
  : > "$R/run/prestium/admin-window"; echo "100.00 50.00" > "$R/uptime"
  printf '#!/bin/sh\ncat > "%s/chpasswd.in"\nexit ${CHFAIL:-0}\n' "$R" > "$R/bin/chpasswd"
  printf '#!/bin/sh\nexit 0\n' > "$R/bin/visudo"; printf '#!/bin/sh\necho "$@" > "%s/flag"\n' "$R" > "$R/bin/flag"
  chmod +x "$R/bin/"*
  export PRESTIUM_ROOT=$R PRESTIUM_UPTIME_FILE=$R/uptime PRESTIUM_CHPASSWD=$R/bin/chpasswd \
         PRESTIUM_VISUDO=$R/bin/visudo PRESTIUM_SAFETY_FLAG=$R/bin/flag
}
setup
[ "$($S status)" = open ] && ok "status open after boot" || bad "status open"
echo 'pw1' | $S set >/dev/null && ok "set in window" || bad "set in window"
[ "$($S status)" = set ] && ok "status set" || bad "status set"
grep -q 'PASSWD: PRESTIUM_SENSITIVE' "$R/etc/sudoers.d/prestium-sensitive" && ! grep -q NOPASSWD "$R/etc/sudoers.d/prestium-sensitive" && ok "sudoers switched to password" || bad "sudoers switched"
[ "$(cat "$R/chpasswd.in")" = "root:pw1" ] && ok "root password set" || bad "root password"
echo 'pw2' | $S set >/dev/null 2>&1 && bad "second set refused" || ok "second set refused"
rm -rf "$R"; setup
echo "1000.00 5.00" > "$R/uptime"
echo 'pw' | $S set >/dev/null 2>&1 && bad "late set refused" || ok "late set refused (after 15 min)"
grep -q NOPASSWD "$R/etc/sudoers.d/prestium-sensitive" && ok "late: sudoers unchanged" || bad "late sudoers"
rm -rf "$R"; setup
$S close >/dev/null; [ "$($S status)" = closed ] && ok "close ends window" || bad "close"
echo 'pw' | $S set >/dev/null 2>&1 && bad "set after close refused" || ok "set after close refused"
rm -rf "$R"; setup
echo 'a:b' | $S set >/dev/null 2>&1 && bad "colon refused" || ok "colon refused"
[ "$($S status)" = closed ] && ok "failed attempt still ends window" || bad "window after failed attempt"
rm -rf "$R"; setup
CHFAIL=1; export CHFAIL
echo 'pw' | $S set >/dev/null 2>&1; rc=$?
[ $rc = 3 ] && grep -q 'PASSWD: PRESTIUM_SENSITIVE' "$R/etc/sudoers.d/prestium-sensitive" && [ -s "$R/flag" ] \
  && ok "chpasswd failure fails closed (password rules kept, safety flag)" || bad "chpasswd failure rc=$rc"
unset CHFAIL; rm -rf "$R"
exit $fail
