# Files left out (over GitHub's 100 MB limit)

Prestium 1.9.1.3, branch `prestium-1.6-update`. These files are in `Prestium-1.9.1.3-amd64.iso` but not in git,
because GitHub refuses files over 100 MB.

| Path | Bytes | SHA-256 |
|---|---|---|
| rootfs/boot/initrd.img-6.12.113+deb13-amd64 (initrd, identical to iso/live/initrd.img-6.12.113+deb13-amd64) | 134,568,846 | d2a1682fe6896a278813d97067af81e6bfe7f3d72f208b138a1e6f6c67f6c293 |
| rootfs/opt/firefox/libxul.so (Firefox 159, local-only browser) | 189,342,152 | 45d113fc37005b4a7efed0f3fc3a24b4dac0cbe192cd59dfe128440803f5c073 |
| rootfs/opt/nodejs/bin/node (Node.js 24.22.1 for The Lounge) | 126,879,696 | e32e2d16081cf644f88392934288086e7662529d0d43277c34f7aad2207cfafb |
| rootfs/opt/tor-browser/Browser/libxul.so (Tor Browser 16.0) | 173,928,448 | 92bebcfb618b07955d844f89c67e8737c8bd21fabd6ee331be11e836b22e90ab |
| rootfs/usr/lib/x86_64-linux-gnu/libLLVM.so.19.1 (trixie libllvm19) | 129,673,080 | 3523f50f635d2a1ea47518a392451f2854b92823ceaf1345fb806099dd1a3b8a |
| rootfs/usr/share/librewolf/browser/omni.ja (LibreWolf 159) | 133,492,664 | 761e01615a7afd291e23cda953d8c346b6d00cdf05dbbdee1436b64968eb4f6c |
| rootfs/usr/share/librewolf/libxul.so (LibreWolf 159) | 206,078,920 | 412d44f8e4d2f229e8bb4d0f5c6c269839b93537c9c406ae2f68bf0c5c19e64e |
| rootfs/usr/share/librewolf/omni.ja (LibreWolf 159) | 119,007,518 | ac40d0db844d43129ff604a9953122295a1639a20ba16f6bc0a065a1ab752489 |
| iso/live/initrd.img-6.12.113+deb13-amd64 (initrd with the Tails firmware set and the memory-wipe hook) | 134,568,846 | d2a1682fe6896a278813d97067af81e6bfe7f3d72f208b138a1e6f6c67f6c293 |

`iso/live/filesystem.squashfs` (the ISO's only squashfs) is not committed; `rootfs/` holds its unpacked contents.
