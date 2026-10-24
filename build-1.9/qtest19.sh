#!/bin/bash
# usage: qtest19.sh bios|uefi-sb|uefi   -> boots test ISO (Prestium-1.9 + 99-selftest layer) through the real boot loader
bash /workspace/work/prestium/v20/host.sh >/dev/null 2>&1
cd /workspace/work/prestium/v20; M=$1; L=serial-$M.log; S=qmon-$M.sock; rm -f $L $S
mkdir -p screens/raw
case $M in
 bios) Q="-machine pc -drive file=selftest19.iso,media=cdrom,if=ide,readonly=on" ; EJ="eject -f ide0-cd0";;
 uefi-sb) cp /usr/share/OVMF/OVMF_VARS_4M.ms.fd vars-sb.fd
   Q="-machine q35,smm=on -global driver=cfi.pflash01,property=secure,value=on -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd -drive if=pflash,format=raw,unit=1,file=vars-sb.fd -device qemu-xhci,id=xhci -drive if=none,id=stick,format=raw,readonly=on,file=selftest19.iso -device usb-storage,bus=xhci.0,drive=stick,id=usbstick,removable=on"; EJ="device_del usbstick";;
 uefi) cp /usr/share/OVMF/OVMF_VARS_4M.fd vars-plain.fd
   Q="-machine q35 -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd -drive if=pflash,format=raw,unit=1,file=vars-plain.fd -device qemu-xhci,id=xhci -drive if=none,id=stick,format=raw,readonly=on,file=selftest19.iso -device usb-storage,bus=xhci.0,drive=stick,id=usbstick,removable=on"; EJ="device_del usbstick";;
esac
timeout 6000 qemu-system-x86_64 -m 2560 -smp 2 $Q -vga std -audiodev none,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0 -display none -serial file:$L -no-reboot -nic user,model=e1000 -monitor unix:$S,server,nowait &
QP=$!; T0=$(date +%s)
mon(){ echo "$1" | socat - UNIX-CONNECT:$S >/dev/null 2>&1; }
n=0
while kill -0 $QP 2>/dev/null; do
  sleep 10; E=$(( $(date +%s) - T0 ))
  # screenshots: every 10s for the first 2 min (boot menu/plymouth), then every 60s
  if [ $E -lt 120 ] || [ $(( E % 60 )) -lt 10 ]; then mon "screendump screens/raw/19-$M-$(printf %05d $E).ppm"; fi
  grep -q 'SELFTEST5 END' $L 2>/dev/null && break
done
echo "selftest end seen at $(date -u) after $(( $(date +%s) - T0 ))s"; sleep 5; mon "screendump screens/raw/19-$M-final.ppm"
mon "$EJ"; T1=$(date +%s)
for i in $(seq 1 60); do kill -0 $QP 2>/dev/null || break; sleep 2; done
if kill -0 $QP 2>/dev/null; then echo "VM STILL RUNNING 120s after '$EJ'"; mon "screendump screens/raw/19-$M-after-eject.ppm"; kill $QP; else echo "QEMU-EXIT after '$EJ': $(( $(date +%s) - T1 ))s"; fi
sed -n '/=== HCAP BEGIN/,/=== HCAP END/p' $L | tr -d '\r' > hcap-1.9-$M.txt; wc -l hcap-1.9-$M.txt
echo QTEST-DONE
