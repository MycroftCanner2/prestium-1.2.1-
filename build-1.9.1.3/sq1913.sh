#!/bin/bash
# 1.9.1.3 squash: zstd level 1 (fits the ~60 min sandbox uptime on 2 cores), writes .part, renamed only on success
cd /workspace/work/prestium/v20
rm -f iso/live/filesystem.squashfs.part
sudo mksquashfs rootfs iso/live/filesystem.squashfs.part -comp zstd -Xcompression-level 1 -b 1M -noappend -no-progress -processors $(nproc) \
  -wildcards -e 'proc/*' 'sys/*' 'dev/*' 'run/*' 'tmp/*' 'var/tmp/*' 'var/cache/apt/*.bin' 'boot/initrd.img*.old' > sq1913.log 2>&1
RC=$?; echo "SQ-EXIT $RC" >> sq1913.log
if [ $RC = 0 ]; then sudo chown $(id -u) iso/live/filesystem.squashfs.part; sync; mv -f iso/live/filesystem.squashfs.part iso/live/filesystem.squashfs; sync; fi
