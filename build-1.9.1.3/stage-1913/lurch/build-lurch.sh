#!/bin/bash
# Prestium 1.9.1.3: build lurch 0.7.0 (OMEMO for libpurple; bundled axc 0.3.4, libomemo 0.7.1,
# libsignal-protocol-c 2.3.3, statically linked) in the rootfs chroot; install lurch.so to
# /usr/lib/purple-2/; install purple-xmpp-carbons (Debian) and the lurch runtime lib libmxml1.
# Build-only packages are purged again (exact list of what this run added). Idempotent.
set -e
cd /workspace/work/prestium/v20; . ./chenv.sh; R=rootfs; L=stage-1913/lurch
RES=$(mktemp); sudo cp -a $R/etc/resolv.conf.prestium $RES 2>/dev/null || true
$C apt-get $O --no-install-recommends install purple-xmpp-carbons libmxml1 2>&1 | tail -3
if ! sudo test -e $R/usr/lib/purple-2/lurch.so; then
  [ -s $L/pkgs-before.txt ] || $C dpkg-query -W -f="\${Package}\\n" | sort > $L/pkgs-before.txt
  $C apt-get $O --no-install-recommends install gcc g++ make cmake pkg-config libc6-dev libpurple-dev libmxml-dev libxml2-dev libsqlite3-dev libgcrypt20-dev libglib2.0-dev 2>&1 | tail -3
  $C dpkg-query -W -f='${Package}\n' | sort > $L/pkgs-after.txt
  sudo rm -rf $R/tmp/lurch; sudo cp -a $L/src $R/tmp/lurch
  $C sh -c 'cd /tmp/lurch && make -j2 LIBGCRYPT_LDFLAGS=-lgcrypt CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=-fPIC -DCMAKE_POLICY_VERSION_MINIMUM=3.5" 2>&1 | tail -20 && ls -la build/lurch.so'
  sudo install -D -m644 $R/tmp/lurch/build/lurch.so $R/usr/lib/purple-2/lurch.so
  comm -13 $L/pkgs-before.txt $L/pkgs-after.txt > $L/pkgs-build-only.txt
  [ -s $L/pkgs-build-only.txt ] && $C apt-get $O purge $(cat $L/pkgs-build-only.txt) 2>&1 | tail -3
  sudo rm -rf $R/tmp/lurch
fi
# (1.9.1.3 first build lacked -lgcrypt: libgcrypt-config absent in trixie; fixed there with patchelf --add-needed libgcrypt.so.20)
$C apt-get clean
sudo chroot $R ldd /usr/lib/purple-2/lurch.so | grep -E 'not found|mxml|gcrypt|sqlite' || true
sudo chroot $R ls -la /usr/lib/purple-2/ | grep -E 'lurch|carbons'
# restore Prestium's resolv.conf (chenv.sh copied the host's)
printf '# Prestium: no system DNS. Tor and I2P resolve names themselves; anything else\n# trying to resolve a name fails here instead of leaking a query.\nnameserver 127.0.0.1\n' | sudo tee $R/etc/resolv.conf >/dev/null
sudo rm -f $R/usr/sbin/policy-rc.d
for m in dev/pts dev sys proc; do mountpoint -q $R/$m && sudo umount -l $R/$m; done
echo LURCH-OK
