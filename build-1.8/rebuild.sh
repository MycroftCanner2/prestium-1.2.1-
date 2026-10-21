#!/bin/bash
bash /workspace/work/prestium/v19/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v19; R=rootfs; Z="-comp zstd -Xcompression-level 15 -noappend -quiet -no-progress"
sudo rm -rf st-a st-b st-c L10 L25; mkdir -p st-a/usr/share st-b/usr/share st-c/usr/share L10/usr L25/usr
for d in icons locale; do sudo cp -al $R/usr/share/$d st-a/usr/share/; done
for d in doc gimp help man perl zoneinfo; do sudo cp -al $R/usr/share/$d st-b/usr/share/; done
for d in $(ls $R/usr/share); do case " icons locale doc gimp help man perl zoneinfo " in *" $d "*) ;; *) sudo cp -al $R/usr/share/$d st-c/usr/share/;; esac; done
sudo cp -al $R/usr/lib L10/usr/
for d in $(ls $R/usr); do case $d in lib|share) ;; *) sudo cp -al $R/usr/$d L25/usr/;; esac; done
sudo chown root:root st-a st-b st-c L10 L25 st-?/usr st-?/usr/share L10/usr L25/usr
sudo chmod 755 st-a st-b st-c L10 L25 st-?/usr st-?/usr/share L10/usr L25/usr
cd iso/live
sudo mksquashfs ../../rootfs 00-system.squashfs $Z -e usr opt & 
sudo mksquashfs ../../L10 10-usr-lib.squashfs $Z &
sudo mksquashfs ../../st-a 20-usr-share-a.squashfs $Z &
sudo mksquashfs ../../st-b 20-usr-share-b.squashfs $Z &
sudo mksquashfs ../../st-c 20-usr-share-c.squashfs $Z &
sudo mksquashfs ../../L25 25-usr-rest.squashfs $Z &
wait
ls -la; echo REBUILD-DONE
