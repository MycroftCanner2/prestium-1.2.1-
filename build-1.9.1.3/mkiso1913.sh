#!/bin/bash
set -o pipefail
bash /workspace/work/prestium/v20/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v20; P=/workspace/work/prestium
[ -e iso/live/zfix-1912.squashfs ] && { echo "zfix layer still in iso/live"; exit 1; }
[ "$(ls iso/live/*.squashfs | wc -l)" = 1 ] || { echo "not exactly one squashfs in iso/live"; exit 1; }
X(){ xorriso -as mkisofs -r -J -joliet-long -l -iso-level 3 -V PRESTIUM -isohybrid-mbr isohdpfx.bin \
  -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e efiboot.img -no-emul-boot -isohybrid-gpt-basdat -o "$@"; }
OUT=$P/Prestium-1.9.1.3-amd64.iso
rm -f $OUT.part
X $OUT.part iso 2>&1 | tail -2 || { echo "xorriso failed; $OUT untouched"; rm -f $OUT.part; exit 1; }
sync; mv -f $OUT.part $OUT
(cd $P && sha256sum Prestium-1.9.1.3-amd64.iso > Prestium-1.9.1.3-amd64.iso.sha256)
ls -la $OUT; cat $OUT.sha256; echo ISO-DONE
