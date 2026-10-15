# BoardConfig.mk — Tecno Spark Go 2023, BF7 variant (NOT BF7n)
# Assembled from confirmed values across your device tree investigation
# (twrpdtgen output, parse_bootimg.py, MIO-KITCHEN stock boot.img parse,
# and your manual fixes). Verify against your own stock firmware dump if
# anything here doesn't match what you observe on a fresh pull.

DEVICE_PATH := device/tecno/TECNO-BF7

# ---- SoC / platform ----------------------------------------------------
TARGET_BOARD_PLATFORM := mt6761
TARGET_BOOTLOADER_BOARD_NAME := CY-BF7-H6127
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic

PLATFORM_VERSION := 16.1.0
PLATFORM_SECURITY_PATCH := 2024-06-05
VENDOR_SECURITY_PATCH := 2024-06-05
# ^ anti-rollback hack — keep this pinned to what your bootloader expects

# ---- Boot image header ---------------------------------------------------
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_KERNEL_HEADER_VERSION := 2
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x11a88000
BOARD_KERNEL_TAGS_OFFSET := 0x07808000
BOARD_DTB_OFFSET := 0x07808000
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)

# Prebuilt kernel + dtb (no kernel source available for this device —
# confirmed during your rooting investigation)
TARGET_FORCE_PREBUILT_KERNEL := true
ifeq ($(TARGET_FORCE_PREBUILT_KERNEL),true)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_KERNEL_IMAGE_NAME := Image.gz
endif

# ---- MTK-specific: 64-byte proprietary header wraps the real DTB/DTBO --
# Confirmed via manual parsing: slice data[64:64+real_size] before handing
# payload to dtc. Not an AOSP stock variable — consumed by your own
# unpack/repack tooling (builder.py / backend_mtk.c), kept here so the
# value lives next to the rest of the device's boot image geometry.
MTK_DTB_HEADER_SIZE := 64

# ---- Partitions / A-B / dynamic partitions ------------------------------
TARGET_NO_RECOVERY := false
BOARD_USES_RECOVERY_AS_BOOT := false
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += boot vendor_boot system vendor product system_ext

BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_PARTITION_LIST := system system_ext vendor product
BOARD_MAIN_SIZE := 9122611200
# ^ Group name is "main" to match BOARD_MAIN_*; if you regenerate via
# twrpdtgen and it uses "tecno_dynamic_partitions" instead, the variable
# prefix MUST match the group name exactly — pick one and keep both
# consistent (see notes in docs/ARCHITECTURE.md of CyberRecoveryProject).

BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
# ^ THE 32MB budget — this is the hard limit builder.py targets.

# ---- Ramdisk compression -------------------------------------------------
# Confirmed via /proc/config.gz: kernel only has CONFIG_RD_GZIP=y.
# Do NOT change to lzma/lz4/xz — confirmed bootloop on this device.
TARGET_RAMDISK_COMPRESSION := gzip
BOARD_RAMDISK_USE_LZMA := false
BOARD_BOOTIMAGE_COMPRESSION_ALGORITHM := gzip

# ---- Recovery (TWRP) flags -----------------------------------------------
TW_INCLUDE_REPACK_TOOL := true
TW_USE_TOOLBOX := true
TW_THEME := portrait_hdpi
TW_BOOT_CONTROL_VERSION := 1.0
TW_NO_FASTBOOT_BOOT := true
TW_INCLUDE_LIBRESETPROP := true

# Crypto/FBE decrypt: OMITTED by default. Re-enabling these caused the
# boot-hang-at-splash regression (keystore2 crash-looping because the TEE
# daemon mcDrvDaemon never connects — a ramdisk-contents problem, not a
# flag problem). Only re-enable once that's actually fixed; see open
# issues at the bottom of this file.
# TW_INCLUDE_CRYPTO := true
# TW_INCLUDE_FBE := true
# TW_INCLUDE_FBE_METADATA_DECRYPT := true

# Exclusions kept to stay under the 32MB budget without relying solely on
# post-build shrinking — trim what AOSP would otherwise include by default.
TW_EXCLUDE_NANO := true
TW_EXCLUDE_APEX := true
TW_EXCLUDE_SUPERSU := true
TW_EXCLUDE_TWRPAPP := true

# ---- Filesystem / fstab ---------------------------------------------------
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_USES_METADATA_PARTITION := true

# =====================================================================
# OPEN ISSUES carried over from your investigation (unresolved as of the
# last confirmed status) — check these before assuming a fresh build is
# correct:
#   - /system_image, /vendor_image, /product_image, /system_ext_image
#     mount with "Invalid Argument" unless recovery.fstab's "logical"
#     flag is present AND BOARD_SUPER_PARTITION_SIZE/BOARD_MAIN_SIZE are
#     real values (placeholder text breaks this silently) — both are set
#     above, but re-verify against `fastboot getvar partition-size:super`
#     or `adb shell lpdump` on your actual unit if mounts still fail.
#   - /data FBE decrypt blocked on missing TEE daemon in the ramdisk,
#     unrelated to any BoardConfig flag.
# =====================================================================
