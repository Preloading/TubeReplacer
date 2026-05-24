TARGET := iphone:clang:latest:5.0
# INSTALL_TARGET_PROCESSES = YouTube
ARCHS := armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeReplacerGoogle

GOOGLE_APP = 1

TubeReplacerGoogle_FILES = polyfill.x \
	signin.x \
	deviceauth.x \
	frontfeed.x \
	parsing.x \
	categories.x \
	getvideo.x \
	channels.x \
	channelfeed.x \
	search.x \
	feeds.x \
	myprofile.x \
	subscriptions.x \
	homefeed.x \
	suggestedvideos.x \
	comments.x \
	accountfeeds.x \
	playlist.x \
	likes.x \
	general.x \
	settings.x \
	subtitles.x \
	crashreporter.x \
	potoken.m \
	botguard_js.c \
	Translators/TRJSONUtils.m \
	Translators/TRJSONTranslator.m \
	Translators/TRContiunation.m \
	Translators/Delegates/TRVideoTranslator.m \
	Translators/Delegates/TRChannelTranslator.m \
	Translators/Delegates/TRFeedTranslator.m \
	Translators/Delegates/TRCommentTranslator.m \
	Translators/Delegates/TRSubscriptionTranslator.m \
	Translators/Delegates/TRPlaylistTranslator.m \
	Translators/TRRequestBuilder.m \
	../Protobuf.m ../YoutubeClientType.m general.m ../base64/NSData+Base64.m ../base64/NSString+Base64.m
	
TubeReplacerGoogle_CFLAGS = -fno-objc-arc -ITranslators
TubeReplacerGoogle_LDFLAGS = ../lib/libquickjs.a ../lib/libposixshim.a

before-all::
	rm signinpolyfil.h || true
	xxd -i signinpolyfil.js > signinpolyfil.h
	rm botguard_js.c || true
	../lib/qjsc -ss -o botguard_js.c botguard_js.js # if this gives you problems, build yourself with commit 3adc8c9

ifeq (, $(shell which xxd))
$(error "You are missing `xxd` from your system, which is required to build.")
endif

# ifeq (, $(shell which qjsc))
# $(error "You are missing the quickjs-ng compiler from your system, which is required to build. (commit 3adc8c9)")
# endif

include $(THEOS_MAKE_PATH)/tweak.mk
