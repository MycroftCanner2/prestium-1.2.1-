#!/bin/bash
# Prestium 1.9.1.3 build chain (resumable, markers in bh/s1913/markers): sq1913 (zstd 1, no cache warm) -> mkboot1913 -> mkiso1913
cd /workspace/work/prestium/v20; L=build1913.log; M=bh/s1913/markers; mkdir -p $M
bash host.sh >/dev/null 2>&1
echo "BUILD-START $(date -u +%T) up=$(cut -d. -f1 /proc/uptime)s" >> $L
if [ ! -e $M/b-sq ]; then
  [ -e $M/apply ] || { echo "apply-1913 not done" >> $L; exit 1; }
  ./sq1913.sh; tail -1 sq1913.log >> $L
  sync; grep -q "SQ-EXIT 0" sq1913.log && touch $M/b-sq || { echo "SQ-FAIL" >> $L; exit 1; }
  echo "SQ-DONE $(date -u +%T)" >> $L
fi
if [ ! -e $M/b-boot ]; then ./mkboot1913.sh >> $L 2>&1 && touch $M/b-boot || { echo BOOT-FAIL >> $L; exit 1; }; fi
if [ ! -e $M/b-iso ]; then ./mkiso1913.sh >> $L 2>&1 && touch $M/b-iso || { echo ISO-FAIL >> $L; exit 1; }; fi
sync; echo "BUILD-DONE $(date -u +%T)" >> $L
