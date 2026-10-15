LOCAL_PATH := device/tecno/TECNO-BF7

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery.fstab:$(TARGET_COPY_OUT_RECOVERY)/root/etc/recovery.fstab

PRODUCT_PACKAGES += \
    libtwrpfbe \
    librecovery_updater_mtk

# init.rc fragment handling the device's USB rc import (fix applied
# during your investigation: missing import of init.mt6761.usb.rc broke
# ADB/USB in recovery)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6761.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6761.rc
