TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = Preferences
ARCHS := armv7 arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TubeReplacerPrefs

TubeReplacerPrefs_FILES = YTRPRootListController.m YTRPDebugListController.m
TubeReplacerPrefs_FRAMEWORKS = UIKit MessageUI
TubeReplacerPrefs_PRIVATE_FRAMEWORKS = Preferences
TubeReplacerPrefs_INSTALL_PATH = /Library/PreferenceBundles
TubeReplacerPrefs_CFLAGS = -fobjc-arc # todo: figure out how to remove arc stuff

include $(THEOS_MAKE_PATH)/bundle.mk
