LOCAL_PATH := $(call my-dir)
ifeq ($(TARGET_DEVICE),TECNO-BF7)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
