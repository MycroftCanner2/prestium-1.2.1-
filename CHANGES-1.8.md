# Prestium 1.8

Built 2026-10-20 from the 1.7 image (all live layers merged into one tree, upgraded and
hardened in a qemu-x86_64 chroot, then re-split into zstd squashfs layers).
`Prestium-1.7-amd64.iso.torrent` is unchanged.

## Updates
| Component | 1.7 | 1.8 |
|---|---|---|
| Debian bookworm | full upgrade | full upgrade (2026-10-20), `dpkg --audit` clean |
| Kernel | 6.1.0-53 (6.1.187-1) | **6.1.0-54 (6.1.190-1)**, new live initrd (live-boot `sr_mod`/SATA fallback kept) |
| qBittorrent | 5.2.4 | **removed** (replaced by the i2pd 3.0 built-in torrent client, see below) |
| Tor | 0.4.9.14 | 0.4.9.14 (latest in deb.torproject.org) |
| LibreWolf | 158.0-1 | 158.0-1 (latest in repo) |
| i2pd | 2.61.0 | **3.0.0** (official PurpleI2P `i2pd_3.0.0-1bookworm1_amd64.deb`, SHA-256 f314659ac70617a9cdf1424417b099c2be7022b800f364ef5699233f39b2929a; adds libboost-json/url/program-options 1.81) |
| Tor Browser | 15.0.25 | **15.0.26** (2026-10-22, signature-checked) |
| Feather | 2.8.1 | 2.8.1 (latest) |
| StormyCloud reseed file | old | refreshed 2026-10-22 (SHA-256 1678013ff0a607e61667804c18bd9cfeb5c8456cd38a0d77c076ba801ee375b0) |

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

## i2pd 3.0.0 and the built-in torrent client
- i2pd 3.0.0: full SAM 3.3, SAM reconnect fix, faster LeaseSet lookups, fewer datagram losses,
  stalled UDP tunnel fixes, owner-only key files, stricter IPv4-mapped IPv6 rejection, updated reseed
  certificates. Prestium's own `/var/lib/i2pd/i2pd.conf` and `tunnels.conf` are kept (the package
  install had replaced them with symlinks to the stock `/etc/i2pd` files; restored), so reseeding is
  still bundled-file only and all tunnels (4444, 4447, 4449, 4450, 7656, SMTP, POP3) are unchanged.
- **qBittorrent removed** (/opt/qbittorrent, launcher, menu entry, MIME handlers; ~290 MB smaller).
- **I2P Torrents** (menu: Internet, and the `magnet:` / `.torrent` handler): i2pd's own torrent
  client (`type = torrents`) with I2P DHT, magnets, PEX and datagram trackers, which libtorrent-based
  clients can't do. Downloads go to `~/Downloads/Torrents`.
  - `prestium-i2pd-torrents` (i2pd `ExecStartPre`) writes the tunnel to
    `/var/lib/i2pd/tunnels.conf.d/torrents.conf` each boot, with transient keys (a new I2P identity
    every boot).
  - The Transmission-compatible RPC and web UI listen on 127.0.0.1:7685 only, under a random
    128-bit path generated each boot (`/run/prestium-torrents/url`, readable by `user` only).
    i2pd answers RPC with `Access-Control-Allow-Origin: *`, so without the secret path any web page
    open in a browser could add or delete torrents.
  - `~/Downloads/Torrents` is `user:i2ptorrents 2770`; i2pd runs with `SupplementaryGroups=i2ptorrents`
    and `UMask=0007`, so `user` can open, move and delete what i2pd downloads. AppArmor local rule
    lets i2pd write only there.
  - `prestium-torrents [magnet|file.torrent]` adds the torrent over RPC, then opens the web UI in
    Web Browser (I2P). The web UI files are upstream `contrib/torrents/web` from the 3.0.0 tag.
  - No firewall change: i2pd (uid 2000) already reaches the network, and `user` already reaches
    localhost high ports.
  - Downloads live in RAM like everything else; copy them to an unlocked encrypted volume to keep them.

## Tor Browser 15.0.26 (2026-10-22, still 1.8)
- `/opt/tor-browser` replaced with the official **Tor Browser 15.0.26** (`tor-browser-linux-x86_64-15.0.26.tar.xz`,
  137,985,168 bytes, SHA-256 `327ac7443724b9eb6d3697506391b110ee159739bdc14bd731caa6fc16ffbf74`) from dist.torproject.org.
  Its `.asc` verifies with the Tor Browser Developers key `EF6E 286D DA85 EA2A 4BA7 DE68 4E2C 6E87 9329 8290`
  (signing subkey 022DA248432D2A0E0F54E65E316C1FACD62D07D9), and the hash matches the signed `sha256sums-signed-build.txt`.
- Unpacked unmodified, owned by `user`; `Browser/distribution/policies.json` (`DisableAppUpdate`) and the
  `/usr/local/bin/tor-browser` launcher (system Tor: `TOR_SKIP_LAUNCH=1`, SOCKS 127.0.0.1:9050, `/run/tor/control`) kept.
- Bundled StormyCloud reseed file refreshed. Nothing else changed (only the `00-system` and `30-opt` layers were rebuilt).

## Local-only Firefox, The Lounge IRC, HexChat removed (2026-10-22, still 1.8)
### Firefox 158.0.1 (local-only)
- Official `firefox-158.0.1.tar.xz` from archive.mozilla.org (SHA-256
  `dce45470139242cf294eb6ada3d192a9bb334696842b02b71ade448a139eb41a`); the hash matches `SHA256SUMS`, whose
  `.asc` verifies with Mozilla's release key `14F2 6682 D091 6CDD 81E3 7B6D 61B7 B526 D98F 0353`
  (signing subkey `827E658608679618CD349F93678E455D76767AA3`). Unpacked unmodified to `/opt/firefox` (root-owned).
- It is **only** for Prestium's own pages: **I2P Router Console** (i2pd web console, 127.0.0.1:7070),
  **I2P Torrents** (127.0.0.1:7685 behind the per-boot secret path) and **IRC (The Lounge)** (127.0.0.1:9000).
  These menu entries (and the magnet/.torrent handler) now open in it instead of LibreWolf.
  Browsing stays in **Web Browser (I2P)** (LibreWolf) and **Tor Browser**, both unchanged.
- Enforcement, firewall first: `/usr/local/bin/prestium-localfox` starts Firefox through `sg prestium-localweb`,
  so every Firefox process has primary group `prestium-localweb`. ferm matches that group
  (`mod owner gid-owner`) before any other user rule: it may open TCP connections only to 127.0.0.1 ports
  7070, 7685 and 9000; everything else is logged and refused (no Internet, no i2pd 4444/4447/4450/SAM,
  no Tor 9050, no other local port, no IPv6 at all). The `user` account is a member of the group; being in
  it only ever restricts a process. The launcher also refuses any URL other than those three pages.
- Second layer, `/opt/firefox/distribution/policies.json`: updates (app, add-ons, system add-ons) off,
  telemetry/studies/Pocket/Firefox accounts/feedback off, no add-on installs, proxy locked to none,
  DNS-over-HTTPS off, captive-portal/connectivity checks, prefetch, Safe Browsing, region, translations,
  ML/AI chat, geolocation, GMP/DRM downloads off, website filter that blocks everything except
  `http://127.0.0.1/*`, history off (the per-boot secrets never land in places.sqlite). Otherwise Firefox defaults.
  Its profile is `~/.local/share/prestium-localfox` (in RAM like the rest of the live system).

### The Lounge 4.5.2 (IRC web client, self-hosted)
- `thelounge@4.5.2` from npm (npm registry tarball; the lockfile's sha512 integrity for thelounge 4.5.2 matches the registry's signed `dist.integrity`; pure JavaScript, no native modules),
  installed without install scripts in `/opt/thelounge`; runtime Node.js **24.22.1 LTS** (`node-v24.22.1-linux-x64.tar.xz`,
  SHA-256 `6c172a9ab6718f7b801fb5a7bd486af2ee5e32758086a04b84fcce2aa77095e6`, `SHASUMS256.txt.asc` signed by Node.js
  releaser key `5BE8 A3F6 C8A5 C01D 106C 0AD8 20B1 A390 B168 D356`), only `bin/node` kept, in `/opt/nodejs`.
  The Lounge 4.5 needs Node >= 22; Debian 12 has 18.
- `thelounge.service`: own unprivileged system user `thelounge`, `THELOUNGE_HOME=/var/lib/thelounge`,
  listens on **127.0.0.1:9000** only. systemd sandbox: NoNewPrivileges, no capabilities, ProtectSystem=strict,
  ProtectHome, PrivateTmp/Devices, IPAddressAllow=localhost / IPAddressDeny=any, etc.
- ferm: the `thelounge` user may connect only to 127.0.0.1:6665-6672 (the i2pd IRC tunnels); no IPv6, nothing else.
- Config: private mode; `prefetch` off, media previews off, no uploads, no message logs on disk
  (`messageStorage: []`), no identd/oidentd/LDAP/WEBIRC, empty quit message.
  (The Lounge answers CTCP VERSION with "thelounge -- https://thelounge.chat", without a version number.)
- The Lounge never contacts the Internet itself: its GitHub changelog/update check (`plugins/changelog.js`) and the
  `yarn outdated` package check (`plugins/packages/index.js`) are patched to no-ops (`build-1.8/patch20b.sh`).
  Unpatched, the firewall-blocked GitHub request crashed the server about 10 s after every start.
- **Sign-in**: one pre-provisioned user, `prestium`. On every service start `prestium-thelounge-setup`
  (ExecStartPre, root) creates a random password (bcrypt in the user file) and a new random 512-bit login token;
  only the token's SHA-512 goes into The Lounge's user file. The token is in `/run/prestium-thelounge/token`
  (`root:user 0640`). **IRC (The Lounge)** (`prestium-irc`) opens
  `http://127.0.0.1:9000/packages/thelounge-prestium-autologin/autologin.html#<token>`: a tiny local The Lounge
  package on The Lounge's own origin stores the token where The Lounge keeps a remembered sign-in and opens the
  client, so there is no login screen. The token is in the URL fragment (never sent to the server). Without it,
  other local programs or web pages (any origin) get only the sign-in screen and would need the random password.
  This is the same idea as the torrent UI's per-boot secret path. If you press "Sign out", the password for
  user `prestium` is in `/run/prestium-thelounge/password` (also `user`-only); restarting the service issues a new token.
  First start of a boot gets a random nick (`anonNNNN`).
- Networks (auto-connect, auto-join):
  - **IRC2P**: 127.0.0.1:6668 -> irc.postman.i2p; channels #i2p, #i2p-chat, #i2p-dev, #i2p-help.
  - **Ilita**: 127.0.0.1:6669 -> irc.ilita.i2p; channel #dev (the i2pd developers' channel; #ru is not auto-joined).

### i2pd IRC tunnels (`/var/lib/i2pd/tunnels.conf`)
Prestium had no IRC client tunnel (HexChat used the SOCKS tunnel 4449). Added, one tunnel per server so another
server can be used if one is down (The Lounge can't fail over by itself: edit the network and change the port):

| Port | Network | Server | Destination (b32) |
|---|---|---|---|
| 6668 | IRC2P (The Lounge default) | irc.postman.i2p | hhcy7zznltay2tzwdvtd37g2inptemz3hk5zmxyi57d3sxgxbseq |
| 6665 | IRC2P | irc.echelon.i2p | ez2czsvej5p3z5bquue5q3thujcodfze7ptybctqhnqc7hms5uzq |
| 6666 | IRC2P | irc.dg.i2p | fvp3pkcw4uvijqabwtekcdilklp73gyasuek67wdcs2mucep4caq |
| 6669 | Ilita (The Lounge default) | irc.ilita.i2p | 5xeoyfvtddmo5k3kxzv7b3d5risil6333ntqrr3yvx3yubz5tk3a |
| 6670 | Ilita | irc.r4sas.i2p | hodhusp73gltozgrnianlbploon3rrvhrzfn5mf2g46o7aaau5la |
| 6671 | Ilita | irc.acetone.i2p | qyzbrdw26ejjdjzsrcmq5h3ggdzk6cq5xynrgee5t5q73gq545yq |
| 6672 | Ilita | rusirc.ilita.i2p | mjsudehdlutbd3ze3lnj5qh3pfuxqx7msbydxt3nrmupgz5tfaoa |

- b32 addresses because i2pd's address book is empty at boot until the subscriptions are fetched over I2P.
  IRC2P addresses were computed from the destinations in Java I2P's bundled `hosts.txt` (postman/echelon also match
  PurpleI2P's i2pdbrowser address book); Ilita addresses are from PurpleI2P's i2pdbrowser address book.
- All IRC2P tunnels share one I2P identity (`irc2p-keys.dat`), all Ilita tunnels another (`ilita-keys.dat`),
  so the two networks can't link you; both are new every boot. `i2p.streaming.profile = 2` (interactive).

### HexChat removed
- Packages `hexchat`, `hexchat-common`, `hexchat-lua`, `hexchat-perl`, `hexchat-plugins`, `hexchat-python3` purged
  (plus `liblua5.3-0`, used only by hexchat-lua); menu entry, desktop file, D-Bus service, `~/.config/hexchat` and
  `/etc/skel/.config/hexchat` gone; its i2pd SOCKS tunnel (127.0.0.1:4449) removed. It had no firewall rule or autostart.
- Reseed file refreshed again (StormyCloud, 61 routers, signed by admin@stormycloud.org, signature checked;
  SHA-256 b27dcb806f40c4c535dc6760a494786409c487f30fb2293679ec75de260f7d9f).
- All live layers rebuilt (HexChat files were spread over them).

### Tested (QEMU x86_64, TCG; ISO SHA-256 503414e4ba5e437eaf2fdcd28ba9986cd1d1aeef34f150d0f953c505941f2d41, 1,946,157,056 bytes)
- Unchanged and passing: 0 failed units; ferm/NetworkManager/i2pd/Tor/LightDM/memlockd/watchdog active; OUTPUT/INPUT
  policy DROP; MAC randomized; no DNS; clock set over Tor; direct clearnet blocked for `user` and the time-sync user;
  Tor SOCKS works; `sudo mount` denied; root locked; i2pd 3.0.0 reseeded from the bundled file only; I2P Torrents
  web/RPC (per-boot path) works; Tor Browser 15.0.26 present and starts; VeraCrypt volume unlock/mount/lock (udisks2);
  emergency shutdown on boot-medium removal (16 s).
- HexChat: no binary, no packages, no menu/desktop/D-Bus entries, no config dirs, nothing on 4449.
- Firefox 158.0.1 starts as `user` with primary group `prestium-localweb` (all its processes). With that group:
  127.0.0.1:7070, :7685 (secret path) and :9000 answer 200; 1.1.1.1, i2pd 4444/4447/4450, SAM 7656, Tor 9050,
  IRC tunnel 6668 and [::1] are all refused. The launcher refuses any other URL.
- Menu entries: **I2P Router Console** opened "Purple I2P Webconsole" in the local Firefox; **IRC (The Lounge)**
  signed in automatically (The Lounge's session switched from the launcher token to "Firefox 158 on Linux x86_64");
  **I2P Torrents** launched the local Firefox, but the test could not capture that tab's title.
- The Lounge: active, 0 restarts, no external fetch attempts, listening only on 127.0.0.1:9000; per-boot token
  readable by `user`, not by `thelounge`; as `thelounge`, clearnet/4444/9050 blocked, tunnel 6668 reachable.
  Networks IRC2P (6668: #i2p #i2p-chat #i2p-dev #i2p-help) and Ilita (6669: #dev) configured; The Lounge held a TCP
  connection to the Ilita tunnel 6669 and i2pd created the IRC2P/Ilita tunnel identities. IRC registration/JOIN was
  **not** observed within 15 minutes in the emulated VM (I2P is very slow under TCG), so joining channels over I2P is
  untested.
