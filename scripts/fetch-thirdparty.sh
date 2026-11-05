#!/bin/bash
# Prestium 2.0: download and verify the third-party software that is not in Debian, then stage it
# for the chroot hooks in config/includes.chroot/usr/src/prestium-thirdparty/ (not committed).
#   scripts/fetch-thirdparty.sh            verify signature + pinned SHA-256 (fails on any mismatch)
#   scripts/fetch-thirdparty.sh --repin    verify signature only, print the SHA-256 values to pin
#   It also downloads a fresh I2P reseed file (StormyCloud su3, signature-checked) into config/includes.chroot/var/lib/i2pd/.
# Needs: curl gpg gpgv git sha256sum unzip npm python3 openssl (the host's npm only runs "npm ci --ignore-scripts": pure JS,
# architecture-independent; every package tarball is checked against the lockfile's sha512 integrity).
set -euo pipefail
TOP=$(cd "$(dirname "$0")/.." && pwd)
. "$TOP/thirdparty/versions.sh"
REPIN=0; [ "${1:-}" = "--repin" ] && REPIN=1
C=${PRESTIUM_CACHE:-$TOP/cache/thirdparty}; mkdir -p "$C"
S=$TOP/config/includes.chroot/usr/src/prestium-thirdparty
export GNUPGHOME=$(mktemp -d); trap 'rm -rf "$GNUPGHOME"' EXIT
gpg -q --import "$TOP"/thirdparty/keys/*.asc 2>/dev/null
get(){ [ -s "$C/$2" ] || { curl -sfL --retry 3 -m 1800 -o "$C/$2.part" "$1" && mv "$C/$2.part" "$C/$2"; }; }
sha(){ sha256sum "$1" | cut -c1-64; }
pin(){ # name file expected
  local got; got=$(sha "$2")
  if [ "$REPIN" = 1 ]; then echo "PIN $1 $got"; return 0; fi
  [ -n "$3" ] || { echo "ERROR: no SHA-256 pinned for $1 (run --repin)"; exit 1; }
  [ "$got" = "$3" ] || { echo "ERROR: $1 SHA-256 $got != pinned $3"; exit 1; }
  echo "OK $1 $got"; }
sigok(){ # sigfile datafile fpr
  gpg --status-fd 1 --verify "$1" "$2" 2>/dev/null | grep -q "VALIDSIG.*$3" || { echo "ERROR: bad signature on $2"; exit 1; }; }

# Tor Browser
TBF=tor-browser-linux-x86_64-$TB_VERSION.tar.xz
get https://dist.torproject.org/torbrowser/$TB_VERSION/$TBF $TBF
get https://dist.torproject.org/torbrowser/$TB_VERSION/$TBF.asc $TBF.asc
sigok "$C/$TBF.asc" "$C/$TBF" "$TB_KEY"; pin TB "$C/$TBF" "$TB_SHA256"

# Firefox (local-only browser for Prestium's own pages)
FFF=firefox-$FF_VERSION.tar.xz
get https://archive.mozilla.org/pub/firefox/releases/$FF_VERSION/SHA256SUMS ff-$FF_VERSION.SHA256SUMS
get https://archive.mozilla.org/pub/firefox/releases/$FF_VERSION/SHA256SUMS.asc ff-$FF_VERSION.SHA256SUMS.asc
get https://archive.mozilla.org/pub/firefox/releases/$FF_VERSION/linux-x86_64/en-US/$FFF $FFF
sigok "$C/ff-$FF_VERSION.SHA256SUMS.asc" "$C/ff-$FF_VERSION.SHA256SUMS" "$FF_KEY"
grep -q "^$(sha "$C/$FFF")  linux-x86_64/en-US/$FFF\$" "$C/ff-$FF_VERSION.SHA256SUMS" || { echo "ERROR: Firefox not in signed SHA256SUMS"; exit 1; }
pin FF "$C/$FFF" "$FF_SHA256"

# Node.js (runtime for The Lounge)
NF=node-$NODE_VERSION-linux-x64.tar.xz
get https://nodejs.org/dist/$NODE_VERSION/SHASUMS256.txt.asc node-$NODE_VERSION.SHASUMS256.txt.asc
get https://nodejs.org/dist/$NODE_VERSION/$NF $NF
gpgv --keyring "$TOP/thirdparty/keys/node-release-keys.kbx" --output "$C/node-$NODE_VERSION.SHASUMS256.txt" \
  "$C/node-$NODE_VERSION.SHASUMS256.txt.asc" 2>/dev/null || { echo "ERROR: bad Node SHASUMS signature"; exit 1; }
grep -q "^$(sha "$C/$NF")  $NF\$" "$C/node-$NODE_VERSION.SHASUMS256.txt" || { echo "ERROR: Node not in signed SHASUMS"; exit 1; }
pin NODE "$C/$NF" "$NODE_SHA256"

# Feather (Monero wallet)
FEF=feather-$FEATHER_VERSION-linux.zip
get https://featherwallet.org/files/releases/linux/$FEF $FEF
get https://featherwallet.org/files/releases/linux/$FEF.asc $FEF.asc
sigok "$C/$FEF.asc" "$C/$FEF" "$FEATHER_KEY"; pin FEATHER "$C/$FEF" "$FEATHER_SHA256"

# The Lounge: npm ci from the committed lockfile (every tarball checked against its sha512 integrity)
L=$C/thelounge-$THELOUNGE_VERSION
if [ ! -e "$L/.done" ]; then
  rm -rf "$L"; mkdir -p "$L"
  cp "$TOP/thirdparty/thelounge/package.json" "$TOP/thirdparty/thelounge/package-lock.json" "$L/"
  ( cd "$L" && npm ci --omit=dev --omit=optional --ignore-scripts --no-audit --no-fund >/dev/null )
  grep -q "\"version\": \"$THELOUNGE_VERSION\"" "$L/node_modules/thelounge/package.json" || { echo "ERROR: thelounge version"; exit 1; }
  touch "$L/.done"
fi
echo "OK THELOUNGE $THELOUNGE_VERSION (npm ci, lockfile integrity)"

# lurch source at pinned commits (submodules checked too)
LS=$C/lurch-src
if [ ! -e "$LS/.done" ]; then
  rm -rf "$LS"; git clone -q --recursive https://github.com/gkdr/lurch "$LS"
  git -C "$LS" checkout -q "$LURCH_COMMIT"; git -C "$LS" submodule -q update --init --recursive
  touch "$LS/.done"
fi
[ "$(git -C "$LS" rev-parse HEAD)" = "$LURCH_COMMIT" ] && [ "$(git -C "$LS/lib/axc" rev-parse HEAD)" = "$AXC_COMMIT" ] && \
  [ "$(git -C "$LS/lib/libomemo" rev-parse HEAD)" = "$LIBOMEMO_COMMIT" ] || { echo "ERROR: lurch commits"; exit 1; }
echo "OK LURCH $LURCH_COMMIT"

[ "$REPIN" = 1 ] && exit 0

# I2P reseed file: fetched fresh on every build (never cached), then checked: SU3 format, StormyCloud
# signer, RSA-4096/SHA-512 signature against i2pd's reseed certificate (thirdparty/keys/reseed/), at
# most 14 days old, routerInfo entries in the zip. Any failure stops the build (no stale fallback).
# i2pd.conf [reseed] file= points at it; owner i2pd (2000) comes from perms.txt.
SU3=$TOP/config/includes.chroot/var/lib/i2pd/stormycloud-i2pseeds.su3
SU3URL=https://reseed.stormycloud.org/i2pseeds.su3
rm -f "$SU3" "$SU3.part"
# reseed servers only answer I2P's reseed user agent
curl -sfL --retry 5 --retry-delay 10 --retry-all-errors -m 300 -A "Wget/1.11.4" -o "$SU3.part" "$SU3URL" \
  || { rm -f "$SU3.part"; echo "ERROR: cannot download the I2P reseed file $SU3URL"; exit 1; }
python3 "$TOP/scripts/verify-su3.py" "$SU3.part" "$TOP/thirdparty/keys/reseed" 14 \
  || { rm -f "$SU3.part"; echo "ERROR: I2P reseed file $SU3URL failed verification"; exit 1; }
chmod 644 "$SU3.part"; mv -f "$SU3.part" "$SU3"

# stage for the hooks
rm -rf "$S"; mkdir -p "$S"
cp "$C/$TBF" "$S/tor-browser.tar.xz"; cp "$C/$FFF" "$S/firefox.tar.xz"; cp "$C/$NF" "$S/node.tar.xz"
cp "$C/$FEF" "$S/feather.zip"; echo "$FEATHER_VERSION" > "$S/feather.version"
# tar once per The Lounge version (node_modules has thousands of small files; slow on network filesystems)
LT="$C/thelounge-$THELOUNGE_VERSION.tar"
if [ ! -s "$LT" ] || [ "$L/.done" -nt "$LT" ]; then
  tar -C "$L" -cf "$LT.tmp" package.json package-lock.json node_modules && mv -f "$LT.tmp" "$LT"
fi
cp "$LT" "$S/thelounge.tar"
tar -C "$LS" --exclude=.git -cf "$S/lurch-src.tar" .
echo "STAGED $S"; ls -la "$S"
