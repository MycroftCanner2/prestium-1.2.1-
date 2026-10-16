# Prestium 1.2.1 (amd64), extracted

Source image: `Prestium-1.2.1-amd64.iso`, 1,242,460,160 bytes,
SHA-256 `5c95a1ad47db75726806647885979988edd78f9a9183610d19ec317593b507ad`.

- `iso/` — ISO contents (GRUB/isolinux boot, EFI, kernel `live/vmlinuz-5.10.0-20-amd64`, initrd)
- `rootfs/` — unpacked `live/filesystem.squashfs` (Debian 11 based live root filesystem)

See LARGE_FILES.md for files excluded because of GitHub's size limit.

## Branch `prestium-1.6-update`: Prestium 1.6 rebuild (Debian 12)

This branch is a rebuild of Prestium **1.6** on Debian 12 (bookworm). It follows the
developer's 1.3–1.6 release notes and adds updates on top. The version is still 1.6, and the ISO is `Prestium-1.6-amd64.iso`.
CHANGES-1.6-UPDATE.md has the full list of changes. The ISO itself is not in git.

- Base: Debian 12, fully upgraded. Kernel 6.1.0-53-amd64 (6.1.187-1).
- I2P: i2pd 2.61.0 from the official PurpleI2P repo (repo.i2pd.xyz). HTTP proxy 4444, SOCKS proxy 127.0.0.1:4447 and SAM 127.0.0.1:7656 are on.
- Tor 0.4.9.14 from deb.torproject.org, SOCKS 127.0.0.1:9050, with Nyx 2.1.0 as the monitor.
- Browsers (LibreWolf 158.0): the menu has **Web Browser (I2P)**, the default profile through the i2pd HTTP proxy 127.0.0.1:4444,
  and **Web Browser (Tor)**, a separate profile `~/.librewolf-tor` using SOCKS5 127.0.0.1:9050 with remote DNS and no I2P proxy.
- Wallet: **Feather 2.8.1 is the only wallet**, preconfigured for I2P (SOCKS 127.0.0.1:4447). Monero Wallet GUI is removed.
- qBittorrent 5.2.4: the official signed AppImage, extracted to /opt/qbittorrent. It uses native I2P via SAM 127.0.0.1:7656 and is I2P-only:
  mixed mode, DHT, PeX, LSD, UPnP and NAT-PMP are all off.
- Other network apps are set up for I2P. Gajim uses the i2pd HTTP proxy. HexChat uses the i2pd SOCKS tunnel 127.0.0.1:4449 and I2P IRC servers. Sylpheed uses the postman SMTP/POP3 tunnels.
  Everything else uses the `/etc/environment` proxy 127.0.0.1:4450.
- Firewall (ferm): only i2pd (uid 2000) and Tor (uid 107) may reach the network. `user` may reach localhost proxy ports
  (4444, 4447, 7656, 9050, …).
- i2pd reseed: **bundled file only**. It reseeds from `/var/lib/i2pd/stormycloud-i2pseeds.su3`, which is signed by admin@stormycloud.org and checked with `verify = true`.
  `urls` and `yggurls` are empty, so no reseed server is ever contacted. The bundled file ages, so refresh it when rebuilding the ISO.
