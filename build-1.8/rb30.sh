#!/bin/bash
# rebuild only 30-opt after patch20b (The Lounge offline patches)
cd /workspace/work/prestium/v19
sudo rm -rf L30; sudo mkdir -p L30; sudo cp -al rootfs/opt L30/; sudo chown root:root L30; sudo chmod 755 L30
sudo rm -f iso/live/30-opt.squashfs.new
sudo mksquashfs L30 iso/live/30-opt.squashfs.new -comp zstd -Xcompression-level 15 -noappend -quiet -no-progress -mem 700M -processors 1 || { echo FAIL; exit 1; }
sudo mv iso/live/30-opt.squashfs.new iso/live/30-opt.squashfs; sudo rm -rf L30
ls -la iso/live/30-opt.squashfs; echo RB30-DONE
