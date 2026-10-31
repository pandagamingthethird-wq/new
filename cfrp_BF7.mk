PRODUCT_NAME := cfrp_BF7
PRODUCT_DEVICE := BF7
PRODUCT_BRAND := Tecno
PRODUCT_MODEL := TECNO BF7
PRODUCT_MANUFACTURER := Tecno

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# NOTE: deliberately NO vendor/twrp/config/common.mk here. That file
# expects TWRP's own bootable/recovery, which the CFRP build replaces.

# The recovery binary built from CyberRecoveryProject's Android.mk
PRODUCT_PACKAGES += recovery

# Inherit from TECNO-BF7 device
$(call inherit-product, device/tecno/TECNO-BF7/device.mk)
