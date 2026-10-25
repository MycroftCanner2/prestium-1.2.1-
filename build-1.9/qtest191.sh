#!/bin/bash
# Prestium 1.9.1 QEMU smoke test (UEFI + Secure Boot, USB stick): selftest layer, then
# A2 memory-erasure test: RAM dump before and after a normal shutdown (-no-shutdown keeps the RAM)
bash /workspace/work/prestium/v20/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v20; M=uefi-sb; L=serial-191-$M.log; S=qmon-191.sock; R=qtest191.log; rm -f $L $S
mkdir -p screens/raw
cp /usr/share/OVMF/OVMF_VARS_4M.ms.fd vars-sb-191.fd
Q="-machine q35,smm=on -global driver=cfi.pflash01,property=secure,value=on -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd -drive if=pflash,format=raw,unit=1,file=vars-sb-191.fd -device qemu-xhci,id=xhci -drive if=none,id=stick,format=raw,readonly=on,file=selftest191.iso -device usb-storage,bus=xhci.0,drive=stick,id=usbstick,removable=on"
timeout 9000 qemu-system-x86_64 -m 2560 -smp 2 $Q -vga std -audiodev none,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0 -display none -serial file:$L -no-reboot -no-shutdown -nic user,model=e1000 -monitor unix:$S,server,nowait &
QP=$!; T0=$(date +%s); echo "qemu pid $QP start $(date -u +%T)" >> $R
mon(){ echo "$1" | socat - UNIX-CONNECT:$S 2>/dev/null; }
while kill -0 $QP 2>/dev/null; do
  sleep 10; E=$(( $(date +%s) - T0 ))
  if [ $E -lt 120 ] || [ $(( E % 120 )) -lt 10 ]; then mon "screendump screens/raw/191-$M-$(printf %05d $E).ppm" >/dev/null; fi
  grep -q 'SELFTEST5 END' $L 2>/dev/null && break
done
echo "selftest end seen at $(date -u +%T) after $(( $(date +%s) - T0 ))s" >> $R
sleep 5; mon "screendump screens/raw/191-$M-final.ppm" >/dev/null
if grep -q WIPETEST-READY $L; then
  rm -f /tmp/mem-before.bin; mon "pmemsave 0 0xA0000000 /tmp/mem-before.bin" >/dev/null; sleep 5
  for i in $(seq 1 60); do [ -s /tmp/mem-before.bin ] && [ $(stat -c %s /tmp/mem-before.bin) -ge 2684354560 ] && break; sleep 5; done
  echo "before shutdown: $(python3 bh/s191/memscan.py /tmp/mem-before.bin) (dump $(stat -c %s /tmp/mem-before.bin))" >> $R; rm -f /tmp/mem-before.bin
fi
T1=$(date +%s); mon "system_powerdown" >/dev/null; echo "system_powerdown sent $(date -u +%T)" >> $R
st=""; for i in $(seq 1 180); do st=$(mon "info status" | tr -d '\r' | grep -o 'VM status: .*'); case "$st" in *shutdown*) break;; esac; kill -0 $QP 2>/dev/null || break; sleep 5; done
echo "after powerdown: '$st' after $(( $(date +%s) - T1 ))s" >> $R
mon "screendump screens/raw/191-$M-after-shutdown.ppm" >/dev/null
if grep -q WIPETEST-READY $L && kill -0 $QP 2>/dev/null; then
  rm -f /tmp/mem-after.bin; mon "pmemsave 0 0xA0000000 /tmp/mem-after.bin" >/dev/null; sleep 5
  for i in $(seq 1 60); do [ -s /tmp/mem-after.bin ] && [ $(stat -c %s /tmp/mem-after.bin) -ge 2684354560 ] && break; sleep 5; done
  echo "after shutdown: $(python3 bh/s191/memscan.py /tmp/mem-after.bin) (dump $(stat -c %s /tmp/mem-after.bin))" >> $R; rm -f /tmp/mem-after.bin
fi
mon "quit" >/dev/null; sleep 3; kill $QP 2>/dev/null
sed -n '/=== HCAP BEGIN/,/=== HCAP END/p' $L | tr -d '\r' > hcap-1.9.1-$M.txt; wc -l hcap-1.9.1-$M.txt >> $R
echo QTEST-DONE >> $R
