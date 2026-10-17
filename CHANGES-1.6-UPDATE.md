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

## Package update, I2P-everywhere and browser/reseed changes (2026-10-16, still 1.6)
Version strings stay 1.6 (os-release, boot menus, ISO name). Shipped as one more live layer,
`live/95-update.squashfs` (zstd). It is a file-level diff of the rootfs, with overlay whiteouts for
removed files, on top of the unchanged layers 00-base..94-netfix. 12 layers in total, under `loop.max_loop=64`.

### Versions
| Package | before | now | source |
|---|---|---|---|
| Debian 12 + security | current | `apt full-upgrade`: nothing pending | deb.debian.org / security.debian.org |
| Kernel | 6.1.0-53-amd64 (6.1.187-1) | unchanged (newest bookworm kernel) | Debian |
| i2pd | 2.61.0-1bookworm1 | unchanged (newest release); PurpleI2P apt repo added | repo.i2pd.xyz |
| Tor | 0.4.9.11-0+deb12u1 | **0.4.9.14-1~d12.bookworm+1** (+ tor-geoipdb, deb.torproject.org-keyring) | deb.torproject.org |
| Nyx | 2.1.0-2.2 | unchanged (last upstream release is 2.1.0) | Debian |
| qBittorrent | 4.5.2-3+deb12u1 | **5.2.4** official AppImage, libtorrent 2.0 build | github.com/qbittorrent/qBittorrent |
| Feather | 2.8.1 | unchanged (newest) | featherwallet.org |
| LibreWolf | 157.0.1-1 | **158.0-1** (repo signing key refreshed) | repo.librewolf.net |

### Monero Wallet GUI removed
Feather is the only wallet. No Monero GUI binary, package, menu entry, desktop file or autostart
is left in any layer. The last remnant, an empty `~/.config/monero-project`, is whited out.
The i2pd client tunnel "Monero SOCKS Proxy" (127.0.0.1:4448) is still in tunnels.conf. Feather does not use it; it uses SOCKS 4447.

### qBittorrent 5.2.4 with native I2P
- AppImage SHA-256 `eda6c0ca39f9befb0cd111b76a3d8b8bf3fd859323f2d4aac8c18f63766c2a1a`. It matches
  the GitHub release digest and has a good signature from sledgehammer_999 (D8F3 DA77 AAC6 7410 5359 9C13 6E4A 2D02 5B7C C9A2).
- Extracted to `/opt/qbittorrent`, so no FUSE is needed. The `/usr/local/bin/qbittorrent` wrapper keeps the menu entry working. Debian's qbittorrent package is purged.
- `~/.config/qBittorrent/qBittorrent.conf` (live user + /etc/skel): I2P via SAM 127.0.0.1:7656,
  mixed mode off (I2P peers only), DHT/PeX/LSD off, UPnP/NAT-PMP off, anonymous mode, bound to lo/127.0.0.1.

### I2P for network apps
- i2pd SOCKS proxy enabled on 127.0.0.1:4447.
- Feather: proxy = I2P (SOCKS 127.0.0.1:4447), so it uses its I2P node list and I2P websocket. The first-run network page is skipped.
- Gajim: global proxy "I2P HTTP (i2pd 4444)". "I2P SOCKS (i2pd 4447)" and "Tor" (9050) are also defined.
- HexChat: unchanged (I2P SOCKS tunnel 4449, I2P IRC servers). Now also in /etc/skel.
- Sylpheed: template account "I2P mail (postman)", SMTP 127.0.0.1:7659 / POP3 127.0.0.1:7660.
- Everything else still uses `/etc/environment` http(s)_proxy = 127.0.0.1:4450 (I2P).

### Web browsers
- Menu: **Web Browser (I2P)** (`librewolf-i2p`, default profile, HTTP proxy 127.0.0.1:4444) and **Tor Browser**.
  The I2P WebConsole entry uses the I2P browser.
- `librewolf.cfg` Prestium block sets the I2P proxy only. The policies.json (NoScript + uBlock forced, HTTPS-only off, DoH off) is unchanged.
- Desktop files: `/usr/local/share/applications/librewolf.desktop` ("Web Browser (I2P)", also the http/https handler)
  and `torbrowser.desktop`. The default tint2 launcher (/etc/xdg) lists both.
- ferm unchanged: uid 1000 may already open TCP to any 127.0.0.1 port ≥1024, which covers 9050, 4444, 4447 and 7656.

### i2pd reseed: bundled StormyCloud su3 only
- `/var/lib/i2pd/stormycloud-i2pseeds.su3` was downloaded from https://reseed.stormycloud.org/i2pseeds.su3 on 2026-10-16.
  su3 version/date 1792180824 = 2026-10-16 20:00:24 UTC, 48,235 bytes, 61 RouterInfos,
  SHA-256 `389a8796bb9b840dcf4d9d0664663533d877ea35a462bae2f2bdabbcf9a8c044`, signer `admin@stormycloud.org`, RSA-SHA512-4096.
- The signing cert `certificates/reseed/admin_at_stormycloud.org.crt` is already shipped by the i2pd 2.61 package and is byte-identical to
  i2pd 2.61.0 `contrib/certificates/reseed/` (SHA-256 61a7535a…). Signature checked with openssl, and i2pd loaded all 61 routers with verify=true.
- `[reseed]`: `verify = true`, `file = /var/lib/i2pd/stormycloud-i2pseeds.su3`, `urls =`, `yggurls =`.
  In i2pd 2.61 `Reseeder::Bootstrap()`, a set `reseed.file` means only that file is used: there is no fallback to servers.
  Empty `urls`/`yggurls` also replace the compiled-in default list, so `ReseedFromServers()` would stop at "No reseed servers specified".
- Caveat: the bundled RouterInfos age. The image needs a fresh su3 regularly (re-download and rebuild), or bootstrapping will eventually fail.

### Build and test (2026-10-16)
- `Prestium-1.6-amd64.iso`, 2,011,299,840 bytes,
  SHA-256 `29a3e1d9d03c9a13cbc4826355764fbd4c5324573138f6d2d6762fc9ba8634fc`. It has 12 live layers (00-base … 95-update) and no test layer.
- Two leftover "Prestium 1.7" comments were reset to 1.6, in `/usr/local/bin/qbittorrent` and `/var/lib/i2pd/i2pd.conf`. No 1.7 version string remains.
- QEMU test (IDE CD, e1000, user-mode network). It booted the same ISO plus a test-only layer that turned on i2pd info logging and ran checks; that layer is not in the release ISO.
  Results:
  - autologin into Openbox; ferm, NetworkManager (DHCP), i2pd, Tor and LightDM all active, with no failed units.
  - Tor bootstrapped to 100%.
  - i2pd loaded its reseed certificates and the bundled su3, with no reseed download. i2pd opened no :80/:443 connections. It reached about 145 routers, with 52% tunnel success.
  - Listening on 127.0.0.1: SOCKS 4447, SAM 7656, HTTP 4444, Tor 9050.
  - qBittorrent 5.2.4 connected to SAM 7656 and listens only on 127.0.0.1.
  - No Monero GUI remnants.
  - The only firewall drops were IPv6 router solicitations.

## Tor Browser and tunnel-hops fix (2026-10-16, still 1.6)

### Tor Browser replaces "Web Browser (Tor)"
- Removed: `librewolf-tor`, `librewolf-tor.desktop`, the `PRESTIUM_BROWSER` switch in `librewolf.cfg`. LibreWolf is I2P-only.
- Added: official **Tor Browser 15.0.25** (`tor-browser-linux-x86_64-15.0.25.tar.xz`, 137,994,120 bytes,
  SHA-256 `37432d6f4d9b1f1190ba2cfbbd4ab9dad5ccd52c14aa47a21795d08273f4a165`), from dist.torproject.org.
  Its signature verifies with the Tor Browser Developers key `EF6E 286D DA85 EA2A 4BA7 DE68 4E2C 6E87 9329 8290`
  (signing subkey 022DA248432D2A0E0F54E65E316C1FACD62D07D9), and the hash matches `sha256sums-signed-build.txt`.
- Unpacked unmodified to `/opt/tor-browser`, owned by `user` so the browser can write its profile.
  The only addition is `Browser/distribution/policies.json` with `DisableAppUpdate` (a live image cannot keep updates; update by rebuilding).
- `/usr/local/bin/tor-browser` starts it with `TOR_SKIP_LAUNCH=1`, SOCKS 127.0.0.1:9050 and control socket `/run/tor/control`
  (cookie `/run/tor/control.authcookie`; `user` is in `debian-tor`). So the system Tor 0.4.9.14 carries the traffic,
  the bundled tor never runs, the ferm rule (only i2pd and debian-tor reach the network) still holds, and Nyx sees the circuits.
  New Identity and the circuit display work through the control socket.
- Menu "Tor Browser" and tint2 launcher `/usr/local/share/applications/torbrowser.desktop`.
- `Browser/libxul.so` (156,454,456 bytes) is over GitHub's limit and is in LARGE_FILES.md; take it from the tarball above.

### Changing tunnel hops broke the I2P proxy (fixed)
- Cause: `/var/lib/i2pd/tunnels.conf` had a stray uncommented `[SMTP]` header above the commented-out example, plus the real `[SMTP]` tunnel.
  i2pd tolerated the empty duplicate, but `prestium-tunnel-hops` wrote `inbound/outbound.length` into every section, including the empty one.
  i2pd then refused the whole file ("tunnels.conf(67): duplicate section name", 0 client tunnels), so the 4444 browser proxy,
  4449 HexChat, 4450 system proxy and the postman tunnels all vanished until the file was fixed by hand.
- Fix: the stray header is commented out (`#[SMTP]`).
- `prestium-tunnel-hops` rewritten: it changes only real tunnels (sections with a `type`), plus `[exploratory]` and `[socksproxy]` in i2pd.conf;
  checks the result for duplicate sections and keys the way i2pd reads it before replacing anything; keeps owner and mode;
  restarts i2pd and waits for 4444, and if it does not come back it restores the old files and says so.

### Build and test (Tor Browser / hops fix)
- `Prestium-1.6-amd64.iso`, 2,170,388,480 bytes, SHA-256 `eb9426b7a5d2c53881652fc82686e971caad9cef2532fe4757b32aa0ad7e4ca5`.
  Same 12 live layers; only 95-update changed. No test layer.
- QEMU (IDE CD, e1000, user-mode network), with a test-only layer:
  - All units active, no failed units. i2pd: 6 client tunnels; 4444, 4447, 4449, 4450, 7656, 7659, 7660 listening.
  - `prestium-tunnel-hops 5`, then 7, then 3, run as `user` through sudo like the menu: each time i2pd restarted with 6 client tunnels,
    no duplicate sections, all proxy ports back.
  - Through the 4444 proxy as `user`, after switching to 5 hops: `http://stats.i2p/` returned 200 (stats.i2p page).
  - Tor Browser (headless, as `user`): opened a control connection to the system Tor and loaded https://check.torproject.org/ —
    "Congratulations. This browser is configured to use Tor." The firewall would have blocked any direct connection.
  - No `librewolf-tor` file, desktop entry or `PRESTIUM_BROWSER` left; the menu shows "Tor Browser".
- Note for testing: ferm lets only `user` (uid 1000) connect to localhost proxy ports, so tests as root get "connection refused".
