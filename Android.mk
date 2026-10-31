# Android.mk for CyberRecoveryProject — goes at the ROOT of the CFRP repo.
# Lets the AOSP build system compile CFRP as the `recovery` binary once
# the builder workflow clones it into bootable/recovery.
#
# NOT YET BUILD-TESTED against a real AOSP tree. Likely first-run issues:
#   - libarchive: src/backup/twrp_tar.c needs it. The TWRP minimal
#     manifest may not ship external/libarchive; if the link fails on it,
#     either add that project to the manifest or drop twrp_tar.c from
#     LOCAL_SRC_FILES below (system/vendor tar backup stops working).
#   - The module name `recovery` and the sbin install path follow the
#     usual recovery-binary convention, but verify against the manifest
#     branch you build with.

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := recovery
LOCAL_MODULE_TAGS := eng optional
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/sbin

CFRP_SRCS := $(wildcard $(LOCAL_PATH)/src/*.c) \
             $(wildcard $(LOCAL_PATH)/src/*/*.c)
LOCAL_SRC_FILES := $(patsubst $(LOCAL_PATH)/%,%,$(CFRP_SRCS))

LOCAL_CFLAGS := -Wall -Wno-unused-parameter -D_POSIX_C_SOURCE=200809L
LOCAL_C_INCLUDES := $(LOCAL_PATH)/src

LOCAL_SHARED_LIBRARIES := libarchive

include $(BUILD_EXECUTABLE)
