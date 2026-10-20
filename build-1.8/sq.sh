#!/bin/bash
bash /workspace/work/prestium/v19/host.sh >/dev/null 2>&1
# usage: sq.sh <name> <exclude patterns...>
cd /workspace/work/prestium/v19; n=$1; shift
sudo rm -f iso/live/$n.squashfs
sudo mksquashfs rootfs iso/live/$n.squashfs -comp zstd -Xcompression-level 15 -noappend -quiet -no-progress -wildcards -e "$@"
ls -la iso/live/$n.squashfs; echo "$n DONE $(date -u)"
