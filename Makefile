TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = YouTube Capture
ARCHS := armv7 arm64

include $(THEOS)/makefiles/common.mk

include $(THEOS_MAKE_PATH)/tweak.mk

before-all::
	rm common/botguard_js.c || true
	./lib/qjsc -ss -o common/botguard_js.c common/botguard_js.js # if this gives you problems, build yourself with commit 3adc8c9. this is only built for linux right now.

SUBPROJECTS += googleapp
SUBPROJECTS += preferences
# SUBPROJECTS += classicapp
SUBPROJECTS += captureapp
include $(THEOS_MAKE_PATH)/aggregate.mk
