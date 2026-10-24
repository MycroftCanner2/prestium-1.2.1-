# Files left out (over GitHub's 100 MB limit)

| Path | Bytes | SHA-256 |
|---|---|---|
| rootfs/usr/local/bin/monero-wallet-gui (main/1.2.1 only; removed in the 1.6 update) | 117409800 | 1babfc3a97105996f7e0528356efcb2be3885a937b93e4de92bf30deb37e05cb |
| rootfs/usr/share/librewolf/libxul.so | 143081752 | 6ddaa3071b367ca618f1c99dffcfeae409331529259ad4cf2a876d793072a4e6 |

iso/live/filesystem.squashfs (1,121,542,144 bytes) is unpacked into rootfs/ instead of committed.

## prestium-1.6-update branch (current)
Files over GitHub's 100 MB limit, left out of git (they are in Prestium-1.6-amd64.iso):

| Path | Bytes | SHA-256 |
|---|---|---|
| rootfs/usr/lib/x86_64-linux-gnu/libLLVM-15.so.1 | 117308864 | e45650cba881293ba3b6a0e7241920fc48fa4a522ca6dfda72dc94f5c54e44b0 |
| rootfs/usr/share/librewolf/browser/omni.ja | 134095298 | a1717ed8c715cbc570d47f0b126a285693ee79075d3c6f99670d84fb1ec88821 |
| rootfs/usr/share/librewolf/libxul.so | 204882368 | 24d4eaadbb865c1447089b96e244706ab83396109d2cd5b6049a1402d6eae277 |
| rootfs/usr/share/librewolf/omni.ja | 118365120 | 56fd27a3d0877270c67b41b5b7c8e247c1273f44a9178eca7e42d0c5e9536554 |
| rootfs/opt/tor-browser/Browser/libxul.so (Tor Browser 15.0.26) | 156454456 | e0159bb156321abb0ac174882645c75ff42a1e4ba1e0d2c70f19a600364b010e |
| rootfs/opt/qbittorrent/usr/bin/qbittorrent (5.3.0, Prestium 1.8) | 209216728 | 2b5b9a1f5bd2ebc6b364f8396d8d0aa61a1cfb443f353248bbd6f28c846c59f7 |
| rootfs/opt/firefox/libxul.so (Firefox 158.0.1, local-only browser, Prestium 1.8) | 188813968 | 5146807a20c1e8283330a1bf30996f5a05f91c5a4d840beda7c56038df8cb520 |
| rootfs/opt/nodejs/bin/node (Node.js 24.22.1 for The Lounge, Prestium 1.8) | 126879696 | e32e2d16081cf644f88392934288086e7662529d0d43277c34f7aad2207cfafb |

The LibreWolf rows are for LibreWolf 158.0-1. qbittorrent comes from the signed upstream AppImage
qbittorrent-5.3.0_x86_64.AppImage (SHA-256 1c64f2e95740be41f2822f909f56e4dd0da2637f312098a06da113d7add7418b), Prestium 1.8.

Monero Wallet GUI (`monero-wallet-gui`) is not on this branch or in its ISO. It was removed;
Feather is the only wallet. The `monero-wallet-gui` row above applies to `main` (1.2.1) only.

## Prestium 1.9 (Debian 13 trixie, current tree on prestium-1.6-update)
Files in the 1.9 rootfs that are over 100 MB and so left out of git. They are inside Prestium-1.9-amd64.iso.

| Path | Bytes | SHA-256 |
|---|---|---|
| rootfs/usr/lib/x86_64-linux-gnu/libLLVM.so.19.1 (trixie libllvm19) | 129673080 | 3523f50f635d2a1ea47518a392451f2854b92823ceaf1345fb806099dd1a3b8a |
| rootfs/usr/share/librewolf/browser/omni.ja (LibreWolf 158.0.1-2) | 134513400 | f779b9221ea8be38d1130429b22e9009fed331ff7d5579ed93c684982ef7e90d |
| rootfs/usr/share/librewolf/libxul.so (LibreWolf 158.0.1-2) | 204888128 | 4695c4868c2329edb472c5efe4226fd7ffff3fa65f66e244c7487dfe287113c4 |
| rootfs/usr/share/librewolf/omni.ja (LibreWolf 158.0.1-2) | 118262744 | 69c587aa29e4a057e4d64fc7c72379c2fd9a67cc26fa39f24d148b28cc23bd5c |
| rootfs/opt/firefox/libxul.so (Firefox 158.0.1) | 188813968 | 5146807a20c1e8283330a1bf30996f5a05f91c5a4d840beda7c56038df8cb520 |
| rootfs/opt/nodejs/bin/node (Node.js 24.22.1) | 126879696 | e32e2d16081cf644f88392934288086e7662529d0d43277c34f7aad2207cfafb |
| rootfs/opt/tor-browser/Browser/libxul.so (Tor Browser 15.0.26) | 156454456 | e0159bb156321abb0ac174882645c75ff42a1e4ba1e0d2c70f19a600364b010e |
| iso/live/initrd.img-6.12.113+deb13-amd64 (1.9 initrd, includes the Tails 7.15 firmware set) | 134573220 | a2f73fbb45286dcd9e0aef4630823364be57ecde5045b44884dd0eab669c2568 |

iso/live/filesystem.squashfs (the 1.9 ISO's squashfs) is not committed; rootfs/ holds its unpacked contents.
qBittorrent is not in 1.9.
