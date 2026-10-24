#!/bin/bash
# post-stage4 fix: packages 1.8 had that were not carried (t64 renames / manual libs)
cd /workspace/work/prestium/v20; . ./chenv.sh
$C apt-get update -q
for p in libfuse2t64 libfm-modules libsasl2-modules libpam-gnome-keyring libgtk2.0-bin libcanberra-gtk3-module libpam-cap mailcap media-types libregexp-ipv6-perl; do
  $C apt-get install $O --no-install-recommends $p && echo "INSTALLED $p" || echo "NOTAVAIL $p"
done
$C dpkg --audit && echo AUDIT-OK
$C apt-get clean
R=$B; sudo rm -rf $R/var/lib/apt/lists/* $R/var/cache/apt/*.bin; sudo mkdir -p $R/var/lib/apt/lists/partial
sudo cp ../v19/rootfs/etc/resolv.conf $R/etc/resolv.conf; sudo rm -f $R/usr/sbin/policy-rc.d
grep -q update_initramfs=yes $R/etc/initramfs-tools/update-initramfs.conf && echo INITRAMFS-CONF-YES
ls -la $R/boot
for m in dev/pts dev/shm dev sys/fs/cgroup sys proc; do sudo umount -l $R/$m 2>/dev/null; done
echo FIX5-DONE
