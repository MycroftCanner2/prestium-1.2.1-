#!/bin/bash
# stage4: caches, initramfs, bootloader debs
set -e
cd /workspace/work/prestium/v20; . ./chenv.sh
K=6.12.113+deb13-amd64
$C update-desktop-database /usr/local/share/applications || true
$C update-desktop-database /usr/share/applications || true
$C gtk-update-icon-cache -f -t /usr/local/share/icons/hicolor || true
$C fc-cache -s || true
$C glib-compile-schemas /usr/share/glib-2.0/schemas || true
# bootloader packages (not installed in the image; extracted on the host)
sudo rm -rf $B/tmp/bl; sudo mkdir -p $B/tmp/bl
$C sh -c "cd /tmp/bl && apt-get download shim-signed shim-helpers-amd64-signed grub-efi-amd64-signed grub-efi-amd64-bin grub-efi-ia32-bin grub-common isolinux syslinux-common"
ls -la $B/tmp/bl
# live initrd (live-boot hooks, Prestium live-boot patch)
$C mkinitramfs -o /boot/initrd.img-$K $K
ls -la $B/boot
echo STAGE4-DONE
