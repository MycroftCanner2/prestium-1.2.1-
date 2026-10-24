#!/bin/bash
bash /workspace/work/prestium/v20/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v20; P=/workspace/work/prestium
X(){ xorriso -as mkisofs -r -J -joliet-long -l -iso-level 3 -V PRESTIUM -isohybrid-mbr isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e efiboot.img -no-emul-boot -isohybrid-gpt-basdat -o "$@"; }
rm -f $P/Prestium-1.9-amd64.iso; X $P/Prestium-1.9-amd64.iso iso 2>&1 | tail -2
rm -f t5.squashfs; sudo mksquashfs t5 t5.squashfs -comp zstd -noappend -quiet -no-progress -all-root; sudo chown $(id -u) t5.squashfs
rm -f selftest19.iso; X selftest19.iso -graft-points iso /live/99-selftest.squashfs=t5.squashfs 2>&1 | tail -2
ls -la $P/Prestium-1.9-amd64.iso selftest19.iso; echo ISO-DONE
