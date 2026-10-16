# Prestium 1.2.1 -> 1.6 update branch

Branch `prestium-1.6-update`, forked from `main` (unmodified 1.2.1 extraction, left untouched).

Sources for what 1.3–1.6 changed: the official 1.4.1 CHANGELOG.md (Wayback copy of
prestium.org/release/Prestium-1.4.1/CHANGELOG.md), the developer's (Opicaak) Mastodon
announcements for 1.5 (2023-08-05) and 1.6 (2023-10-10).

This is a rebuild that follows those notes, not the developer's original 1.6 image,
which is no longer available. Built in a qemu-x86_64 chroot on 2026-10-15.

## Base system
- Debian 11 -> **Debian 12.15 (bookworm)**, full upgrade, no pending packages.
- Kernel **6.1.0-53-amd64 (6.1.187-1)**. The 1.5/1.6 notes mention 5.10.0-21/-22/-23;
  those are Debian 11 kernels and do not apply to a bookworm base. 5.10.0-19/-20 images purged
  (the 5.10.0-19 header packages are still installed).
- New live initrd built with live-boot modules; `iso/live/` and both boot menus
  (GRUB, isolinux) now point at 6.1.0-53, with `splash` added.
- `/usr/lib/os-release`: Prestium 1.6 (bookworm).

## Upgraded / added software
| Package | Version |
|---|---|
| i2pd | 2.61.0-1bookworm1 |
| LibreWolf | 157.0.1-1 |
| VeraCrypt | 1.26.29-1~deb12-1 |
| KeePassXC (AppImage) | 2.7.12 |
| Audacity (AppImage) | 4.0.1 |
| GpgFrontend (AppImage) | 2.2.2 |
| Feather wallet (replaces Monero GUI) | 2.8.1 |
| Gajim + omemo/openpgp/antispam/triggers/lengthnotifier | 1.7.3-2 (omemo 2.9.0-1) |
| qBittorrent / libtorrent-rasterbar | 4.5.2-3+deb12u1 / 2.0.8-1+b1 |
| Tor / Nyx | 0.4.9.11-0+deb12u1 / 2.1.0-2.2 |
| SpeedCrunch | 0.12.0-6 |
| xarchiver | 0.5.4.20-2 |
| Ristretto | 0.12.4-1 |
| pavucontrol / volumeicon-alsa | 5.0-2 / 0.5.1+git20170117 |
| LightDM | 1.26.0-8 |
| Plymouth (+ "connect" theme from adi1090x/plymouth-themes) | 22.02.122-3 |
| firmware-libertas (Marvell) | 20230210-5 |
| AppArmor + profiles (incl. usr.bin.i2pd) | 3.0.8-3 |

## Removed
- macchanger, intel-microcode, amd64-microcode, monero-wallet-gui.

## Configuration
- LightDM autologin for `user` into the Openbox session.
- Openbox: volume icon autostarts; menu entries for the new apps, Nyx, i2pd restart,
  and an I2P tunnel-hops submenu (1–7 hops).
- i2pd systemd drop-in uses `/var/lib/i2pd/` configs; outproxy set to StormyCloud
  (`5d4s7pcvfdpftfk7npc7hllyujhufsdprtrf4o53i44rgsa2xbwa.b32.i2p`, exit.stormycloud.i2p).

## Reconstructed (originals unavailable)
- i2pd webconsole dark theme (`/var/lib/i2pd/webconsole/style.css`) — written fresh.
- `prestium-tunnel-hops` script and its menu entries — written fresh.

## Not done
- The exact 1.6 HexChat server list: no copy of it could be found. HexChat keeps its 1.2.1 list.
- The ISO (Prestium-1.6-amd64.iso, SHA-256 424dd2a05155e8ea9f386d7ee8ef7ae9edb30b9a9acfb01932542e0c831dde9d) is not committed. It splits the system into six zstd squashfs layers in /live, which live-boot stacks.
- Untested on real hardware or in a VM.

## Large files
The four files over GitHub's 100 MB limit are left out of git, as on `main`; see LARGE_FILES.md. They are inside the built ISO.

## Fixes (2026-10-16)
- Reinstalled packages the Debian 12 upgrade had removed: LibreOffice (Writer/Calc/Impress/Draw/Math/Base), GIMP, VLC, Sylpheed, QtQR, xterm (x-terminal-emulator), NetworkManager + nm-applet, ModemManager, macchanger, mat2, ferm firewall (Prestium ruleset kept), Intel/AMD microcode, gvfs-backends, full Xorg meta + fonts, graphviz, obsession.
- Power: poweroff/reboot/restart-i2pd/tunnel-hops now work without a password for `user` (polkit rule + pkla + sudoers.d/prestium-power); Openbox menu falls back to `sudo -n`.
- LibreWolf: HTTPS-only/HTTPS-first fully disabled (I2P eepsites are plain HTTP; stock LibreWolf 157 policy had forced it on). System-wide hardening block in librewolf.cfg: resistFingerprinting + letterboxing, first-party isolation, WebGL/WebGPU/WebRTC/WebAudio off, JavaScript off, JS JIT (baseline/Ion/regexp) + WebAssembly + asm.js off, no prefetch/speculative connects, strict tracking protection, TLS 1.2+ with safe renegotiation, nothing persisted on shutdown, camera/mic/geo/notifications denied. NoScript and uBlock Origin bundled and force-installed (also in private windows). Overrides file also placed at the XDG path.
- Live ISO layers: 90-xorg, 91-librewolf, 92-apps.

## Network fixes (2026-10-16)
- Live base layer had NetworkManager, NetworkManager-dispatcher and ferm masked (build leftovers),
  so the ISO booted with no DHCP and no firewall. Unmasked via overlay whiteouts in `94-netfix.squashfs`.
  NetworkManager-wait-online stays masked, as in stock Prestium.
- ferm: Tor (`debian-tor`, uid 107) may now connect out, IPv4 and IPv6. `user` added to `debian-tor` so Nyx can read Tor's control socket.
- i2pd gets a random port (10000–30000) each boot, opened inbound for TCP/UDP only
  (`/usr/local/sbin/prestium-i2pd-port`, run as `ExecStartPre=+`). The router is no longer
  firewalled, which helps tunnel building.
- Boot: optical-drive fallback in live-boot, `loop.max_loop=64` for the 10+ squashfs layers.
- Tested in QEMU (IDE CD, e1000): ferm loads, NetworkManager gets DHCP, i2pd starts, Tor bootstraps to 100%.
