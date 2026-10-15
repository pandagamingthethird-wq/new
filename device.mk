
LOCAL_PATH := device/tecno/BF7

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# A/B OTA
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Boot control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.0-impl \
    android.hardware.boot@1.0-impl.recovery \
    android.hardware.boot@1.0-service \
    bootctrl.mt6761 \
    bootctrl.mt6761.recovery 

PRODUCT_PACKAGES += \
    bootctrl 

PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh \
    update_engine \
    update_verifier \
    libtwrpfbe \
    librecovery_updater_mtk

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery.fstab:$(TARGET_COPY_OUT_RECOVERY)/root/etc/recovery.fstab

# init.rc fragment handling the device's USB rc import (fix applied
# during your investigation: missing import of init.mt6761.usb.rc broke
# ADB/USB in recovery)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6761.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6761.rc
