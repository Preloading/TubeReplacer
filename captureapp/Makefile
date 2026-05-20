TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = Capture
ARCHS := armv7 arm64

include $(THEOS)/makefiles/common.mk

GOOGLE_APP = $(THEOS_PROJECT_DIR)/googleapp
TWEAK_NAME = TubeReplacerCaptureApp
CAPTURE_APP = 1

TubeReplacerCaptureApp_FILES = $(GOOGLE_APP)/signin.x \
	remove-gplus.x \
	resumables.x \
	$(GOOGLE_APP)/crashreporter.x \
	$(GOOGLE_APP)/Translators/TRJSONUtils.m \
	$(GOOGLE_APP)/Translators/TRContiunation.m \
	$(GOOGLE_APP)/Translators/TRRequestBuilder.m \
	$(GOOGLE_APP)/general.m \
	../Protobuf.m
TubeReplacerCaptureApp_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
