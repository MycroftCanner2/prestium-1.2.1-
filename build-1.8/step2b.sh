cd /workspace/work/prestium/v19; source chroot.sh
$C apt-get $O install --no-install-recommends memlockd
$C apt-get $O purge linux-headers-5.10.0-19-amd64 linux-headers-5.10.0-19-common linux-image-6.1.0-53-amd64
$C apt-get $O autoremove --purge
$C sh -c "dpkg -l | awk '/^rc/{print \$2}' | xargs -r dpkg --purge"
sudo rm -f rootfs/etc/modprobe.d/r8168-dkms.conf rootfs/etc/modprobe.d/dkms.conf
$C dpkg --audit && echo AUDIT-OK
$C dpkg -l | grep -E '^ii +(gcc|g\+\+|make|build-essential|linux-|cpp)' 
ls rootfs/boot rootfs/lib/modules rootfs/usr/src
echo STEP2B-DONE
