# device/tecno/TECNO-BF7

Device tree for Tecno Spark Go 2023, **BF7 variant (not BF7n)** — MT6761,
non-GKI, A/B + dynamic partitions, 32MB boot/recovery partition budget.

## Where every value in this tree came from

| Value | Source / confidence |
|---|---|
| Board name `CY-BF7-H6127` | Confirmed from your device investigation |
| Kernel header v2, pagesize 2048, base/offset/tags/dtb offsets | Confirmed via `parse_bootimg.py` against your stock boot.img |
| `MTK_DTB_HEADER_SIZE := 64` | Confirmed via manual DTB header analysis |
| `BOARD_SUPER_PARTITION_SIZE := 9126805504`, `BOARD_MAIN_SIZE := 9122611200` | From the twrpdtgen-generated tree for plain BF7 (branch `vnd_bf7_h6127-user-12-SP1A.210812.016-651674-release-keys`) — supersedes an earlier BF7n-scatter-file guess that turned out to be for the wrong sub-variant |
| `RAMDISK_COMPRESSION := gzip` only | Confirmed via `/proc/config.gz`: kernel only has `CONFIG_RD_GZIP=y`; lzma was tried and bootlooped |
| `recovery.fstab` logical flags + raw by-name entries | Confirmed working split: raw by-name nodes mount via TWRP's Mount menu; logical nodes needed the flag AND real super partition values (placeholder text in BoardConfig.mk was the actual root cause of "Invalid Argument" mount failures) |
| `init.recovery.mt6761.rc` USB import fix | Confirmed fix for ADB/USB not working in recovery |
| `TW_BOOT_CONTROL_VERSION := 1.0`, `TW_NO_FASTBOOT_BOOT := true` | Confirmed fixes for reboot-to-system loop |
| Stock reference sizes (kernel 11,883,603B / ramdisk 13,413,567B / dtb 121,231B) | From MIO-KITCHEN parse of your stock boot.img — useful as a sanity baseline, not build inputs |

## What's genuinely unverified

- **Crypto/FBE flags are commented out** in BoardConfig.mk. Re-enabling
  them previously caused a stuck-at-splash hang traced to `keystore2`
  crash-looping because the TEE daemon (`mcDrvDaemon`) never starts —
  this is a missing-binary/missing-init-service problem in the ramdisk,
  not something any BoardConfig flag fixes. Don't re-enable until that's
  separately resolved.
- **No kernel source exists** for this device (confirmed during your
  rooting investigation) — `TARGET_FORCE_PREBUILT_KERNEL` is set and you
  must supply `prebuilt/Image.gz` and `prebuilt/dtb.img` yourself (pulled
  from a stock or already-working boot.img), they are NOT included here.
- **This tree has not been run through an actual AOSP/TWRP build in this
  session** — I don't have your source tree, toolchain, or stock firmware
  to compile against. Treat this as your confirmed values consolidated
  into the standard file layout, not as a tree that's been build-tested
  from scratch here. Build it in your existing CI (GitHub Actions) exactly
  as you've been doing, and if `BOARD_SUPER_PARTITION_SIZE` or the kernel
  offsets ever disagree with what twrpdtgen reports on a fresh pull of
  your actual stock image, trust the fresh pull over this file — firmware
  can vary by region/batch even within "BF7".

## Fitting the 32MB budget

`BOARD_BOOTIMAGE_PARTITION_SIZE` / `BOARD_RECOVERYIMAGE_PARTITION_SIZE` are
set to exactly `33554432` (32MB) — the hard limit your CI's avbtool checks
have been failing against. `TW_EXCLUDE_*` flags trim known AOSP default
bloat at build time; `../builder/builder.py` (shipped alongside this tree)
handles the rest automatically if a build still comes out oversized —
see its own README section for how the two fit together.
