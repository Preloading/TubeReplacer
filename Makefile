TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += googleapp
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
