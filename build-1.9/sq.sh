#!/bin/bash
cd /workspace/work/prestium/v20
rm -f iso/live/filesystem.squashfs
sudo mksquashfs rootfs iso/live/filesystem.squashfs -comp zstd -Xcompression-level 6 -b 1M -noappend -no-progress -processors 2 \
  -wildcards -e 'proc/*' 'sys/*' 'dev/*' 'run/*' 'tmp/*' 'var/tmp/*' 'var/cache/apt/*.bin' 'boot/initrd.img*.old' > sq.log 2>&1
echo "SQ-EXIT $?" >> sq.log
sudo chown $(id -u) iso/live/filesystem.squashfs
