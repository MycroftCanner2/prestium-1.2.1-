# Prestium 1.9.1.3 build code

The scripts used to build `Prestium-1.9.1.3-amd64.iso`. They work on an unpacked Debian 13 (trixie) root filesystem
(`rootfs/` in this repository is that tree) and were run from a working directory that holds `rootfs/`, `iso/` and `bh/`
(backups and resume markers). Paths inside the scripts point at that working directory; adjust them for your machine.

## Order

1. `stage-1911/` (on top of the Debian 13 rootfs):
   - `apt1911.sh`: apt upgrade in the chroot, installs `pidgin` and `pidgin-otr`.
   - `pidgin/install-pidgin-1911.sh`: Pidgin over Tor (global SOCKS5 127.0.0.1:9050, remote DNS, logging off, OTR on),
     `pidgin-tor` wrapper, menu entry and the AppArmor profile `pidgin/usr.bin.pidgin` (complain mode).
   - `clockfix/`: `prestium-clockfix` + its systemd unit (sets the clock from Tor's consensus when the hardware clock is far off).
2. `stage-1912/apply-1912.sh`: the next set of changes (idempotent; takes backups of every file it changes on its first run).
   Uses `prestium-unlock-volume` (the Unlock Volume tool) and `install-pidgin-1911.sh.new` from the same directory.
3. `stage-1913/lurch/build-lurch.sh`: builds lurch 0.7.0 (OMEMO for libpurple) in the rootfs chroot and installs
   `purple-xmpp-carbons` and `libmxml1`. The build-only packages it installs and purges again are listed in
   `stage-1913/lurch/pkgs-build-only.txt`. It expects the lurch source in `stage-1913/lurch/src`:
   `git clone --recursive https://github.com/gkdr/lurch src` at commit `84f72d85a6735d64ade8f8bc8619bd61699298b2`
   (submodules `lib/axc` v0.3.4 `1d4454ea42d39a2064955f2a8de5f89787743f2a`, `lib/libomemo` v0.7.1 `7667e54d6488aba85701bb4dd6e09fd98bfb3a2c`).
4. `stage-1913/apply-1913.sh`: final changes (I2P outproxy by b32 address, Pidgin with lurch/carbons/OTR, Tor Browser
   NoScript toolbar button, version string). Uses `install-pidgin-1911.sh.new` and `prefs.xml.new` from the same directory.
5. `build1913.sh`: the build chain, resumable through marker files:
   - `sq1913.sh`: `rootfs/` -> `iso/live/filesystem.squashfs` (zstd level 1, single squashfs, no extra layers)
   - `mkboot1913.sh`: boot tree (BIOS isolinux, UEFI Debian-signed shim + GRUB for Secure Boot, 32-bit UEFI GRUB)
   - `mkiso1913.sh`: hybrid ISO with xorriso; refuses to build unless `iso/live` holds exactly one squashfs.

Helpers: `host.sh` (installs the host tools: mmdebstrap, squashfs-tools, xorriso, qemu, mtools, grub-common ...) and
`chenv.sh` (sourced by the stage scripts: mounts /proc, /sys, /dev into the rootfs and defines the chroot command).
`mkboot1913.sh` reads the syslinux, shim and GRUB binaries from an unpacked set of the trixie packages (`bl/x`) and the
1.8 isolinux menu header from the previous build tree.

Not included: logs, backups, test layers and test ISOs, QEMU images, and large binaries.
