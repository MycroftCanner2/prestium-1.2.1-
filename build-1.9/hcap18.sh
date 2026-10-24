#!/bin/bash
bash /workspace/work/prestium/v20/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v20; V=/workspace/work/prestium/v19; L=hcap18.serial; rm -f $L
K=$(grep -m1 -o 'boot=live[^"]*' $V/iso/boot/grub/grub.cfg | sed 's/ quiet splash//')
timeout 2400 qemu-system-x86_64 -m 2560 -smp 2 -drive file=hcap18.iso,media=cdrom,if=ide -kernel $V/iso/live/vmlinuz-6.1.0-54-amd64 -initrd $V/iso/live/initrd.img-6.1.0-54-amd64 -append "$K console=ttyS0" -display none -serial file:$L -no-reboot -nic user,model=e1000 &
QP=$!
for i in $(seq 1 230); do sleep 10; grep -q 'HCAP END' $L 2>/dev/null && break; kill -0 $QP 2>/dev/null || break; done
kill $QP 2>/dev/null; sed -n '/=== HCAP BEGIN/,/=== HCAP END/p' $L | tr -d '\r' > hcap-1.8.txt; wc -l hcap-1.8.txt; echo HCAP18-DONE
