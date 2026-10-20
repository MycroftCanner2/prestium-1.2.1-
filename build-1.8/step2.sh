cd /workspace/work/prestium/v19; source chroot.sh
$C dpkg-divert --local --rename --add /usr/sbin/update-initramfs
$C ln -sf /bin/true /usr/sbin/update-initramfs
$C apt-get $O install linux-headers-6.1.0-54-amd64 memlockd
$C dpkg --configure -a
$C apt-get $O -f install
$C dpkg --audit && echo AUDIT-OK
$C dkms status
ls rootfs/lib/modules/6.1.0-54-amd64/updates/dkms 2>&1
echo STEP2-DONE
