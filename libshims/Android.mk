LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := lib-imsvtshim.cpp
LOCAL_MODULE := lib-imsvtshim
LOCAL_MODULE_TAGS := optional
include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := strdup8to16.cpp strdup16to8.cpp
LOCAL_MODULE := libshim_dpmframework
LOCAL_MODULE_TAGS := optional
include $(BUILD_SHARED_LIBRARY)
