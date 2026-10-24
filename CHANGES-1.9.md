# Prestium 1.9

Built 2026-10-22/23 as a **Debian 13 (trixie) rebase**. The rootfs is a fresh trixie amd64
`mmdebstrap`, with the 1.8 package set installed on top. Every Prestium customization from 1.8
was carried over: 77 Prestium-only files plus 12 changed package conffiles, and the users, groups,
units, menus and app configs. The look and UI are the same as 1.8.
Following Prestium's standing policy, it matches **Tails 7.15** for hardware support: same Debian
release, same kernel line and the same firmware set.
The ISO is `Prestium-1.9-amd64.iso` (SHA-256 `2a88ecf404b35ff8a4038d1b8db393a8d50fa5118629aa3d7814eb2e7ca621cc`, 2,346,516,480 bytes). The 1.7 and 1.8 torrents and the
1.8 ISO are unchanged. There is no 1.9 torrent.

## Versions
| Component | 1.8 | 1.9 |
|---|---|---|
| Base | Debian 12 bookworm | **Debian 13 trixie** (trixie, -updates, -security; -backports for firmware only), 1,255 packages, `dpkg --audit` clean |
| Kernel | 6.1.0-54 (6.1.190-1) | **6.12.113+deb13-amd64 (6.12.113-1, trixie-security)**, signed by Debian (Tails 7.15 ships 6.12.111-1, the same line) |
| Firmware | firmware-nonfree 20230210 | **firmware-nonfree 20260916-1~bpo13+1** (= the Tails 7.15 version), the same 24 firmware packages as Tails + atmel-firmware, wireless-regdb 2026.05.30, **firmware-sof-signed 2026.09.1-1** (Surface/modern Intel audio), amd64-microcode 3.20250311.1, intel-microcode 3.20251111.1 |
| live-boot | 20230131 | 1:20250815~deb13u1 (Prestium SATA/CD fallback patch re-applied) |
| systemd | 252 | 257.13 |
| Tor | 0.4.9.14 | 0.4.9.14 (deb.torproject.org trixie) + Nyx 2.1.0 |
| i2pd | 3.0.0 (bookworm deb) | **3.0.0-1trixie1** (official PurpleI2P trixie deb, SHA-256 c48c9e2e…be70) |
| LibreWolf | 158.0-1 | **158.0.1-2** (repo.librewolf.net), the eMudhra root block and all Prestium prefs/policies kept |
| Tor Browser | 15.0.26 | 15.0.26 (signature-checked, same file as 1.8) |
| eMudhra (Tails 7.15.1 match) | ca-certificates 20250419~deb12u1 | **ca-certificates 20250419+deb13u1** (trixie-security, Debian bug #1151413): "emSign ECC Root CA - G3" and "AAA Certificate Services" (Comodo) distrusted system-wide for OpenSSL/GnuTLS/curl/p11-kit, byte-identical system CA bundle to Tails 7.15.1; emSign Root CA - C1/G1 and ECC C3 stay trusted, as in Tails and Debian |
| Firefox (local-only) | 158.0.1 | 158.0.1 (signature-checked) |
| Node.js / The Lounge | 24.22.1 / 4.5.2 | 24.22.1 (sig-checked) / 4.5.2 |
| Feather | 2.8.1 | 2.8.1 (sig-checked) |
| KeePassXC | 2.7.12 | **2.8.0** AppImage (sig-checked) |
| OnionShare | — | **2.6.3-1+deb13u2** (`onionshare` + `onionshare-cli`, as in Tails) |
| Archive manager | — | **file-roller 44.5-1** + 7zip 25.01 + p7zip-full (as in Tails 7) |
| LibreOffice / GIMP / VLC | 7.4 / 2.10 / 3.0.21 | 25.2.3 / 3.0.4 / 3.0.24 |
| Gajim | 1.7 + gajim-omemo | 2.1.1 (OMEMO built in) |
| AppArmor | 3.0.8 | 4.1.0 |
| StormyCloud reseed file | 2026-10-22 | refreshed 2026-10-22 (SHA-256 e88eaeeb…584f, 61 router infos, signature checked) |

## New in 1.9
- **Secure Boot** (like Tails): UEFI boots Debian's Microsoft-signed `shimx64.efi`
  (shim-signed 1.51~1+deb13u1+16.1-2~deb13u1). Shim loads Debian's signed GRUB, `gcdx64.efi`
  (grub-efi-amd64-signed 1+2.12+9+deb13u2), and GRUB loads the Debian-signed kernel. `mmx64.efi` (MokManager) is included.
  So 1.9 boots on Surface devices and laptops with Secure Boot left **on**. With Secure Boot on, the kernel also enters lockdown (integrity) mode.
  BIOS boot (isolinux) and 32-bit UEFI (`bootia32.efi`, unsigned, as in 1.8) are kept, and the ISO is hybrid (BIOS + UEFI, DVD + USB). `.disk/info` added.
- Boot menus: the same entries, colours and timeouts as 1.8, labelled "Prestium 1.9". Every 1.8 kernel parameter is copied unchanged
  (`boot=live loop.max_loop=64 modprobe.blacklist=ahci/libahci/libata noprompt block.events_dfl_poll_msecs=1000 slab_nomerge slub_debug=FZP mce=0 vsyscall=none page_poison=1 init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 randomize_kstack_offset=on pti=on mds=full,nosmt quiet splash`, plus the nomodeset entry).
- **OnionShare** uses the system Tor through the control socket (`/run/tor/control`, user in `debian-tor`) and never starts its own tor. It runs as `user`, so no new firewall rule was needed (the control socket is a Unix socket, and onion traffic leaves through the `debian-tor` user).
- **Archive Manager** (file-roller) set as the default for zip/7z/tar/rar.
- The Lounge: `#i2p-help` removed from IRC2P and `#dev` removed from Ilita. This covers the config.js defaults and the per-boot user template.

## Fixed 1.8 defects (found by the 1.8 hardening capture)
1. **AppArmor now actually enforces.** Debian's `apparmor.service` has `ConditionPathExists=!/run/live/overlay/work`, so on a live system it
   skipped itself and 1.8 loaded **no** profiles. 1.9 clears that condition (`/etc/systemd/system/apparmor.service.d/prestium-live.conf`), so the profiles load in enforce mode. In the QEMU test of the 1.9 candidate, 147 profiles were loaded (24 enforce, 47 complain), with `i2pd` and `system_tor` in enforce mode, and `/usr/bin/tor` confined as `system_tor`.
2. **i2pd's random inbound port is really open now.** ferm loads its rules with the *legacy* xtables backend. 1.8's `prestium-i2pd-port`
   used `iptables` (the nft backend), so the ACCEPT went into a different table and the legacy `INPUT policy DROP` still dropped the port.
   1.9 uses `iptables-legacy`/`ip6tables-legacy`. Its own chain `PRESTIUM_I2PD` accepts only that boot's port: tcp NEW, plus udp.
3. **fs.protected_fifos is 2.** systemd's `protect-links.conf` sorted after `99-prestium-hardening.conf` and reset it to 1. The Prestium file is now
   `/etc/sysctl.d/zz-prestium-hardening.conf`, so it is applied last whatever other packages ship.

## Adaptations for trixie
- polkit `.pkla` files dropped: polkitd-pkla is gone in trixie. `49-prestium-power.rules` already grants the same rights (NetworkManager + power for `user`).
- `gajim-omemo` dropped: OMEMO is built into Gajim 2.
- `speedcrunch` is not in trixie, so it is taken from bookworm (0.12.0-6), pinned to that package only. The bookworm source was removed after the build.
- `gpg-wks-server` (it pulled in exim4, an MTA 1.8 never had) purged.
- t64 library renames: `libfuse2` → `libfuse2t64`, which the AppImages need, and the libcanberra/libfm modules were re-added by name.
  `binutils` (a development toolchain that came in as a dependency in 1.8) was deliberately not carried over.
- GpgFrontend 2.2.2: the signature is valid but the developer's signing key has since **expired**. The signature itself was made 2026-08-10, before the expiry.
- Audacity 4.0.1 AppImage: there is no upstream signature, so it is verified **only by the GitHub release SHA-256 digest**.
- Build-only apt sources (testing, bookworm) and their pins were removed from the image. apt caches were cleaned, `/etc/resolv.conf` is back to the dead `nameserver 127.0.0.1`, and `update_initramfs=yes` is restored.

## Unchanged from 1.8 (verified)
Firewall (ferm, OUTPUT DROP; only i2pd and Tor reach the network), local-only Firefox (7070/7685/9000 only), The Lounge (127.0.0.1:9000, per-boot token autologin),
I2P Torrents (127.0.0.1:7685, random per-boot path), i2pd tunnels (4444/4447/4450/7656/7659/7660 + IRC 6665–6672), bundled-file-only reseed,
emergency shutdown on boot-medium removal, memlockd, Tor-only time sync, UTC, no DHCP hostname, dead DNS, MAC randomization, root locked,
no passwordless sudo for mount, udisks2 VeraCrypt unlocker, the blocked kernel modules (Bluetooth, FireWire, DCCP, SCTP, RDS, TIPC, CAN, ATM, cramfs/freevxfs/jffs2, vivid, …),
and HexChat/qBittorrent/VeraCrypt app absent.

## Test results (QEMU)
**The final ISO (SHA-256 above) was not boot-tested, at the user's request.** It was built straight after the last rootfs fixes
so the ISO would be ready sooner. Its squashfs uses `zstd -Xcompression-level 6`, which builds faster than the earlier candidate's setting.
The results below come from the **earlier 1.9 candidate** (SHA-256 `312ac7bfcd375a275d5caa00d310ce04a1d7f5d5857c6de0077d90fe524577be`),
booted in QEMU/OVMF with **Secure Boot on** and an in-image self-test layer. The BIOS run was cancelled after a sandbox restart and was not repeated.

| Area | Result on the candidate |
|---|---|
| Secure Boot | Boots through MS-signed shim → Debian-signed GRUB → Debian-signed kernel with SB on; kernel lockdown `[integrity]` |
| Units | ferm, NetworkManager, i2pd, tor@default, lightdm, memlockd, prestium-usb-watchdog, thelounge, apparmor active; no failed units; time sync over Tor set the clock |
| AppArmor | active, 147 profiles; i2pd + system_tor enforce |
| Firewall | legacy OUTPUT/INPUT policy DROP; `PRESTIUM_I2PD` chain with that boot's port (tcp NEW + udp) in the legacy tables, nothing in nft |
| Leaks | clearnet direct blocked, DNS none, `prestium-htp` clearnet blocked, Tor SOCKS works; MAC randomized; resolv.conf dead |
| Local-only Firefox | reaches only 7070 + 9000 (7685 see below); clearnet, proxies, SAM, IRC tunnel, IPv6 all blocked; launcher refuses other URLs |
| The Lounge | 127.0.0.1:9000 only, autologin works, token not readable by `thelounge`; IRC2P connected through the i2pd 6668 tunnel; `#i2p-help`/`#dev` gone |
| VeraCrypt (udisks2) | wrong password refused, unlock/mount/write/lock OK |
| OnionShare | system Tor control socket works (bootstrap 100%), .onion URL created, no own tor |
| Archive Manager | zip, rar4 and rar5 extract; file-roller is the default for zip/rar |
| Apps | file-roller, LibreOffice, GIMP, VLC, KeePassXC, SpeedCrunch, Sylpheed, Gajim, QtQR, xterm, Nyx, LibreWolf and OnionShare opened windows. Feather, FeatherPad, GpgFrontend and Audacity showed no window in time under TCG emulation. Afterwards all four were opened in a chroot under Xvfb, with no missing libraries (FeatherPad's window is titled "Untitled", so the test pattern was wrong) |
| Emergency shutdown | after USB `device_del`, QEMU exited in 52 s. The faster `@prestium-emergency` fallback that came after this is **untested** |
| hardening | see the next section |

Defects the candidate found, fixed in the final rootfs but **not re-tested** on the final ISO:
- I2P Torrents (7685) did not listen. On trixie `/home/user` is 0700, so i2pd could not reach `~/Downloads/Torrents`. `prestium-i2pd-torrents` now runs `chmod go+x /home/user`, which allows only traversal.
- The trixie `clipit` is a transitional package that showed a "ClipIt has been deprecated" dialog. It was purged and Diodon autostarts instead.
- `firmware-nvidia-graphics` had been removed during the backports firmware upgrade. It was reinstalled (20260916-1~bpo13+1, the same as Tails) and the initrd was rebuilt.
- `kernel.io_uring_disabled = 2` was added (the candidate showed 0).
- Volume tray icon: it was missing in the VM, which has no sound card. Trixie's volumeicon embeds a hidden 1×1 icon when there is no ALSA card. Not changed.

## Hardening capture diff vs 1.8
Compared `hcap-1.8.txt` (1.8 ISO) with `hcap-1.9-uefi-sb.txt` (1.9 candidate). Both files are in `build-1.9/`.
- `fs.protected_fifos` 1 → **2**. `kernel.io_uring_disabled` did not exist on 6.1 → 0 on the candidate (**2** in the final rootfs, untested). All other sysctls are the same, apart from `user.max_user_namespaces`, which depends on RAM.
- AppArmor: 1.8 had `apparmor.service` skipped and **0** profiles. 1.9 has it active with **147** profiles, i2pd + system_tor enforce. Denials: 1.8 had `change_onexec unconfined system_tor`. 1.9 had only `mknod /run/i2pd/selftest.log`, the test layer's own log path, which is not in the image.
- Firewall: the rules are the same apart from renumbered uid/gid (debian-tor 107→102, thelounge 998→995, prestium-localweb 995→988, Tor Browser socks uid 110→996). The i2pd `PRESTIUM_I2PD` chain moved from nft, where it had no effect, to the legacy tables that ferm uses, and adds a conntrack NEW match. There are no nft tables at all now.
- Kernel lockdown: `[none]` → `[integrity]` (Secure Boot).
- Module blocklist: the same entries, all with `loaded=0`. libata is no longer loaded under QEMU.
- Unchanged: users and shells, root locked, the sudo rules, password needed for mount, polkit rules, coredumps off, NetworkManager MAC/hostname/DNS settings, IPv6 off, hostname.
