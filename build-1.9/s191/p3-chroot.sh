#!/bin/bash
# Prestium 1.9.1: chroot-side steps (resumable via markers)
source /workspace/work/prestium/v20/chenv.sh
V=/workspace/work/prestium/v20; B=$V/rootfs; M=$V/bh/s191/markers; L=$V/bh/s191/p3-chroot.log
mkdir -p $M; echo "START $(date -u +%T)" >> $L
st(){ [ -e $M/$1 ] && return 1; echo "== $1 $(date -u +%T)" >> $L; return 0; }
ok(){ touch $M/$1; echo "== $1 done $(date -u +%T)" >> $L; }
if st p3-users; then
  $C sh -c 'getent group onion-grater >/dev/null || groupadd --system onion-grater; getent passwd onion-grater >/dev/null || useradd --system -g onion-grater -d /nonexistent -s /usr/sbin/nologin -c "Prestium Tor control filter" onion-grater; gpasswd -d user debian-tor || true; id user; id onion-grater' >> $L 2>&1 && ok p3-users
fi
if st p3-units; then
  $C systemctl enable prestium-onion-grater.service prestium-firewall-early.service prestium-initramfs-shutdown.service prestium-wipe-session.service >> $L 2>&1
  sudo mkdir -p $B/etc/systemd/user; for u in zeitgeist.service zeitgeist-fts.service; do sudo ln -sfn /dev/null $B/etc/systemd/user/$u; done
  ok p3-units
fi
if st p3-statoverride; then
  for f in /usr/bin/ntfs-3g /usr/lib/x86_64-linux-gnu/gstreamer1.0/gstreamer-1.0/gst-ptp-helper /usr/lib/openssh/ssh-keysign /usr/bin/chfn /usr/bin/chsh /usr/bin/newgrp; do
    $C sh -c "dpkg-statoverride --list $f >/dev/null || dpkg-statoverride --update --add root root 0755 $f" >> $L 2>&1
  done
  $C sh -c "dpkg-statoverride --list /usr/sbin/pppd >/dev/null || dpkg-statoverride --update --add root dip 0755 /usr/sbin/pppd" >> $L 2>&1
  $C sh -c 'setcap -r /usr/lib/x86_64-linux-gnu/gstreamer1.0/gstreamer-1.0/gst-ptp-helper 2>/dev/null; dpkg-statoverride --list' >> $L 2>&1
  ok p3-statoverride
fi
if st p3-ca; then
  $C update-ca-certificates --fresh >> $L 2>&1
  $C sh -c 'grep -c "BEGIN CERT" /etc/ssl/certs/ca-certificates.crt; ls /etc/ssl/certs | grep -ci emsign; trust list 2>/dev/null | grep -ci emsign' >> $L 2>&1
  N=/usr/lib/x86_64-linux-gnu/nss/libnssckbi.so
  $C sh -c "[ -e $N ] && { dpkg-divert --list $N | grep -q . || dpkg-divert --add --rename --divert $N.nss-builtins $N; ln -sfn ../pkcs11/p11-kit-trust.so $N; ls -l $N; }" >> $L 2>&1
  ok p3-ca
fi
if st p3-gvfs; then
  for m in afp afp-browse dav dav+sd dns-sd ftp ftpis ftps google http nfs onedrive sftp smb smb-browse network wsdd; do
    f=/usr/share/gvfs/mounts/$m.mount
    $C sh -c "[ -e $f ] && { dpkg-divert --list $f | grep -q . || dpkg-divert --add --rename --divert $f.prestium-disabled $f; }" >> $L 2>&1
  done
  ls $B/usr/share/gvfs/mounts >> $L
  ok p3-gvfs
fi
if st p3-dconf; then
  sudo dconf compile $B/etc/dconf/db/local $B/etc/dconf/db/local.d >> $L 2>&1 && sudo chmod 644 $B/etc/dconf/db/local && ls -l $B/etc/dconf/db/local >> $L && ok p3-dconf
fi
if st p3-initramfs; then
  $C update-initramfs -u -k all >> $L 2>&1 && ok p3-initramfs
  echo "initramfs rc=$?" >> $L
fi
echo "P3-DONE $(date -u +%T)" >> $L
