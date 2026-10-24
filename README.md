Disclaimer: This project and all associated materials (including software, repositories, scripts, and ISO files) are provided strictly "as is" and "as available," for informational, educational, and experimental purposes only, without any express or implied warranties of any kind—including, but not limited to, fitness for a particular purpose, security, accuracy, or non-infringement. The creator and publisher make no claims regarding the safety, integrity, or audit status of any code or binaries, explicitly disclaim any expertise or maintenance obligations, and shall not be held liable for any direct, indirect, incidental, or consequential damages, security breaches, data loss, or legal issues arising from downloading, compiling, or using this material. You assume all responsibility and risk for your use of this software, and you are solely responsible for ensuring compliance with all applicable local, state, and international laws.

## Branch `prestium-1.6-update`: Prestium 1.9 (Debian 13)

This branch rebuilds Prestium **1.6** and adds updates on top. The current version is **1.9**, a rebase onto **Debian 13 (trixie)**.
The ISO is `Prestium-1.9-amd64.iso`: 2,346,516,480 bytes,
SHA-256 `2a88ecf404b35ff8a4038d1b8db393a8d50fa5118629aa3d7814eb2e7ca621cc`. The ISO is not stored in git, and **1.9 has no torrent**.
The final 1.9 ISO was **not boot-tested**, at the user's request. CHANGES-1.9.md has the QEMU results for the earlier 1.9 candidate.
CHANGES-1.9.md lists what 1.9 changed, CHANGES-1.8.md covers 1.8 (Debian 12), and CHANGES-1.6-UPDATE.md has the earlier changes.
Prestium 1.8 is unchanged: `Prestium-1.8-amd64.iso`, SHA-256 503414e4ba5e437eaf2fdcd28ba9986cd1d1aeef34f150d0f953c505941f2d41,
torrent `Prestium-1.8-amd64.iso.torrent` (info hash `195ec3cd35556fc279d5b1c119d4bba69f3d68dd`). The 1.7 torrent is unchanged.
`rootfs/` and `iso/` hold the 1.9 tree. `build-1.9/` holds the build scripts, the QEMU self-test layer and the hardening captures.

- Base: Debian 13 trixie (+ -updates, -security; -backports only for firmware). Kernel 6.12.113+deb13-amd64, firmware-nonfree 20260916 (the same as Tails 7.15).
- **Secure Boot** works the way it does in Tails: Microsoft-signed shim → Debian-signed GRUB → Debian-signed kernel. BIOS and 32-bit UEFI boot are kept.
- **AppArmor enforces.** In 1.8 it was silently skipped on the live overlay. i2pd and Tor are confined.
- I2P: i2pd 3.0.0 (official PurpleI2P trixie package). HTTP proxy 4444, SOCKS proxy 127.0.0.1:4447 and SAM 127.0.0.1:7656 are on.
  The random inbound port is now really open (legacy-iptables chain `PRESTIUM_I2PD`).
- Tor 0.4.9.14 from deb.torproject.org, SOCKS 127.0.0.1:9050, with Nyx 2.1.0 as the monitor.
- Browsers: **Web Browser (I2P)** is LibreWolf 158.0.1 through the i2pd HTTP proxy 127.0.0.1:4444.
- A separate **local-only Firefox** (158.0.1) opens I2P Router Console, I2P Torrents and IRC (The Lounge). The firewall lets it reach only 127.0.0.1 ports 7070, 7685 and 9000.
  **Tor Browser** is the official 15.0.26 (signature-checked) in /opt/tor-browser. It uses the system Tor (SOCKS 127.0.0.1:9050, control socket /run/tor/control).
- **OnionShare** 2.6.3, using the system Tor through its control socket, and **Archive Manager** (file-roller, 7zip), both as in Tails 7.
- System CA bundle: ca-certificates 20250419+deb13u1, byte-identical to Tails 7.15.1. This is the eMudhra/Comodo AAA distrust from Debian bug #1151413.
- Wallet: **Feather 2.8.1 is the only wallet**, preconfigured for I2P (SOCKS 127.0.0.1:4447).
- Torrents: **I2P Torrents**, the i2pd built-in client, saving to ~/Downloads/Torrents. Its web UI/RPC is on 127.0.0.1:7685 behind a random per-boot path.
- IRC is The Lounge (web client, 127.0.0.1:9000) through i2pd tunnels to IRC2P (127.0.0.1:6668) and Ilita (127.0.0.1:6669). Gajim uses the i2pd HTTP proxy. Sylpheed uses the postman SMTP/POP3 tunnels.
  Everything else uses the `/etc/environment` proxy 127.0.0.1:4450.
- Firewall (ferm, legacy iptables): only i2pd (uid 2000) and Tor (debian-tor) may reach the network. `user` may reach localhost proxy ports.
- i2pd reseed: **bundled file only**. It uses `/var/lib/i2pd/stormycloud-i2pseeds.su3` (refreshed 2026-10-22, signature-checked, `verify = true`). `urls` and `yggurls` are empty.
- Kept from 1.8: emergency shutdown and memory wipe when the boot medium is removed, time sync over Tor only, MAC randomization, dead DNS, root locked, kernel hardening parameters and blocked modules.
