#!/bin/bash
# idempotent host prep (sandbox root is reset on restart)
grep -q "(none)" /etc/hosts || echo "127.0.0.1 (none)" | sudo tee -a /etc/hosts >/dev/null
which mmdebstrap mksquashfs xorriso qemu-system-x86_64 qemu-x86_64-static unmkinitramfs socat grub-mkimage >/dev/null 2>&1 || { sudo apt-get update -q >/dev/null 2>&1; sudo apt-get install -y -q mmdebstrap debootstrap squashfs-tools xorriso qemu-system-x86 qemu-user-static rsync initramfs-tools-core socat gnupg ovmf mtools dosfstools grub-common >/dev/null 2>&1; }
grep -q binfmt_misc /proc/mounts || sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
[ -e /proc/sys/fs/binfmt_misc/qemu-x86_64 ] || echo ':qemu-x86_64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-x86_64-static:F' | sudo tee /proc/sys/fs/binfmt_misc/register >/dev/null
echo HOST-OK
