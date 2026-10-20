#!/bin/bash
bash /workspace/work/prestium/v19/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v19; P=/workspace/work/prestium
sudo rm -f t4.squashfs; sudo mksquashfs t4 t4.squashfs -comp zstd -noappend -quiet -no-progress -all-root
if [ -z "$SKIPMAIN" ]; then
if [ -z "$SKIPMAIN" ]; then
sudo rm -f $P/Prestium-1.8-amd64.iso
sudo xorriso -as mkisofs -r -J -joliet-long -l -V PRESTIUM -isohybrid-mbr $P/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e efiboot.img -no-emul-boot -isohybrid-gpt-basdat -o $P/Prestium-1.8-amd64.iso iso 2>&1 | tail -1
sudo chown $(id -u) $P/Prestium-1.8-amd64.iso
fi
fi
sudo rm -f selftest.iso
sudo xorriso -as mkisofs -r -J -joliet-long -l -V PRESTIUM -isohybrid-mbr $P/isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e efiboot.img -no-emul-boot -isohybrid-gpt-basdat -o selftest.iso \
  -graft-points iso /live/99-selftest.squashfs=t4.squashfs 2>&1 | tail -1
sudo chown $(id -u) selftest.iso
ls -la $P/Prestium-1.8-amd64.iso selftest.iso; echo ISO-DONE
