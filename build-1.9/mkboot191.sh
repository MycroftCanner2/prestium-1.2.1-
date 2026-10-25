#!/bin/bash
# Prestium 1.9.1: ISO boot tree (BIOS isolinux + UEFI shim/GRUB signed by Debian = Secure Boot, + IA32 GRUB)
set -e
cd /workspace/work/prestium/v20
K=6.12.113+deb13-amd64
X=bl/x
I=iso
mkdir -p $I/live $I/isolinux $I/boot/grub $I/EFI/boot $I/EFI/debian $I/.disk
sudo cp rootfs/boot/vmlinuz-$K rootfs/boot/initrd.img-$K $I/live/; sudo chown $(id -u) $I/live/vmlinuz-$K $I/live/initrd.img-$K; chmod 644 $I/live/*-$K
P="boot=live loop.max_loop=64 modprobe.blacklist=ahci modprobe.blacklist=libahci modprobe.blacklist=libata noprompt block.events_dfl_poll_msecs=1000 slab_nomerge slub_debug=FZP mce=0 vsyscall=none page_poison=1 init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 randomize_kstack_offset=on pti=on mds=full,nosmt spec_store_bypass_disable=on debugfs=off intel_iommu=on amd_iommu=force_isolation iommu=force iommu.strict=1 efi=disable_early_pci_dma module.sig_enforce=1 quiet splash"
PN="boot=live loop.max_loop=64 nomodeset modprobe.blacklist=ahci modprobe.blacklist=libahci modprobe.blacklist=libata noprompt block.events_dfl_poll_msecs=1000 slab_nomerge slub_debug=FZP mce=0 vsyscall=none page_poison=1 init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 randomize_kstack_offset=on pti=on mds=full,nosmt spec_store_bypass_disable=on debugfs=off intel_iommu=on amd_iommu=force_isolation iommu=force iommu.strict=1 efi=disable_early_pci_dma module.sig_enforce=1 quiet splash"
# --- BIOS: isolinux (trixie syslinux 6.04), same menu look as 1.8
cp $X/usr/lib/ISOLINUX/isolinux.bin $I/isolinux/; cp $X/usr/lib/syslinux/modules/bios/*.c32 $I/isolinux/
cp $X/usr/lib/ISOLINUX/isohdpfx.bin isohdpfx.bin
{ sed -n '1,/^LABEL linux/p' ../v19/iso/isolinux/isolinux.cfg | sed '$d'
cat <<ISO
LABEL linux
  MENU LABEL Prestium 1.9.1 [BIOS/ISOLINUX]
  MENU DEFAULT
  KERNEL /live/vmlinuz-$K
  APPEND initrd=/live/initrd.img-$K $P

LABEL nomodeset
  MENU LABEL Prestium 1.9.1 [BIOS/ISOLINUX] (nomodeset)
  KERNEL /live/vmlinuz-$K
  APPEND initrd=/live/initrd.img-$K $PN

LABEL nocammic
  MENU LABEL Prestium 1.9.1 [BIOS/ISOLINUX] (camera and microphone off)
  KERNEL /live/vmlinuz-$K
  APPEND initrd=/live/initrd.img-$K $P prestium.nocammic
ISO
} > $I/isolinux/isolinux.cfg
# --- GRUB menu (same entries/params as 1.8)
mkcfg(){ cat <<G
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660

insmod all_video
insmod font

set default="0"
set timeout=$1

menuentry "Prestium 1.9.1 [EFI/GRUB]" {
    search --no-floppy --set=root --label PRESTIUM
    linux (\$root)/live/vmlinuz-$K $P
    initrd (\$root)/live/initrd.img-$K
}

menuentry "Prestium 1.9.1 [EFI/GRUB] (nomodeset)" {
    search --no-floppy --set=root --label PRESTIUM
    linux (\$root)/live/vmlinuz-$K $PN
    initrd (\$root)/live/initrd.img-$K
}

menuentry "Prestium 1.9.1 [EFI/GRUB] (camera and microphone off)" {
    search --no-floppy --set=root --label PRESTIUM
    linux (\$root)/live/vmlinuz-$K $P prestium.nocammic
    initrd (\$root)/live/initrd.img-$K
}
G
}
mkcfg 3 > $I/boot/grub/grub.cfg
mkcfg 30 > $I/EFI/boot/grub.cfg
# stub read by Debian's signed GRUB (built-in prefix /EFI/debian) from the ESP -> real menu on the ISO
cat > $I/EFI/debian/grub.cfg <<'G'
search --no-floppy --set=root --label PRESTIUM
if [ -z "$root" ]; then search --no-floppy --set=root --file /.disk/info; fi
set prefix=($root)/boot/grub
configfile $prefix/grub.cfg
G
# --- UEFI x64: Debian-signed shim (Microsoft UEFI CA) -> Debian-signed GRUB (CD image) -> Debian-signed kernel
cp $X/usr/lib/shim/shimx64.efi.signed $I/EFI/boot/bootx64.efi
cp $X/usr/lib/shim/mmx64.efi.signed  $I/EFI/boot/mmx64.efi
cp $X/usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed $I/EFI/boot/grubx64.efi
# --- UEFI ia32 (32-bit firmware tablets; no Secure Boot chain exists for ia32 in Debian, as in 1.8)
cat > /tmp/ia32-embed.cfg <<'G'
search --no-floppy --set=root --label PRESTIUM
set prefix=($root)/boot/grub
configfile $prefix/grub.cfg
G
grub-mkimage -d $X/usr/lib/grub/i386-efi -O i386-efi -o $I/EFI/boot/bootia32.efi -p /boot/grub -c /tmp/ia32-embed.cfg \
  part_gpt part_msdos fat iso9660 search search_label search_fs_file configfile normal linux all_video font gfxterm echo test ls
# --- .disk/info (Debian/Tails convention; also what Debian's signed GRUB searches for)
echo "Prestium 1.9.1 \"trixie\" - amd64 live ($(date -u +%Y%m%d))" > $I/.disk/info
# --- El Torito EFI image (FAT ESP)
rm -f $I/efiboot.img; mkfs.msdos -C -n PRESTIUMEFI $I/efiboot.img 8192 >/dev/null
mmd -i $I/efiboot.img ::/EFI ::/EFI/boot ::/EFI/debian ::/boot ::/boot/grub
mcopy -i $I/efiboot.img $I/EFI/boot/bootx64.efi $I/EFI/boot/grubx64.efi $I/EFI/boot/mmx64.efi $I/EFI/boot/bootia32.efi $I/EFI/boot/grub.cfg ::/EFI/boot/
mcopy -i $I/efiboot.img $I/EFI/debian/grub.cfg ::/EFI/debian/
mcopy -i $I/efiboot.img $I/EFI/debian/grub.cfg ::/boot/grub/grub.cfg
mdir -i $I/efiboot.img -/ ::/ | tail -15
echo MKBOOT-DONE
