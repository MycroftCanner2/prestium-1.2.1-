Disclaimer: This project and all associated materials (including software, repositories, scripts, and ISO files) are provided strictly "as is" and "as available," for informational, educational, and experimental purposes only, without any express or implied warranties of any kind—including, but not limited to, fitness for a particular purpose, security, accuracy, or non-infringement. The creator and publisher make no claims regarding the safety, integrity, or audit status of any code or binaries, explicitly disclaim any expertise or maintenance obligations, and shall not be held liable for any direct, indirect, incidental, or consequential damages, security breaches, data loss, or legal issues arising from downloading, compiling, or using this material. You assume all responsibility and risk for your use of this software, and you are solely responsible for ensuring compliance with all applicable local, state, and international laws.

## Branch `prestium-1.6-update`: Prestium 1.6 rebuild (Debian 12)

This branch is a rebuild of Prestium **1.6** on Debian 12 (bookworm). It follows the
developer's 1.3–1.6 release notes and adds updates on top. The version is still 1.6, and the ISO is `Prestium-1.6-amd64.iso`.
CHANGES-1.6-UPDATE.md has the full list of changes. The ISO itself is not in git.

- Base: Debian 12, fully upgraded. Kernel 6.1.0-53-amd64 (6.1.187-1).
- I2P: i2pd 2.61.0 from the official PurpleI2P repo (repo.i2pd.xyz). HTTP proxy 4444, SOCKS proxy 127.0.0.1:4447 and SAM 127.0.0.1:7656 are on.
- Tor 0.4.9.14 from deb.torproject.org, SOCKS 127.0.0.1:9050, with Nyx 2.1.0 as the monitor.
- Browsers: **Web Browser (I2P)** is LibreWolf 158.0 through the i2pd HTTP proxy 127.0.0.1:4444.
  **Tor Browser** is the official Tor Browser 15.0.25 (signature-checked) in /opt/tor-browser, using the system Tor
  (SOCKS 127.0.0.1:9050, control socket /run/tor/control) instead of its own tor. LibreWolf no longer has a Tor profile.
- Wallet: **Feather 2.8.1 is the only wallet**, preconfigured for I2P (SOCKS 127.0.0.1:4447). Monero Wallet GUI is removed.
- qBittorrent 5.2.4: the official signed AppImage, extracted to /opt/qbittorrent. It uses native I2P via SAM 127.0.0.1:7656 and is I2P-only:
  mixed mode, DHT, PeX, LSD, UPnP and NAT-PMP are all off.
- Other network apps are set up for I2P. Gajim uses the i2pd HTTP proxy. HexChat uses the i2pd SOCKS tunnel 127.0.0.1:4449 and I2P IRC servers. Sylpheed uses the postman SMTP/POP3 tunnels.
  Everything else uses the `/etc/environment` proxy 127.0.0.1:4450.
- Firewall (ferm): only i2pd (uid 2000) and Tor (uid 107) may reach the network. `user` may reach localhost proxy ports
  (4444, 4447, 7656, 9050, …).
- i2pd reseed: **bundled file only**. It reseeds from `/var/lib/i2pd/stormycloud-i2pseeds.su3`, which is signed by admin@stormycloud.org and checked with `verify = true`.
  `urls` and `yggurls` are empty, so no reseed server is ever contacted. The bundled file ages, so refresh it when rebuilding the ISO.
