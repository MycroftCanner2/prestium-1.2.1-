# source me: mounts + chroot helper for v20/rootfs
bash /workspace/work/prestium/v20/host.sh >/dev/null 2>&1
B=/workspace/work/prestium/v20/rootfs
mountpoint -q $B/proc || sudo mount -t proc proc $B/proc
mountpoint -q $B/sys || sudo mount --rbind /sys $B/sys
mountpoint -q $B/dev || sudo mount --rbind /dev $B/dev
mountpoint -q $B/dev/pts || sudo mount -t devpts devpts $B/dev/pts 2>/dev/null
sudo rm -f $B/etc/resolv.conf; sudo cp /etc/resolv.conf $B/etc/resolv.conf
printf '#!/bin/sh\nexit 101\n' | sudo tee $B/usr/sbin/policy-rc.d >/dev/null; sudo chmod 755 $B/usr/sbin/policy-rc.d
C="sudo chroot $B env DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 PATH=/usr/sbin:/usr/bin:/sbin:/bin http_proxy= https_proxy= HTTP_PROXY= HTTPS_PROXY="
O="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -y"
