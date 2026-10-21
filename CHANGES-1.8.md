# Prestium 1.8

Built 2026-10-20 from the 1.7 image (all live layers merged into one tree, upgraded and
hardened in a qemu-x86_64 chroot, then re-split into zstd squashfs layers).
`Prestium-1.7-amd64.iso.torrent` is unchanged.

## Updates
| Component | 1.7 | 1.8 |
|---|---|---|
| Debian bookworm | full upgrade | full upgrade (2026-10-20), `dpkg --audit` clean |
| Kernel | 6.1.0-53 (6.1.187-1) | **6.1.0-54 (6.1.190-1)**, new live initrd (live-boot `sr_mod`/SATA fallback kept) |
| qBittorrent (official AppImage, GPG-verified, key D8F3 DA77 AAC6 7410 5359 9C13 6E4A 2D02 5B7C C9A2) | 5.2.4 | **5.3.0** (AppImage SHA-256 1c64f2e95740be41f2822f909f56e4dd0da2637f312098a06da113d7add7418b) |
| Tor | 0.4.9.14 | 0.4.9.14 (latest in deb.torproject.org) |
| LibreWolf | 158.0-1 | 158.0-1 (latest in repo) |
| i2pd | 2.61.0 | 2.61.0 (repo; upstream 3.0.0 was released today and is not packaged for bookworm yet) |
| Tor Browser | 15.0.25 | 15.0.25 |
| Feather | 2.8.1 | 2.8.1 (latest) |
| StormyCloud reseed file | old | refreshed 2026-10-20 (SHA-256 8abb064e5490464bd211786fdc1d11bd288153a21a19a6a3941bad2bd0582795) |

## Amnesic protections (modelled on Tails)
- **Emergency shutdown** (`prestium-usb-watchdog.service`): pulling the USB stick or ejecting the
  DVD powers the machine off at once (`systemctl --force poweroff`, then sysrq `o` as a fallback).
  Polling uses bash builtins only; `memlockd` keeps bash/systemctl/sleep in RAM so it still works
  with the medium gone. Not armed with `toram`; paused during suspend.
- **Memory wipe**: `init_on_free=1 init_on_alloc=1 page_poison=1` kept; added
  `page_alloc.shuffle=1 randomize_kstack_offset=on pti=on`. Freed RAM is zeroed, so the power-off
  leaves nothing behind.
- **Time over Tor** (`prestium-timesync`): after Tor bootstraps, the clock is set from the median of
  HTTPS `Date` headers fetched through Tor by an unprivileged `prestium-htp` user that the
  firewall lets reach only 127.0.0.1:9050. No NTP, no clearnet.
- **UTC** system clock / timezone (same for every user).
- **Hardware hiding from malware**: NetworkManager never sends the hostname over DHCP
  (`hostname-mode=none`), never writes resolv.conf (`dns=none`); `/etc/resolv.conf` points at a
  dead local resolver, so nothing can resolve clearnet names. Existing MAC randomization,
  connectivity-check off and IPv6 privacy kept.

## Hardening
- Firewall (ferm) unchanged: OUTPUT DROP; only i2pd (uid 2000) and Tor (debian-tor) reach the
  network; `user` may only reach local proxy ports. One new rule: `prestium-htp` -> 127.0.0.1:9050.
  i2pd's random inbound port kept.
- `sudo`: passwordless `mount` and `uptime` removed (passwordless `mount` was a root escalation
  that could bypass the firewall).
- VeraCrypt app removed. Its passwordless root helper (`sudo veracrypt --core-service`) accepted
  any mount request, so any program could use it to become root and turn off the firewall.
  It is replaced by **Unlock VeraCrypt Volume** (`/usr/local/bin/prestium-unlock-veracrypt`),
  which unlocks VeraCrypt file containers, partitions and drives through udisks2 + cryptsetup,
  like Tails. Volumes always mount under `/media/user` with `nosuid,nodev`; no root rule is needed.
  Supports password, PIM, hidden volumes, Windows system volumes and keyfiles.
  It cannot create new volumes. `veracrypt_grp`, `/etc/sudoers.d/veracrypt` and the unused
  wxWidgets libraries are gone. A polkit rule lets the desktop user unlock internal-disk partitions.
- root account locked.
- sysctl: ptrace_scope 2, unprivileged BPF off, BPF JIT hardening, sysrq off, protected
  fifos/regular files, no ICMP redirects / source routing.
- Unused kernel modules blocked: FireWire, DCCP, SCTP, RDS, TIPC, legacy network protocols,
  CAN, ATM, cramfs/freevxfs/jffs2, vivid.
- i2pd: I2PControl disabled (unused, default password).
- Apt/man-db/fstrim/e2scrub timers disabled (nothing to do on a live system).

## Clean-up
- Removed: stale Monero SOCKS tunnel (port 4448; no Monero GUI since 1.6), old kernel 6.1.0-53,
  5.10 headers, gcc/make toolchain, r8168-dkms leftovers, build-machine resolv.conf
  (192.168.1.100 / 8.8.8.8), apt lists/caches/logs, shell histories, dpkg/debconf backups.
- `/etc/i2pd/tunnels.conf` (never read; i2pd uses `/var/lib/i2pd/tunnels.conf`) replaced with a pointer.
- Kept (in use): HexChat SOCKS 4449, system HTTP proxy 4450 (wget/apt), SMTP 7659, POP3 7660.

## Tested (QEMU, x86_64)
Boots to LightDM; 0 failed units; ferm, NetworkManager, i2pd (5 client tunnels, reseed from file),
Tor, memlockd, watchdog active; MAC randomized; DHCP works; `user` direct clearnet blocked,
Tor SOCKS works; `sudo mount` and `sudo veracrypt` denied; VeraCrypt container unlock/mount/lock as the desktop user (nosuid,nodev); no DNS; clock set through Tor; root locked.
