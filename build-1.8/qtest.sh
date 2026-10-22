#!/bin/bash
bash /workspace/work/prestium/v19/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v19; L=serial.log; rm -f $L qmon.sock
K=$(grep -m1 -o 'boot=live[^"]*' iso/boot/grub/grub.cfg | sed 's/ quiet splash//')
timeout 4800 qemu-system-x86_64 -m 3072 -smp 2 -drive file=selftest.iso,media=cdrom,if=ide -kernel iso/live/vmlinuz-6.1.0-54-amd64 -initrd iso/live/initrd.img-6.1.0-54-amd64 -append "$K console=ttyS0" -display none -serial file:$L -no-reboot -nic user,model=e1000 -monitor unix:qmon.sock,server,nowait &
QP=$!
for i in $(seq 1 440); do sleep 10; grep -q 'SELFTEST4 END' $L 2>/dev/null && break; kill -0 $QP 2>/dev/null || break; done
echo "selftest end seen at $(date -u)"; sleep 5
# emergency shutdown test: eject the boot CD
echo "eject -f ide0-cd0" | socat - UNIX-CONNECT:qmon.sock 2>&1 | tail -1
T0=$(date +%s); for i in $(seq 1 45); do kill -0 $QP 2>/dev/null || break; sleep 2; done
if kill -0 $QP 2>/dev/null; then echo "VM STILL RUNNING 120s after eject"; kill $QP; else echo "QEMU-EXIT after eject: $(( $(date +%s) - T0 ))s"; fi
tail -5 $L
