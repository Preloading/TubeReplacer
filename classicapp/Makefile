TARGET := iphone:clang:latest:5.0
ARCHS := armv6 armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeReplacerClassic

TubeReplacerClassic_FILES = deviceauth.x \
	search.x \
	signin.x

TubeReplacerClassic_CFLAGS = -fno-objc-arc -ITranslators

include $(THEOS_MAKE_PATH)/tweak.mk
