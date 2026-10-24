#!/bin/bash
# fresh trixie amd64 base
set -e
bash /workspace/work/prestium/v20/host.sh
cd /workspace/work/prestium/v20
sudo rm -rf rootfs
sudo mmdebstrap --arch=amd64 --variant=apt --components="main contrib non-free non-free-firmware" \
  --include=ca-certificates,gnupg,curl,locales,apt-utils,dialog,usrmerge,systemd,systemd-sysv,dbus \
  trixie rootfs "deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware" \
  "deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware" \
  "deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware"
echo STAGE1-DONE
