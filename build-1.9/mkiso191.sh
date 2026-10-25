#!/bin/bash
# Prestium 1.9.1 ISO (same xorriso layout as 1.9) + selftest191.iso (ISO + test layer t5) for QEMU only
bash /workspace/work/prestium/v20/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v20; P=/workspace/work/prestium
X(){ xorriso -as mkisofs -r -J -joliet-long -l -iso-level 3 -V PRESTIUM -isohybrid-mbr isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e efiboot.img -no-emul-boot -isohybrid-gpt-basdat -o "$@"; }
OUT=$P/Prestium-1.9.1-amd64.iso
rm -f $OUT.part; X $OUT.part iso 2>&1 | tail -2 && mv -f $OUT.part $OUT
(cd $P && sha256sum Prestium-1.9.1-amd64.iso > Prestium-1.9.1-amd64.iso.sha256)
rm -f t5.squashfs; sudo mksquashfs t5 t5.squashfs -comp zstd -noappend -quiet -no-progress -all-root; sudo chown $(id -u) t5.squashfs
rm -f selftest191.iso; X selftest191.iso -graft-points iso /live/99-selftest.squashfs=t5.squashfs 2>&1 | tail -2
ls -la $OUT selftest191.iso; cat $OUT.sha256; echo ISO-DONE
