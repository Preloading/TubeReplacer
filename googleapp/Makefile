TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeReplacerGoogle

TubeReplacerGoogle_FILES = signin.x categories.x deviceauth.x frontfeed.x parsing.x getvideo.x channels.x search.x feeds.x Tweak.x  ../YoutubeRequestClient.m ../YoutubeClientType.m general.m
TubeReplacerGoogle_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
