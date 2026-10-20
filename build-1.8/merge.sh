#!/bin/bash
set -e
P=/workspace/work/prestium; cd $P
lower=""
for f in $(ls isobuild/live/*.squashfs | sort); do
  n=$(basename $f .squashfs); sudo mkdir -p /mnt/l/$n
  mountpoint -q /mnt/l/$n || sudo mount -t squashfs -o loop,ro $f /mnt/l/$n
  lower="/mnt/l/$n${lower:+:$lower}"
done
sudo mkdir -p /mnt/merged
mountpoint -q /mnt/merged || sudo mount -t overlay overlay -o ro,lowerdir=$lower /mnt/merged
echo "lower=$lower"
sudo mkdir -p $P/v19/rootfs
sudo rsync -aHAX --numeric-ids /mnt/merged/ $P/v19/rootfs/
sudo du -sh $P/v19/rootfs
echo MERGE-DONE
