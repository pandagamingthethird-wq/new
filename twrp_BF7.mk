PRODUCT_NAME := twrp_BF7
PRODUCT_DEVICE := BF7
PRODUCT_BRAND := Tecno
PRODUCT_MODEL := TECNO BF7
PRODUCT_MANUFACTURER := Tecno

$(call inherit-product, $(SRC_TARGET_DIR)/product/full.mk)
$(call inherit-product, device/tecno/TECNO-BF7/device.mk)
