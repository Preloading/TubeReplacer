TARGET := iphone:clang:latest:5.0
ARCHS := armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeReplacerCaptureApp
CAPTURE_APP = 1

GOOGLE_APP_FILES = $(THEOS_PROJECT_DIR)/googleapp
COMMON = $(THEOS_PROJECT_DIR)/common
COMMON_GOOGLE = $(THEOS_PROJECT_DIR)/common-google

TubeReplacerCaptureApp_FILES = $(GOOGLE_APP_FILES)/signin.x \
	remove-gplus.x \
	resumables.x \
	$(GOOGLE_APP_FILES)/crashreporter.x \
	$(GOOGLE_APP_FILES)/Translators/TRJSONUtils.m \
	$(GOOGLE_APP_FILES)/Translators/TRContiunation.m \
	$(GOOGLE_APP_FILES)/Translators/TRRequestBuilder.m \
	$(GOOGLE_APP_FILES)/general.m \
	$(COMMON)/botguard_js.c \
	$(COMMON)/potoken.m \
	$(COMMON_GOOGLE)/potoken-google.m \
	$(COMMON)/Protobuf.m \
	$(COMMON)/YoutubeClientType.m
TubeReplacerCaptureApp_CFLAGS = -fno-objc-arc
TubeReplacerCaptureApp_LDFLAGS = ../lib/libquickjs.a ../lib/libposixshim.a

include $(THEOS_MAKE_PATH)/tweak.mk
