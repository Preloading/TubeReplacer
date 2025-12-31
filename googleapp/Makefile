TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeReplacerGoogle

TubeReplacerGoogle_FILES = polyfill.x signin.x categories.x deviceauth.x frontfeed.x parsing.x getvideo.x channels.x channelfeed.x search.x feeds.x myprofile.x subscriptions.x homefeed.x suggestedvideos.x ../YoutubeRequestClient.m ../YoutubeClientType.m general.m
TubeReplacerGoogle_CFLAGS = -fno-objc-arc

before-all::
	rm signinpolyfil.h
	xxd -i signinpolyfil.js > signinpolyfil.h

include $(THEOS_MAKE_PATH)/tweak.mk
