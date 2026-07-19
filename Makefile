TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = YouTube Capture
ARCHS := armv7 arm64

include $(THEOS)/makefiles/common.mk

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += googleapp
SUBPROJECTS += preferences
# SUBPROJECTS += classicapp
# SUBPROJECTS += captureapp
include $(THEOS_MAKE_PATH)/aggregate.mk
