#!/bin/bash
# Prestium 1.9.1 build chain (resumable): warm -> sq.sh (zstd 6) -> mkboot191 -> mkiso191
cd /workspace/work/prestium/v20; L=build191.log; M=bh/s191/markers
echo "BUILD-START $(date -u +%T)" >> $L
if [ ! -e $M/b-sq ]; then
  echo "WARM-START $(date -u +%T)" >> $L
  sudo find rootfs -xdev -type f -print0 | sudo xargs -0 -P48 -n100 cat >/dev/null 2>&1
  echo "WARM-DONE $(date -u +%T)" >> $L
  ./sq.sh; tail -1 sq.log >> $L
  sync; sleep 2; grep -q "SQ-EXIT 0" sq.log && touch $M/b-sq || { echo "SQ-FAIL" >> $L; exit 1; }
fi
if [ ! -e $M/b-boot ]; then ./mkboot191.sh >> $L 2>&1 && touch $M/b-boot || { echo BOOT-FAIL >> $L; exit 1; }; fi
if [ ! -e $M/b-iso ]; then ./mkiso191.sh >> $L 2>&1 && touch $M/b-iso; fi
echo "BUILD-DONE $(date -u +%T)" >> $L
