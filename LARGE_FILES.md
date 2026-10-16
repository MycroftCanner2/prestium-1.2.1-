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
| rootfs/opt/qbittorrent/usr/bin/qbittorrent | 186677944 | 58544a9c261e9e1e052adf23426b9cee28ef48c260056a1bec622af6f4d75c8c |

The LibreWolf rows are for LibreWolf 158.0-1. qbittorrent comes from the signed upstream AppImage
qbittorrent-5.2.4_lt20_x86_64.AppImage (SHA-256 eda6c0ca39f9befb0cd111b76a3d8b8bf3fd859323f2d4aac8c18f63766c2a1a),
with the squashfs at offset 944632.

Monero Wallet GUI (`monero-wallet-gui`) is not on this branch or in its ISO. It was removed;
Feather is the only wallet. The `monero-wallet-gui` row above applies to `main` (1.2.1) only.
