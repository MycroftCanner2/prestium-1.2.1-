B=/workspace/work/prestium/v19/rootfs
[ -e /proc/sys/fs/binfmt_misc/register ] || sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-x86_64 ] || echo ':qemu-x86_64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-x86_64-static:F' | sudo tee /proc/sys/fs/binfmt_misc/register >/dev/null
mountpoint -q $B/proc || sudo mount -t proc proc $B/proc
mountpoint -q $B/sys || sudo mount --rbind /sys $B/sys
mountpoint -q $B/dev || sudo mount --rbind /dev $B/dev
[ -f $B/../resolv.orig ] || sudo cp -a $B/etc/resolv.conf $B/../resolv.orig
sudo rm -f $B/etc/resolv.conf; sudo cp /etc/resolv.conf $B/etc/resolv.conf
C="sudo chroot $B env DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 PATH=/usr/sbin:/usr/bin:/sbin:/bin http_proxy= https_proxy= HTTP_PROXY= HTTPS_PROXY= ftp_proxy= FTP_PROXY="
O="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -y"
