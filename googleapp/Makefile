TARGET := iphone:clang:latest:6.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeReplacerGoogle

TubeReplacerGoogle_FILES = Tweak.x
TubeReplacerGoogle_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
