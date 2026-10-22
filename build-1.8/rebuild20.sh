#!/bin/bash
# resumable, memory-limited rebuild of all live layers (v20 changes)
bash /workspace/work/prestium/v19/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v19; R=rootfs; M=build20.done; touch $M
Z="-comp zstd -Xcompression-level 15 -noappend -quiet -no-progress -mem 900M -processors 2"
if ! grep -q staged $M; then
sudo rm -rf st-a st-b st-c L10 L25 L30; mkdir -p st-a/usr/share st-b/usr/share st-c/usr/share L10/usr L25/usr
for d in icons locale; do sudo cp -al $R/usr/share/$d st-a/usr/share/; done
for d in doc gimp help man perl zoneinfo; do sudo cp -al $R/usr/share/$d st-b/usr/share/; done
for d in $(ls $R/usr/share); do case " icons locale doc gimp help man perl zoneinfo " in *" $d "*) ;; *) sudo cp -al $R/usr/share/$d st-c/usr/share/;; esac; done
sudo cp -al $R/usr/lib L10/usr/
sudo mkdir -p L30; sudo cp -al $R/opt L30/; sudo chown root:root L30; sudo chmod 755 L30
for d in $(ls $R/usr); do case $d in lib|share) ;; *) sudo cp -al $R/usr/$d L25/usr/;; esac; done
sudo chown root:root st-a st-b st-c L10 L25 st-?/usr st-?/usr/share L10/usr L25/usr
sudo chmod 755 st-a st-b st-c L10 L25 st-?/usr st-?/usr/share L10/usr L25/usr
echo staged >> $M; echo "staged $(date +%T)"
fi
L="00-system:rootfs:-e usr opt 10-usr-lib:L10: 20-usr-share-a:st-a: 20-usr-share-b:st-b: 20-usr-share-c:st-c: 25-usr-rest:L25: 30-opt:L30:"
for spec in 00-system:rootfs 10-usr-lib:L10 20-usr-share-a:st-a 20-usr-share-b:st-b 20-usr-share-c:st-c 25-usr-rest:L25 30-opt:L30; do
  n=${spec%%:*}; src=${spec#*:}
  grep -q "^$n\$" $M && continue
  ex=""; [ $n = 00-system ] && ex="-e usr opt"
  sudo rm -f iso/live/$n.squashfs.new
  sudo mksquashfs $src iso/live/$n.squashfs.new $Z $ex || { echo "FAIL $n"; exit 1; }
  sudo mv iso/live/$n.squashfs.new iso/live/$n.squashfs; echo $n >> $M; echo "$n done $(date +%T) $(stat -c %s iso/live/$n.squashfs)"
done
ls -la iso/live; echo REBUILD20-DONE
