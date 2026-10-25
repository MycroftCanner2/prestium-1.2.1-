Disclaimer: This project and all associated materials (including software, repositories, scripts, and ISO files) are provided strictly "as is" and "as available," for informational, educational, and experimental purposes only, without any express or implied warranties of any kind—including, but not limited to, fitness for a particular purpose, security, accuracy, or non-infringement. The creator and publisher make no claims regarding the safety, integrity, or audit status of any code or binaries, explicitly disclaim any expertise or maintenance obligations, and shall not be held liable for any direct, indirect, incidental, or consequential damages, security breaches, data loss, or legal issues arising from downloading, compiling, or using this material. You assume all responsibility and risk for your use of this software, and you are solely responsible for ensuring compliance with all applicable local, state, and international laws.

## Branch `prestium-1.6-update`: Prestium 1.9.1 (Debian 13)

This branch rebuilds Prestium **1.6** and adds updates on top. The current version is **1.9.1**: Prestium 1.9 (Debian 13 trixie) plus a security audit with Tails 7.15.1 parity and bug fixes.
The ISO is `Prestium-1.9.1-amd64.iso`: 2,272,788,480 bytes,
SHA-256 `117f487f1d884a89f4ffba926c12ddfce7c9999741c00a1d7c95c95961c00676`. The ISO is not stored in git, and **1.9.1 has no torrent**.
QEMU UEFI + Secure Boot test passed (Tor bootstraps to 100%, Tor Browser AppArmor enforced, no leaks, clean shutdown); RAM-wipe dump not verified. Details in CHANGES-1.9.1.md.
CHANGES-1.9.1.md lists what 1.9.1 changed (every audit item with its status), CHANGES-1.9.md covers 1.9, CHANGES-1.8.md covers 1.8 (Debian 12), and CHANGES-1.6-UPDATE.md has the earlier changes.
Prestium 1.9 is unchanged: `Prestium-1.9-amd64.iso`, 2,346,516,480 bytes, SHA-256 `2a88ecf404b35ff8a4038d1b8db393a8d50fa5118629aa3d7814eb2e7ca621cc` (commit c672e68b on this branch).
Prestium 1.8 is unchanged: `Prestium-1.8-amd64.iso`, SHA-256 503414e4ba5e437eaf2fdcd28ba9986cd1d1aeef34f150d0f953c505941f2d41,
torrent `Prestium-1.8-amd64.iso.torrent` (info hash `195ec3cd35556fc279d5b1c119d4bba69f3d68dd`). The 1.7 torrent is unchanged.
`rootfs/` and `iso/` hold the 1.9.1 tree. `build-1.9/` holds the build scripts, the QEMU self-test layer and the hardening captures (1.9.1 scripts: `mkboot191.sh`, `mkiso191.sh`, `build191.sh`, `qtest191.sh`).

- Base: Debian 13 trixie (+ -updates, -security; -backports only for firmware). Kernel 6.12.113+deb13-amd64, firmware-nonfree 20260916 (the same as Tails 7.15).
- **Secure Boot** works the way it does in Tails: Microsoft-signed shim → Debian-signed GRUB → Debian-signed kernel. BIOS and 32-bit UEFI boot are kept. 1.9.1 adds `module.sig_enforce=1` (every module in the image is signed), IOMMU/DMA protection, `spec_store_bypass_disable=on` and `debugfs=off`.
- **Memory erasure at shutdown, as in Tails**: at the end of every shutdown Prestium switches into the initramfs and deletes the session's files from RAM (overlay read-write branch, /tmp, /dev/shm), so the kernel zeroes that memory (`init_on_free=1`). The emergency shutdown when the boot medium is removed wipes them too.
- **AppArmor enforces**: i2pd, Tor and (new) **Tor Browser** are confined; LibreWolf has a complain-mode profile.
- **Tor control port behind a filter** (onion-grater style): apps no longer have raw control-port access; Tor Browser, OnionShare and Nyx get only what they need.
- I2P: i2pd 3.0.0 (official PurpleI2P trixie package). HTTP proxy 4444, SOCKS proxy 127.0.0.1:4447; SAM is off. Bandwidth class L, 30 % share. The random inbound port is open (legacy-iptables chain `PRESTIUM_I2PD`).
- Tor 0.4.9.14 from deb.torproject.org, SOCKS 127.0.0.1:9050 with stream isolation per destination, `Sandbox 1`, no unix SOCKS socket; Nyx 2.1.0 as the monitor. obfs4 bridges (lyrebird) are available.
- Browsers: **Web Browser (I2P; clearnet via I2P outproxy)** is LibreWolf 158.0.1 through the i2pd HTTP proxy 127.0.0.1:4444 (HTTPS-Only off, I2P sites are http).
  A separate **local-only Firefox** (158.0.1) opens I2P Router Console, I2P Torrents and IRC (The Lounge). The firewall lets it reach only 127.0.0.1 ports 7070, 7685 and 9000.
  **Tor Browser** is the official 15.0.26 in /opt/tor-browser, now root-owned and read-only, profile in `~/.tor-browser`, downloads in **`~/Tor Browser`** (the only home folder it can access).
- eMudhra: all four emSign roots are distrusted, in the system store and inside the three browsers (Tails 7.15.1 blocks all eMudhra certificates).
- **OnionShare** 2.6.3 and **Archive Manager** (file-roller, 7zip), as in Tails 7; **Image Viewer** Loupe and **Metadata Cleaner** (with a PCManFM "Remove metadata" action).
- Apps from Debian instead of AppImages: **KeePassXC 2.7.10, Kleopatra, Audacity 3.7.3** (as in Tails). **Mail (I2P)** is Claws Mail 4.3.1 with GPG plugins, preconfigured for postman (SMTP 127.0.0.1:7659, POP3 127.0.0.1:7660).
- Wallet: **Feather 2.8.1 is the only wallet**, over Tor 9050 with onion-only nodes.
- Torrents: **I2P Torrents**, the i2pd built-in client, saving to ~/Downloads/Torrents. Its web UI/RPC is on 127.0.0.1:7685 behind a random per-boot path.
- IRC is The Lounge (127.0.0.1:9000) through i2pd tunnels: IRC2P and Ilita connect at start, five alternate servers are ready to connect; each network gets its own random nick. Gajim uses Tor SOCKS 9050 by default.
  Everything else uses the `/etc/environment` proxy 127.0.0.1:4450 (no outproxy, so clearnet fails closed).
- Firewall (ferm, legacy iptables): only i2pd (uid 2000) and Tor (debian-tor, TCP only) may reach the network. `user` may reach only the listed localhost proxy ports. Drop-all before ferm loads; NetworkManager doesn't start without ferm. IPv6 is disabled.
- Screen lock (xss-lock + i3lock; the first lock asks you to set a password), MAC address spoofing at device detection (vendor part kept), clipboard manager without history, boot option "camera and microphone off".
- i2pd reseed: **bundled file only**: `/var/lib/i2pd/stormycloud-i2pseeds.su3` (2026-10-24 build, signature-checked, `verify = true`). `urls` and `yggurls` are empty.
- Kept from 1.8/1.9: emergency shutdown when the boot medium is removed, time sync over Tor only, dead DNS, root locked, kernel hardening parameters and blocked modules.
